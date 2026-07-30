# NestJS Backend Server Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up `wishie-server`, a new standalone NestJS + Prisma repo that owns all reads/writes to the shared Supabase Postgres database and proxies Supabase Auth/Storage, exposing the REST + Socket.io surface both the iOS app and the future web app will call.

**Architecture:** NestJS feature modules (Auth, Profiles, Wishlists, WishlistItems, GiftSuggestions) sit behind a shared `JwtAuthGuard` that verifies Supabase-issued JWTs. Prisma connects directly to Supabase's Postgres (bypassing PostgREST/RLS) and owns schema/migrations. A `SupabaseAdminService` wraps a `service_role`-keyed `supabase-js` client, used only by Auth (to call Supabase Auth) and Storage (to upload to the `Wishie` bucket). A `RealtimeGateway` (Socket.io) emits room-scoped events after mutations succeed.

**Tech Stack:** NestJS 10 (TypeScript), Prisma + PostgreSQL (Supabase-hosted), `@supabase/supabase-js` (service_role), `@nestjs/websockets` + `socket.io`, `@nestjs/axios` (Gemini calls), `class-validator`/`class-transformer`, Jest (`@nestjs/testing`), Railway (deploy).

## Global Constraints

- New repo `wishie-server`, standalone git repository — not nested inside the `Wishie` iOS repo.
- Reuses the existing Supabase Cloud project (the one already used for Storage bucket `Wishie`) — do not create a new Supabase project. Postgres and Auth are already available on that project; this plan is the first thing to use them.
- Storage paths stay exactly as today: `avatar/{userId}.jpg`, `wishlist/{fileName}.jpg`.
- Auth providers: email/password + Google ID token exchange only. No Apple Sign-In, no anonymous auth.
- `Wishlist.id` and `WishlistItem.id` are client-generated UUID strings supplied by the iOS app (`UUID().uuidString`) — Prisma models use `String @id`, never `@default(uuid())` or `@default(cuid())`.
- RLS stays enabled with no permissive policies (deny-all) on every table — Prisma's direct Postgres connection is unaffected by RLS; this is defense in depth only.
- Deploy target: Railway.
- No data/user migration — no production users exist yet.

---

## Task 1: Supabase project credentials (manual, human-only — not delegated to a subagent)

This task has no code and cannot be performed by a coding agent — it requires an interactive browser session and account ownership.

- [ ] **Step 1: Record the existing project's connection details**

Go to https://supabase.com/dashboard, open the existing Wishie project (the one whose Storage bucket `Wishie` is already in use). Settings → Database → copy the **direct connection string** (not the pooled/transaction one — Prisma migrations need a direct connection). Settings → API → copy the **Project URL**, the **`service_role` secret key**, and (Settings → API → JWT Settings) the **JWT secret**.

- [ ] **Step 2: Enable the Google OAuth provider on this project**

Authentication → Providers → Google. Enable it, entering the same OAuth client ID/secret already configured for Google Sign-In in the iOS app's `GoogleService-Info.plist` (`CLIENT_ID` / reversed client ID) — reuse the existing Google Cloud OAuth client.

- [ ] **Step 3: Save these four values somewhere safe for Task 2**

`DATABASE_URL` (direct connection string), `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_JWT_SECRET`. They're wired into `.env` in Task 2 and into Railway env vars in Task 13.

---

## Task 2: Scaffold the NestJS project, config, and health check

**Files:**
- Create: `wishie-server/` (new repo, via `nest new`)
- Create: `src/config/env.validation.ts`
- Create: `src/config/config.module.ts`
- Create: `src/health/health.controller.ts`
- Test: `test/health.e2e-spec.ts`

**Interfaces:**
- Produces: `AppConfigModule` (global, exports nothing — config is read via `ConfigService<EnvVars>` from `@nestjs/config`), `GET /health` → `{ status: 'ok' }`. Consumed by every later task needing env vars (`ConfigService`).

- [ ] **Step 1: Create the repo and install dependencies**

```bash
cd /Users/khanghnguyen
npx @nestjs/cli new wishie-server --package-manager npm --skip-git
cd wishie-server
git init && git add -A && git commit -m "chore: scaffold NestJS project"
npm install @nestjs/config class-validator class-transformer @supabase/supabase-js @prisma/client @nestjs/websockets @nestjs/platform-socket.io socket.io @nestjs/platform-express @nestjs/axios axios jsonwebtoken
npm install -D prisma @types/jsonwebtoken @types/multer
```

- [ ] **Step 2: Write the failing health check e2e test**

Create `test/health.e2e-spec.ts`:

```typescript
import { Test } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';

describe('Health (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = moduleRef.createNestApplication();
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /health returns ok', () => {
    return request(app.getHttpServer())
      .get('/health')
      .expect(200)
      .expect({ status: 'ok' });
  });
});
```

- [ ] **Step 3: Run it to verify it fails**

Run: `npm run test:e2e`
Expected: FAIL — `/health` route doesn't exist (404).

- [ ] **Step 4: Write env validation and the config module**

Create `src/config/env.validation.ts`:

```typescript
import { plainToInstance } from 'class-transformer';
import { IsNotEmpty, IsString, validateSync } from 'class-validator';

class EnvVars {
  @IsString() @IsNotEmpty() DATABASE_URL: string;
  @IsString() @IsNotEmpty() SUPABASE_URL: string;
  @IsString() @IsNotEmpty() SUPABASE_SERVICE_ROLE_KEY: string;
  @IsString() @IsNotEmpty() SUPABASE_JWT_SECRET: string;
  @IsString() @IsNotEmpty() GEMINI_API_KEY: string;
}

export function validateEnv(config: Record<string, unknown>): EnvVars {
  const validated = plainToInstance(EnvVars, config, { enableImplicitConversion: true });
  const errors = validateSync(validated, { skipMissingProperties: false });
  if (errors.length > 0) {
    throw new Error(`Invalid environment configuration: ${errors.toString()}`);
  }
  return validated;
}
```

Create `src/config/config.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { validateEnv } from './env.validation';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      validate: validateEnv,
    }),
  ],
})
export class AppConfigModule {}
```

Create a `.env` at the repo root (not committed) with the four values from Task 1 plus a placeholder `GEMINI_API_KEY` (wired for real in Task 12), and a committed `.env.example`:

```
DATABASE_URL=
SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=
SUPABASE_JWT_SECRET=
GEMINI_API_KEY=
```

Confirm `.env` is in `.gitignore` (generated by `nest new` already ignores `.env` — verify it's listed).

- [ ] **Step 5: Write the health controller and wire modules**

Create `src/health/health.controller.ts`:

```typescript
import { Controller, Get } from '@nestjs/common';

@Controller('health')
export class HealthController {
  @Get()
  check() {
    return { status: 'ok' };
  }
}
```

Edit `src/app.module.ts` to import `AppConfigModule` and declare `HealthController`:

```typescript
import { Module } from '@nestjs/common';
import { AppConfigModule } from './config/config.module';
import { HealthController } from './health/health.controller';

@Module({
  imports: [AppConfigModule],
  controllers: [HealthController],
})
export class AppModule {}
```

- [ ] **Step 6: Run the test to verify it passes**

Run: `npm run test:e2e`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: add config validation and health check"
```

---

## Task 3: Prisma schema, migrations, and RLS deny-all

**Files:**
- Create: `prisma/schema.prisma`
- Create: `prisma/migrations/` (generated)
- Create: `src/prisma/prisma.service.ts`
- Create: `src/prisma/prisma.module.ts`
- Modify: `src/app.module.ts`

**Interfaces:**
- Produces: `PrismaService` (extends `PrismaClient`, injectable, connects/disconnects with the Nest lifecycle) — consumed by `AuthModule`, `ProfilesModule`, `WishlistsModule`, `WishlistItemsModule` in every later task. Also produces Postgres tables `profiles`, `wishlists`, `wishlist_members`, `wishlist_items`.

- [ ] **Step 1: Initialize Prisma**

```bash
npx prisma init --datasource-provider postgresql
```

This creates `prisma/schema.prisma` and adds `DATABASE_URL` to `.env` (already set from Task 2).

- [ ] **Step 2: Write the schema**

Replace `prisma/schema.prisma`:

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model Profile {
  id                         String    @id
  firstName                  String    @default("") @map("first_name")
  lastName                   String    @default("") @map("last_name")
  email                      String    @default("")
  phone                      String    @default("")
  dateOfBirth                DateTime? @map("date_of_birth")
  avatarUrl                  String?   @map("avatar_url")
  interests                  String[]  @default([])
  hasCompletedInterestsSetup Boolean   @default(false) @map("has_completed_interests_setup")
  createdAt                  DateTime  @default(now()) @map("created_at")

  @@map("profiles")
}

model Wishlist {
  id          String           @id
  name        String
  description String           @default("")
  ownerId     String           @map("owner_id")
  dueDate     DateTime         @map("due_date")
  colorTheme  String?          @map("color_theme")
  isArchived  Boolean          @default(false) @map("is_archived")
  createdAt   DateTime         @default(now()) @map("created_at")
  members     WishlistMember[]
  items       WishlistItem[]

  @@map("wishlists")
}

model WishlistMember {
  wishlistId String   @map("wishlist_id")
  userId     String   @map("user_id")
  role       String
  joinedAt   DateTime @default(now()) @map("joined_at")
  wishlist   Wishlist @relation(fields: [wishlistId], references: [id], onDelete: Cascade)

  @@id([wishlistId, userId])
  @@index([userId])
  @@map("wishlist_members")
}

model WishlistItem {
  id            String   @id
  wishlistId    String   @map("wishlist_id")
  name          String
  description   String   @default("")
  imageUrl      String?  @map("image_url")
  isPicked      Boolean  @default(false) @map("is_picked")
  pickedBy      String?  @map("picked_by")
  itemLink      String   @default("") @map("item_link")
  price         String?
  isMostDesired Boolean  @default(false) @map("is_most_desired")
  wishlist      Wishlist @relation(fields: [wishlistId], references: [id], onDelete: Cascade)

  @@index([wishlistId])
  @@map("wishlist_items")
}
```

- [ ] **Step 3: Generate and apply the initial migration**

```bash
npx prisma migrate dev --name init
```

Expected: creates `prisma/migrations/<timestamp>_init/migration.sql` and applies it — tables `profiles`, `wishlists`, `wishlist_members`, `wishlist_items` now exist on the Supabase Postgres instance.

- [ ] **Step 4: Add the RLS deny-all migration**

```bash
npx prisma migrate dev --create-only --name enable_rls_deny_all
```

Edit the generated (empty) `prisma/migrations/<timestamp>_enable_rls_deny_all/migration.sql`:

```sql
alter table public.profiles enable row level security;
alter table public.wishlists enable row level security;
alter table public.wishlist_members enable row level security;
alter table public.wishlist_items enable row level security;
-- Intentionally no policies: default-deny for the "anon" and "authenticated"
-- Postgres roles. Only this server's direct Postgres connection (via
-- DATABASE_URL, not subject to RLS) and the service_role key can read/write.
```

Apply it:

```bash
npx prisma migrate dev
```

Expected: CLI reports the migration applied. Verify in the Supabase dashboard's Table Editor that all four tables exist with RLS enabled and zero policies.

- [ ] **Step 5: Write `PrismaService`/`PrismaModule`**

Create `src/prisma/prisma.service.ts`:

```typescript
import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  async onModuleInit() {
    await this.$connect();
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
```

Create `src/prisma/prisma.module.ts`:

```typescript
import { Global, Module } from '@nestjs/common';
import { PrismaService } from './prisma.service';

@Global()
@Module({
  providers: [PrismaService],
  exports: [PrismaService],
})
export class PrismaModule {}
```

Edit `src/app.module.ts` to import `PrismaModule`:

```typescript
import { Module } from '@nestjs/common';
import { AppConfigModule } from './config/config.module';
import { PrismaModule } from './prisma/prisma.module';
import { HealthController } from './health/health.controller';

@Module({
  imports: [AppConfigModule, PrismaModule],
  controllers: [HealthController],
})
export class AppModule {}
```

- [ ] **Step 6: Rebuild and rerun the health e2e test to confirm nothing broke**

Run: `npm run test:e2e`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add prisma src/prisma src/app.module.ts .env.example
git commit -m "feat: add Prisma schema, migrations, and RLS deny-all policies"
```

---

## Task 4: `SupabaseAdminService`

**Files:**
- Create: `src/supabase-admin/supabase-admin.service.ts`
- Create: `src/supabase-admin/supabase-admin.module.ts`
- Test: `src/supabase-admin/supabase-admin.service.spec.ts`

**Interfaces:**
- Produces: `SupabaseAdminService.client: SupabaseClient` (service_role-keyed) — consumed by `AuthService` (Task 5) and `StorageService` (Task 8).
- Consumes: `ConfigService` from Task 2 (`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`).

- [ ] **Step 1: Write the failing test**

Create `src/supabase-admin/supabase-admin.service.spec.ts`:

```typescript
import { Test } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { SupabaseAdminService } from './supabase-admin.service';

describe('SupabaseAdminService', () => {
  it('builds a client pointed at the configured project URL', async () => {
    const moduleRef = await Test.createTestingModule({
      providers: [
        SupabaseAdminService,
        {
          provide: ConfigService,
          useValue: { get: (key: string) => ({ SUPABASE_URL: 'https://x.supabase.co', SUPABASE_SERVICE_ROLE_KEY: 'key' } as any)[key] },
        },
      ],
    }).compile();

    const service = moduleRef.get(SupabaseAdminService);
    expect(service.client).toBeDefined();
    expect((service.client as any).supabaseUrl).toBe('https://x.supabase.co');
  });
});
```

- [ ] **Step 2: Run it to verify it fails**

Run: `npm test -- supabase-admin.service.spec`
Expected: FAIL — `SupabaseAdminService` doesn't exist.

- [ ] **Step 3: Implement it**

Create `src/supabase-admin/supabase-admin.service.ts`:

```typescript
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

@Injectable()
export class SupabaseAdminService {
  readonly client: SupabaseClient;

  constructor(config: ConfigService) {
    this.client = createClient(
      config.get<string>('SUPABASE_URL')!,
      config.get<string>('SUPABASE_SERVICE_ROLE_KEY')!,
      { auth: { autoRefreshToken: false, persistSession: false } },
    );
  }
}
```

Create `src/supabase-admin/supabase-admin.module.ts`:

```typescript
import { Global, Module } from '@nestjs/common';
import { SupabaseAdminService } from './supabase-admin.service';

@Global()
@Module({
  providers: [SupabaseAdminService],
  exports: [SupabaseAdminService],
})
export class SupabaseAdminModule {}
```

Edit `src/app.module.ts` to add `SupabaseAdminModule` to `imports`.

- [ ] **Step 4: Run the test to verify it passes**

Run: `npm test -- supabase-admin.service.spec`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/supabase-admin src/app.module.ts
git commit -m "feat: add SupabaseAdminService for service_role Auth/Storage access"
```

---

## Task 5: `AuthModule` — signup, login, Google, reset password

**Files:**
- Create: `src/auth/dto/sign-up.dto.ts`
- Create: `src/auth/dto/login.dto.ts`
- Create: `src/auth/dto/google-auth.dto.ts`
- Create: `src/auth/dto/reset-password.dto.ts`
- Create: `src/auth/auth.service.ts`
- Create: `src/auth/auth.controller.ts`
- Create: `src/auth/auth.module.ts`
- Test: `src/auth/auth.service.spec.ts`

**Interfaces:**
- Consumes: `SupabaseAdminService` (Task 4), `PrismaService` (Task 3).
- Produces: `AuthService.signUp/login/loginWithGoogle/resetPassword`, returning `{ accessToken: string; userId: string; email: string | null }` for the first three. Consumed by `AuthController`'s `POST /auth/signup|login|google|reset-password`.

- [ ] **Step 1: Write the DTOs**

Create `src/auth/dto/sign-up.dto.ts`:

```typescript
import { IsDateString, IsEmail, IsString, MinLength } from 'class-validator';

export class SignUpDto {
  @IsEmail() email: string;
  @IsString() @MinLength(8) password: string;
  @IsString() firstName: string;
  @IsString() lastName: string;
  @IsString() phone: string;
  @IsDateString() dateOfBirth: string;
}
```

Create `src/auth/dto/login.dto.ts`:

```typescript
import { IsEmail, IsString } from 'class-validator';

export class LoginDto {
  @IsEmail() email: string;
  @IsString() password: string;
}
```

Create `src/auth/dto/google-auth.dto.ts`:

```typescript
import { IsString } from 'class-validator';

export class GoogleAuthDto {
  @IsString() idToken: string;
  @IsString() accessToken: string;
  @IsString() firstName?: string;
  @IsString() lastName?: string;
}
```

Create `src/auth/dto/reset-password.dto.ts`:

```typescript
import { IsEmail } from 'class-validator';

export class ResetPasswordDto {
  @IsEmail() email: string;
}
```

- [ ] **Step 2: Write the failing test**

Create `src/auth/auth.service.spec.ts`:

```typescript
import { AuthService } from './auth.service';

describe('AuthService', () => {
  function buildService(overrides: { signUp?: any; signInWithPassword?: any; upsertProfile?: any } = {}) {
    const supabaseAdmin = {
      client: {
        auth: {
          signUp: overrides.signUp ?? jest.fn(),
          signInWithPassword: overrides.signInWithPassword ?? jest.fn(),
          resetPasswordForEmail: jest.fn(),
          signInWithIdToken: jest.fn(),
        },
      },
    } as any;
    const prisma = {
      profile: {
        create: jest.fn(),
        upsert: overrides.upsertProfile ?? jest.fn(),
        findUnique: jest.fn(),
      },
    } as any;
    return { service: new AuthService(supabaseAdmin, prisma), supabaseAdmin, prisma };
  }

  it('signUp creates the Supabase user and a Profile row, returns the session', async () => {
    const { service, supabaseAdmin, prisma } = buildService({
      signUp: jest.fn().mockResolvedValue({
        data: { user: { id: 'user-1', email: 'a@b.com' }, session: { access_token: 'jwt-1' } },
        error: null,
      }),
    });

    const result = await service.signUp({
      email: 'a@b.com',
      password: 'password123',
      firstName: 'Ada',
      lastName: 'Lovelace',
      phone: '0123456789',
      dateOfBirth: '1990-01-01',
    });

    expect(supabaseAdmin.client.auth.signUp).toHaveBeenCalledWith({ email: 'a@b.com', password: 'password123' });
    expect(prisma.profile.create).toHaveBeenCalledWith({
      data: expect.objectContaining({ id: 'user-1', firstName: 'Ada', lastName: 'Lovelace', email: 'a@b.com' }),
    });
    expect(result).toEqual({ accessToken: 'jwt-1', userId: 'user-1', email: 'a@b.com' });
  });

  it('login returns the session on success', async () => {
    const { service } = buildService({
      signInWithPassword: jest.fn().mockResolvedValue({
        data: { user: { id: 'user-2', email: 'c@d.com' }, session: { access_token: 'jwt-2' } },
        error: null,
      }),
    });

    const result = await service.login({ email: 'c@d.com', password: 'password123' });
    expect(result).toEqual({ accessToken: 'jwt-2', userId: 'user-2', email: 'c@d.com' });
  });

  it('login throws when Supabase returns an error', async () => {
    const { service } = buildService({
      signInWithPassword: jest.fn().mockResolvedValue({ data: {}, error: { message: 'Invalid credentials' } }),
    });

    await expect(service.login({ email: 'x@y.com', password: 'wrong' })).rejects.toThrow('Invalid credentials');
  });
});
```

- [ ] **Step 3: Run it to verify it fails**

Run: `npm test -- auth.service.spec`
Expected: FAIL — `AuthService` doesn't exist.

- [ ] **Step 4: Implement `AuthService`**

Create `src/auth/auth.service.ts`:

```typescript
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { SupabaseAdminService } from '../supabase-admin/supabase-admin.service';
import { PrismaService } from '../prisma/prisma.service';
import { SignUpDto } from './dto/sign-up.dto';
import { LoginDto } from './dto/login.dto';
import { GoogleAuthDto } from './dto/google-auth.dto';

export interface AuthSession {
  accessToken: string;
  userId: string;
  email: string | null;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly supabaseAdmin: SupabaseAdminService,
    private readonly prisma: PrismaService,
  ) {}

  async signUp(dto: SignUpDto): Promise<AuthSession> {
    const { data, error } = await this.supabaseAdmin.client.auth.signUp({
      email: dto.email,
      password: dto.password,
    });
    if (error || !data.user || !data.session) {
      throw new UnauthorizedException(error?.message ?? 'Sign up failed');
    }
    await this.prisma.profile.create({
      data: {
        id: data.user.id,
        firstName: dto.firstName,
        lastName: dto.lastName,
        email: dto.email,
        phone: dto.phone,
        dateOfBirth: new Date(dto.dateOfBirth),
      },
    });
    return { accessToken: data.session.access_token, userId: data.user.id, email: data.user.email ?? dto.email };
  }

  async login(dto: LoginDto): Promise<AuthSession> {
    const { data, error } = await this.supabaseAdmin.client.auth.signInWithPassword({
      email: dto.email,
      password: dto.password,
    });
    if (error || !data.user || !data.session) {
      throw new UnauthorizedException(error?.message ?? 'Login failed');
    }
    return { accessToken: data.session.access_token, userId: data.user.id, email: data.user.email ?? null };
  }

  async loginWithGoogle(dto: GoogleAuthDto): Promise<AuthSession> {
    const { data, error } = await this.supabaseAdmin.client.auth.signInWithIdToken({
      provider: 'google',
      token: dto.idToken,
      access_token: dto.accessToken,
    });
    if (error || !data.user || !data.session) {
      throw new UnauthorizedException(error?.message ?? 'Google sign-in failed');
    }
    const email = data.user.email ?? '';
    await this.prisma.profile.upsert({
      where: { id: data.user.id },
      create: {
        id: data.user.id,
        firstName: dto.firstName ?? '',
        lastName: dto.lastName ?? '',
        email,
        phone: '',
        dateOfBirth: new Date(),
      },
      update: email ? { email } : {},
    });
    return { accessToken: data.session.access_token, userId: data.user.id, email: data.user.email ?? null };
  }

  async resetPassword(email: string): Promise<{ success: true }> {
    const { error } = await this.supabaseAdmin.client.auth.resetPasswordForEmail(email);
    if (error) {
      throw new UnauthorizedException(error.message);
    }
    return { success: true };
  }
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `npm test -- auth.service.spec`
Expected: PASS

- [ ] **Step 6: Write the controller and module**

Create `src/auth/auth.controller.ts`:

```typescript
import { Body, Controller, Post } from '@nestjs/common';
import { AuthService } from './auth.service';
import { SignUpDto } from './dto/sign-up.dto';
import { LoginDto } from './dto/login.dto';
import { GoogleAuthDto } from './dto/google-auth.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('signup')
  signUp(@Body() dto: SignUpDto) {
    return this.authService.signUp(dto);
  }

  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Post('google')
  loginWithGoogle(@Body() dto: GoogleAuthDto) {
    return this.authService.loginWithGoogle(dto);
  }

  @Post('reset-password')
  resetPassword(@Body() dto: ResetPasswordDto) {
    return this.authService.resetPassword(dto.email);
  }
}
```

Create `src/auth/auth.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';

@Module({
  providers: [AuthService],
  controllers: [AuthController],
  exports: [AuthService],
})
export class AuthModule {}
```

Edit `src/app.module.ts` to add `AuthModule` to `imports`.

- [ ] **Step 7: Build and confirm nothing broke**

Run: `npm run build`
Expected: no TypeScript errors.

- [ ] **Step 8: Commit**

```bash
git add src/auth src/app.module.ts
git commit -m "feat: add AuthModule proxying Supabase Auth"
```

---

## Task 6: `JwtAuthGuard`

**Files:**
- Create: `src/common/guards/jwt-auth.guard.ts`
- Test: `src/common/guards/jwt-auth.guard.spec.ts`

**Interfaces:**
- Consumes: `ConfigService` (`SUPABASE_JWT_SECRET`).
- Produces: `JwtAuthGuard` (implements `CanActivate`), and sets `request.userId: string` on success. Consumed by `ProfilesController`, `WishlistsController`, `WishlistItemsController`, `GiftSuggestionsController` in later tasks (`@UseGuards(JwtAuthGuard)`).

- [ ] **Step 1: Write the failing test**

Create `src/common/guards/jwt-auth.guard.spec.ts`:

```typescript
import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as jwt from 'jsonwebtoken';
import { JwtAuthGuard } from './jwt-auth.guard';

function contextWithHeader(header?: string): ExecutionContext {
  const request: any = { headers: header ? { authorization: header } : {} };
  return {
    switchToHttp: () => ({ getRequest: () => request }),
  } as unknown as ExecutionContext;
}

describe('JwtAuthGuard', () => {
  const config = { get: () => 'test-secret' } as unknown as ConfigService;
  const guard = new JwtAuthGuard(config);

  it('allows a request with a valid bearer token and attaches userId', () => {
    const token = jwt.sign({ sub: 'user-1' }, 'test-secret');
    const context = contextWithHeader(`Bearer ${token}`);

    expect(guard.canActivate(context)).toBe(true);
    expect((context.switchToHttp().getRequest() as any).userId).toBe('user-1');
  });

  it('rejects a request with no authorization header', () => {
    expect(() => guard.canActivate(contextWithHeader())).toThrow(UnauthorizedException);
  });

  it('rejects a request with an invalid token', () => {
    expect(() => guard.canActivate(contextWithHeader('Bearer not-a-real-token'))).toThrow(UnauthorizedException);
  });
});
```

- [ ] **Step 2: Run it to verify it fails**

Run: `npm test -- jwt-auth.guard.spec`
Expected: FAIL — `JwtAuthGuard` doesn't exist.

- [ ] **Step 3: Implement it**

Create `src/common/guards/jwt-auth.guard.ts`:

```typescript
import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as jwt from 'jsonwebtoken';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private readonly config: ConfigService) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const header: string | undefined = request.headers.authorization;
    if (!header?.startsWith('Bearer ')) {
      throw new UnauthorizedException('Missing bearer token');
    }
    const token = header.slice('Bearer '.length);
    try {
      const payload = jwt.verify(token, this.config.get<string>('SUPABASE_JWT_SECRET')!) as { sub: string };
      request.userId = payload.sub;
      return true;
    } catch {
      throw new UnauthorizedException('Invalid or expired token');
    }
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `npm test -- jwt-auth.guard.spec`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/common/guards
git commit -m "feat: add JwtAuthGuard verifying Supabase-issued JWTs"
```

---

## Task 7: `ProfilesModule`

**Files:**
- Create: `src/profiles/dto/update-profile.dto.ts`
- Create: `src/profiles/dto/update-interests.dto.ts`
- Create: `src/profiles/profiles.service.ts`
- Create: `src/profiles/profiles.controller.ts`
- Create: `src/profiles/profiles.module.ts`
- Test: `src/profiles/profiles.service.spec.ts`

**Interfaces:**
- Consumes: `PrismaService` (Task 3), `JwtAuthGuard` (Task 6).
- Produces: `ProfilesService.getById/updateSelf/updateInterests`. `GET /profiles/me`, `PATCH /profiles/me`, `GET /profiles/:id`, `PATCH /profiles/me/interests` — all guarded by `JwtAuthGuard`. Avatar upload endpoint is added in Task 8 (needs `StorageService`).

- [ ] **Step 1: Write the DTOs**

Create `src/profiles/dto/update-profile.dto.ts`:

```typescript
import { IsDateString, IsOptional, IsString } from 'class-validator';

export class UpdateProfileDto {
  @IsOptional() @IsString() firstName?: string;
  @IsOptional() @IsString() lastName?: string;
  @IsOptional() @IsString() phone?: string;
  @IsOptional() @IsDateString() dateOfBirth?: string;
}
```

Create `src/profiles/dto/update-interests.dto.ts`:

```typescript
import { IsArray, IsString } from 'class-validator';

export class UpdateInterestsDto {
  @IsArray() @IsString({ each: true }) interests: string[];
}
```

- [ ] **Step 2: Write the failing test**

Create `src/profiles/profiles.service.spec.ts`:

```typescript
import { ProfilesService } from './profiles.service';
import { NotFoundException } from '@nestjs/common';

describe('ProfilesService', () => {
  function buildService(profile: any = null) {
    const prisma = {
      profile: {
        findUnique: jest.fn().mockResolvedValue(profile),
        update: jest.fn().mockResolvedValue(profile),
      },
    } as any;
    return { service: new ProfilesService(prisma), prisma };
  }

  it('getById returns the profile row', async () => {
    const { service } = buildService({ id: 'user-1', firstName: 'Ada' });
    const result = await service.getById('user-1');
    expect(result).toEqual({ id: 'user-1', firstName: 'Ada' });
  });

  it('getById throws NotFoundException when missing', async () => {
    const { service } = buildService(null);
    await expect(service.getById('missing')).rejects.toThrow(NotFoundException);
  });

  it('updateSelf updates only the provided fields', async () => {
    const { service, prisma } = buildService({ id: 'user-1' });
    await service.updateSelf('user-1', { firstName: 'Grace' });
    expect(prisma.profile.update).toHaveBeenCalledWith({
      where: { id: 'user-1' },
      data: { firstName: 'Grace' },
    });
  });

  it('updateInterests sets hasCompletedInterestsSetup to true', async () => {
    const { service, prisma } = buildService({ id: 'user-1' });
    await service.updateInterests('user-1', ['books', 'math']);
    expect(prisma.profile.update).toHaveBeenCalledWith({
      where: { id: 'user-1' },
      data: { interests: ['books', 'math'], hasCompletedInterestsSetup: true },
    });
  });
});
```

- [ ] **Step 3: Run it to verify it fails**

Run: `npm test -- profiles.service.spec`
Expected: FAIL — `ProfilesService` doesn't exist.

- [ ] **Step 4: Implement `ProfilesService`**

Create `src/profiles/profiles.service.ts`:

```typescript
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Injectable()
export class ProfilesService {
  constructor(private readonly prisma: PrismaService) {}

  async getById(userId: string) {
    const profile = await this.prisma.profile.findUnique({ where: { id: userId } });
    if (!profile) {
      throw new NotFoundException('Profile not found');
    }
    return profile;
  }

  async updateSelf(userId: string, dto: UpdateProfileDto) {
    const data: Record<string, unknown> = {};
    if (dto.firstName !== undefined) data.firstName = dto.firstName;
    if (dto.lastName !== undefined) data.lastName = dto.lastName;
    if (dto.phone !== undefined) data.phone = dto.phone;
    if (dto.dateOfBirth !== undefined) data.dateOfBirth = new Date(dto.dateOfBirth);
    return this.prisma.profile.update({ where: { id: userId }, data });
  }

  async updateInterests(userId: string, interests: string[]) {
    return this.prisma.profile.update({
      where: { id: userId },
      data: { interests, hasCompletedInterestsSetup: true },
    });
  }
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `npm test -- profiles.service.spec`
Expected: PASS

- [ ] **Step 6: Write the controller and module**

Create `src/profiles/profiles.controller.ts`:

```typescript
import { Body, Controller, Get, Param, Patch, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { ProfilesService } from './profiles.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { UpdateInterestsDto } from './dto/update-interests.dto';

@Controller('profiles')
@UseGuards(JwtAuthGuard)
export class ProfilesController {
  constructor(private readonly profilesService: ProfilesService) {}

  @Get('me')
  getMe(@Req() req: Request & { userId: string }) {
    return this.profilesService.getById(req.userId);
  }

  @Patch('me')
  updateMe(@Req() req: Request & { userId: string }, @Body() dto: UpdateProfileDto) {
    return this.profilesService.updateSelf(req.userId, dto);
  }

  @Get(':id')
  getById(@Param('id') id: string) {
    return this.profilesService.getById(id);
  }

  @Patch('me/interests')
  updateInterests(@Req() req: Request & { userId: string }, @Body() dto: UpdateInterestsDto) {
    return this.profilesService.updateInterests(req.userId, dto.interests);
  }
}
```

Create `src/profiles/profiles.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { ProfilesService } from './profiles.service';
import { ProfilesController } from './profiles.controller';

@Module({
  providers: [ProfilesService],
  controllers: [ProfilesController],
  exports: [ProfilesService],
})
export class ProfilesModule {}
```

Edit `src/app.module.ts` to add `ProfilesModule` to `imports`.

Note: route ordering matters — `@Get(':id')` must be declared after `@Get('me')` in the same controller so `/profiles/me` doesn't get captured by the `:id` param route. The order above (`me` before `:id`) is correct; keep it that way in Task 8 when the avatar route is added.

- [ ] **Step 7: Build and confirm nothing broke**

Run: `npm run build`
Expected: no TypeScript errors.

- [ ] **Step 8: Commit**

```bash
git add src/profiles src/app.module.ts
git commit -m "feat: add ProfilesModule for profile reads/writes"
```

---

## Task 8: `StorageService` and avatar upload

**Files:**
- Create: `src/storage/storage.service.ts`
- Create: `src/storage/storage.module.ts`
- Modify: `src/profiles/profiles.controller.ts`
- Modify: `src/profiles/profiles.module.ts`
- Test: `src/storage/storage.service.spec.ts`

**Interfaces:**
- Consumes: `SupabaseAdminService` (Task 4).
- Produces: `StorageService.uploadAvatar(userId, buffer, contentType): Promise<string>` and `StorageService.uploadItemImage(fileName, buffer, contentType): Promise<string>`, both returning a public URL. Consumed here by `ProfilesController` and later by `WishlistItemsModule` (Task 10).

- [ ] **Step 1: Write the failing test**

Create `src/storage/storage.service.spec.ts`:

```typescript
import { StorageService } from './storage.service';

describe('StorageService', () => {
  function buildService() {
    const upload = jest.fn().mockResolvedValue({ error: null });
    const getPublicUrl = jest.fn().mockReturnValue({ data: { publicUrl: 'https://cdn.example/avatar/user-1.jpg' } });
    const from = jest.fn().mockReturnValue({ upload, getPublicUrl });
    const supabaseAdmin = { client: { storage: { from } } } as any;
    return { service: new StorageService(supabaseAdmin), from, upload, getPublicUrl };
  }

  it('uploadAvatar writes to avatar/{userId}.jpg and returns a cache-busted public URL', async () => {
    const { service, from, upload } = buildService();
    const url = await service.uploadAvatar('user-1', Buffer.from('data'), 'image/jpeg');

    expect(from).toHaveBeenCalledWith('Wishie');
    expect(upload).toHaveBeenCalledWith(
      'avatar/user-1.jpg',
      Buffer.from('data'),
      { contentType: 'image/jpeg', upsert: true },
    );
    expect(url.startsWith('https://cdn.example/avatar/user-1.jpg?t=')).toBe(true);
  });

  it('uploadItemImage writes to wishlist/{fileName}.jpg', async () => {
    const { service, upload } = buildService();
    await service.uploadItemImage('abc123', Buffer.from('data'), 'image/jpeg');
    expect(upload).toHaveBeenCalledWith(
      'wishlist/abc123.jpg',
      Buffer.from('data'),
      { contentType: 'image/jpeg', upsert: true },
    );
  });
});
```

- [ ] **Step 2: Run it to verify it fails**

Run: `npm test -- storage.service.spec`
Expected: FAIL — `StorageService` doesn't exist.

- [ ] **Step 3: Implement `StorageService`**

Create `src/storage/storage.service.ts`:

```typescript
import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { SupabaseAdminService } from '../supabase-admin/supabase-admin.service';

const BUCKET = 'Wishie';

@Injectable()
export class StorageService {
  constructor(private readonly supabaseAdmin: SupabaseAdminService) {}

  async uploadAvatar(userId: string, data: Buffer, contentType: string): Promise<string> {
    return this.uploadAndGetUrl(`avatar/${userId}.jpg`, data, contentType, true);
  }

  async uploadItemImage(fileName: string, data: Buffer, contentType: string): Promise<string> {
    return this.uploadAndGetUrl(`wishlist/${fileName}.jpg`, data, contentType, false);
  }

  private async uploadAndGetUrl(path: string, data: Buffer, contentType: string, cacheBust: boolean): Promise<string> {
    const bucket = this.supabaseAdmin.client.storage.from(BUCKET);
    const { error } = await bucket.upload(path, data, { contentType, upsert: true });
    if (error) {
      throw new InternalServerErrorException(`Upload failed: ${error.message}`);
    }
    const { data: urlData } = bucket.getPublicUrl(path);
    return cacheBust ? `${urlData.publicUrl}?t=${Date.now()}` : urlData.publicUrl;
  }
}
```

Create `src/storage/storage.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { StorageService } from './storage.service';

@Module({
  providers: [StorageService],
  exports: [StorageService],
})
export class StorageModule {}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `npm test -- storage.service.spec`
Expected: PASS

- [ ] **Step 5: Add the avatar upload endpoint**

Edit `src/profiles/profiles.module.ts` to import `StorageModule`:

```typescript
import { Module } from '@nestjs/common';
import { ProfilesService } from './profiles.service';
import { ProfilesController } from './profiles.controller';
import { StorageModule } from '../storage/storage.module';

@Module({
  imports: [StorageModule],
  providers: [ProfilesService],
  controllers: [ProfilesController],
  exports: [ProfilesService],
})
export class ProfilesModule {}
```

Edit `src/profiles/profiles.controller.ts` — add the avatar route (after `updateMe`, before the `:id` route stays last per the ordering note in Task 7):

```typescript
import { Body, Controller, Get, Param, Patch, Post, Req, UploadedFile, UseGuards, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Request } from 'express';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { ProfilesService } from './profiles.service';
import { StorageService } from '../storage/storage.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { UpdateInterestsDto } from './dto/update-interests.dto';

@Controller('profiles')
@UseGuards(JwtAuthGuard)
export class ProfilesController {
  constructor(
    private readonly profilesService: ProfilesService,
    private readonly storageService: StorageService,
  ) {}

  @Get('me')
  getMe(@Req() req: Request & { userId: string }) {
    return this.profilesService.getById(req.userId);
  }

  @Patch('me')
  updateMe(@Req() req: Request & { userId: string }, @Body() dto: UpdateProfileDto) {
    return this.profilesService.updateSelf(req.userId, dto);
  }

  @Patch('me/interests')
  updateInterests(@Req() req: Request & { userId: string }, @Body() dto: UpdateInterestsDto) {
    return this.profilesService.updateInterests(req.userId, dto.interests);
  }

  @Post('me/avatar')
  @UseInterceptors(FileInterceptor('file'))
  async uploadAvatar(@Req() req: Request & { userId: string }, @UploadedFile() file: Express.Multer.File) {
    const avatarUrl = await this.storageService.uploadAvatar(req.userId, file.buffer, file.mimetype);
    await this.profilesService.updateSelf(req.userId, {});
    await this.profilesService.updateAvatarUrl(req.userId, avatarUrl);
    return { avatarUrl };
  }

  @Get(':id')
  getById(@Param('id') id: string) {
    return this.profilesService.getById(id);
  }
}
```

Add `updateAvatarUrl` to `src/profiles/profiles.service.ts` (append inside the class):

```typescript
  async updateAvatarUrl(userId: string, avatarUrl: string) {
    return this.prisma.profile.update({ where: { id: userId }, data: { avatarUrl } });
  }
```

Remove the redundant `await this.profilesService.updateSelf(req.userId, {})` line from `uploadAvatar` above — it's a no-op left over from drafting; the final controller method body is:

```typescript
  @Post('me/avatar')
  @UseInterceptors(FileInterceptor('file'))
  async uploadAvatar(@Req() req: Request & { userId: string }, @UploadedFile() file: Express.Multer.File) {
    const avatarUrl = await this.storageService.uploadAvatar(req.userId, file.buffer, file.mimetype);
    await this.profilesService.updateAvatarUrl(req.userId, avatarUrl);
    return { avatarUrl };
  }
```

- [ ] **Step 6: Add a unit test for `updateAvatarUrl`**

Append to `src/profiles/profiles.service.spec.ts`:

```typescript
  it('updateAvatarUrl sets the avatarUrl field', async () => {
    const { service, prisma } = buildService({ id: 'user-1' });
    await service.updateAvatarUrl('user-1', 'https://cdn.example/avatar/user-1.jpg');
    expect(prisma.profile.update).toHaveBeenCalledWith({
      where: { id: 'user-1' },
      data: { avatarUrl: 'https://cdn.example/avatar/user-1.jpg' },
    });
  });
```

Run: `npm test -- profiles.service.spec`
Expected: PASS

- [ ] **Step 7: Build and confirm nothing broke**

Run: `npm run build`
Expected: no TypeScript errors.

- [ ] **Step 8: Commit**

```bash
git add src/storage src/profiles
git commit -m "feat: add StorageService and avatar upload endpoint"
```

---

## Task 9: `WishlistMembersService` + `WishlistsModule`

**Files:**
- Create: `src/wishlists/wishlist-members.service.ts`
- Create: `src/wishlists/dto/create-wishlist.dto.ts`
- Create: `src/wishlists/dto/update-wishlist.dto.ts`
- Create: `src/wishlists/wishlists.service.ts`
- Create: `src/wishlists/wishlists.controller.ts`
- Create: `src/wishlists/wishlists.module.ts`
- Test: `src/wishlists/wishlist-members.service.spec.ts`
- Test: `src/wishlists/wishlists.service.spec.ts`

**Interfaces:**
- Consumes: `PrismaService` (Task 3).
- Produces: `WishlistMembersService.isMember(wishlistId, userId): Promise<boolean>`, `.isOwner(wishlistId, userId): Promise<boolean>` — consumed by `WishlistsService` here and `WishlistItemsService` in Task 10. `WishlistsService.create/getById/listForUser/update/delete/setArchived/join/leave`. `GET/POST /wishlists`, `GET/PATCH/DELETE /wishlists/:id`, `PATCH /wishlists/:id/archive`, `POST /wishlists/:id/join`, `POST /wishlists/:id/leave` — all guarded by `JwtAuthGuard`.

- [ ] **Step 1: Write the failing test for `WishlistMembersService`**

Create `src/wishlists/wishlist-members.service.spec.ts`:

```typescript
import { WishlistMembersService } from './wishlist-members.service';

describe('WishlistMembersService', () => {
  function buildService(member: any = null) {
    const prisma = { wishlistMember: { findUnique: jest.fn().mockResolvedValue(member) } } as any;
    return { service: new WishlistMembersService(prisma), prisma };
  }

  it('isMember returns true when a membership row exists', async () => {
    const { service } = buildService({ role: 'member' });
    expect(await service.isMember('wl-1', 'user-1')).toBe(true);
  });

  it('isMember returns false when no membership row exists', async () => {
    const { service } = buildService(null);
    expect(await service.isMember('wl-1', 'user-1')).toBe(false);
  });

  it('isOwner returns true only when the member row has role "owner"', async () => {
    const { service } = buildService({ role: 'owner' });
    expect(await service.isOwner('wl-1', 'user-1')).toBe(true);
  });

  it('isOwner returns false for a plain member', async () => {
    const { service } = buildService({ role: 'member' });
    expect(await service.isOwner('wl-1', 'user-1')).toBe(false);
  });
});
```

- [ ] **Step 2: Run it to verify it fails**

Run: `npm test -- wishlist-members.service.spec`
Expected: FAIL — `WishlistMembersService` doesn't exist.

- [ ] **Step 3: Implement `WishlistMembersService`**

Create `src/wishlists/wishlist-members.service.ts`:

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class WishlistMembersService {
  constructor(private readonly prisma: PrismaService) {}

  async isMember(wishlistId: string, userId: string): Promise<boolean> {
    const member = await this.prisma.wishlistMember.findUnique({
      where: { wishlistId_userId: { wishlistId, userId } },
    });
    return member !== null;
  }

  async isOwner(wishlistId: string, userId: string): Promise<boolean> {
    const member = await this.prisma.wishlistMember.findUnique({
      where: { wishlistId_userId: { wishlistId, userId } },
    });
    return member?.role === 'owner';
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `npm test -- wishlist-members.service.spec`
Expected: PASS

- [ ] **Step 5: Write the DTOs**

Create `src/wishlists/dto/create-wishlist.dto.ts`:

```typescript
import { IsDateString, IsOptional, IsString } from 'class-validator';

export class CreateWishlistDto {
  @IsString() id: string;
  @IsString() name: string;
  @IsOptional() @IsString() description?: string;
  @IsDateString() dueDate: string;
  @IsOptional() @IsString() colorTheme?: string;
}
```

Create `src/wishlists/dto/update-wishlist.dto.ts`:

```typescript
import { IsDateString, IsOptional, IsString } from 'class-validator';

export class UpdateWishlistDto {
  @IsOptional() @IsString() name?: string;
  @IsOptional() @IsString() description?: string;
  @IsOptional() @IsDateString() dueDate?: string;
  @IsOptional() @IsString() colorTheme?: string;
}
```

- [ ] **Step 6: Write the failing test for `WishlistsService`**

Create `src/wishlists/wishlists.service.spec.ts`:

```typescript
import { ForbiddenException } from '@nestjs/common';
import { WishlistsService } from './wishlists.service';

describe('WishlistsService', () => {
  function buildService() {
    const prisma = {
      wishlist: {
        create: jest.fn(),
        findUnique: jest.fn(),
        findMany: jest.fn(),
        update: jest.fn(),
        delete: jest.fn(),
      },
      wishlistMember: {
        create: jest.fn(),
        delete: jest.fn(),
        findMany: jest.fn(),
      },
    } as any;
    const members = { isMember: jest.fn(), isOwner: jest.fn() } as any;
    return { service: new WishlistsService(prisma, members), prisma, members };
  }

  it('create inserts the wishlist and an owner membership row', async () => {
    const { service, prisma } = buildService();
    await service.create('user-1', { id: 'wl-1', name: 'Birthday', dueDate: '2026-12-25' });

    expect(prisma.wishlist.create).toHaveBeenCalledWith({
      data: expect.objectContaining({ id: 'wl-1', name: 'Birthday', ownerId: 'user-1' }),
    });
    expect(prisma.wishlistMember.create).toHaveBeenCalledWith({
      data: { wishlistId: 'wl-1', userId: 'user-1', role: 'owner' },
    });
  });

  it('update throws ForbiddenException for a non-member', async () => {
    const { service, members } = buildService();
    members.isMember.mockResolvedValue(false);

    await expect(service.update('wl-1', 'stranger', { name: 'New name' })).rejects.toThrow(ForbiddenException);
  });

  it('delete throws ForbiddenException for a non-owner', async () => {
    const { service, members } = buildService();
    members.isOwner.mockResolvedValue(false);

    await expect(service.delete('wl-1', 'not-owner')).rejects.toThrow(ForbiddenException);
  });

  it('join creates a member membership row', async () => {
    const { service, prisma } = buildService();
    await service.join('wl-1', 'user-2');
    expect(prisma.wishlistMember.create).toHaveBeenCalledWith({
      data: { wishlistId: 'wl-1', userId: 'user-2', role: 'member' },
    });
  });
});
```

- [ ] **Step 7: Run it to verify it fails**

Run: `npm test -- wishlists.service.spec`
Expected: FAIL — `WishlistsService` doesn't exist.

- [ ] **Step 8: Implement `WishlistsService`**

Create `src/wishlists/wishlists.service.ts`:

```typescript
import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { WishlistMembersService } from './wishlist-members.service';
import { CreateWishlistDto } from './dto/create-wishlist.dto';
import { UpdateWishlistDto } from './dto/update-wishlist.dto';

@Injectable()
export class WishlistsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly members: WishlistMembersService,
  ) {}

  async create(ownerId: string, dto: CreateWishlistDto) {
    await this.prisma.wishlist.create({
      data: {
        id: dto.id,
        name: dto.name,
        description: dto.description ?? '',
        ownerId,
        dueDate: new Date(dto.dueDate),
        colorTheme: dto.colorTheme,
      },
    });
    await this.prisma.wishlistMember.create({ data: { wishlistId: dto.id, userId: ownerId, role: 'owner' } });
    return this.getById(dto.id, ownerId);
  }

  async getById(wishlistId: string, requesterId: string) {
    if (!(await this.members.isMember(wishlistId, requesterId))) {
      throw new ForbiddenException('Not a member of this wishlist');
    }
    const wishlist = await this.prisma.wishlist.findUnique({
      where: { id: wishlistId },
      include: { members: true, items: true },
    });
    if (!wishlist) {
      throw new NotFoundException('Wishlist not found');
    }
    return wishlist;
  }

  async listForUser(userId: string) {
    return this.prisma.wishlist.findMany({
      where: { members: { some: { userId } } },
      include: { members: true, items: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async update(wishlistId: string, requesterId: string, dto: UpdateWishlistDto) {
    if (!(await this.members.isMember(wishlistId, requesterId))) {
      throw new ForbiddenException('Not a member of this wishlist');
    }
    const data: Record<string, unknown> = {};
    if (dto.name !== undefined) data.name = dto.name;
    if (dto.description !== undefined) data.description = dto.description;
    if (dto.dueDate !== undefined) data.dueDate = new Date(dto.dueDate);
    if (dto.colorTheme !== undefined) data.colorTheme = dto.colorTheme;
    return this.prisma.wishlist.update({ where: { id: wishlistId }, data });
  }

  async setArchived(wishlistId: string, requesterId: string, isArchived: boolean) {
    if (!(await this.members.isMember(wishlistId, requesterId))) {
      throw new ForbiddenException('Not a member of this wishlist');
    }
    return this.prisma.wishlist.update({ where: { id: wishlistId }, data: { isArchived } });
  }

  async delete(wishlistId: string, requesterId: string) {
    if (!(await this.members.isOwner(wishlistId, requesterId))) {
      throw new ForbiddenException('Only the owner can delete this wishlist');
    }
    await this.prisma.wishlist.delete({ where: { id: wishlistId } });
    return { success: true };
  }

  async join(wishlistId: string, userId: string) {
    await this.prisma.wishlistMember.create({ data: { wishlistId, userId, role: 'member' } });
    return { success: true };
  }

  async leave(wishlistId: string, userId: string) {
    await this.prisma.wishlistMember.delete({ where: { wishlistId_userId: { wishlistId, userId } } });
    return { success: true };
  }
}
```

- [ ] **Step 9: Run the test to verify it passes**

Run: `npm test -- wishlists.service.spec`
Expected: PASS

- [ ] **Step 10: Write the controller and module**

Create `src/wishlists/wishlists.controller.ts`:

```typescript
import { Body, Controller, Delete, Get, Param, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { WishlistsService } from './wishlists.service';
import { CreateWishlistDto } from './dto/create-wishlist.dto';
import { UpdateWishlistDto } from './dto/update-wishlist.dto';

@Controller('wishlists')
@UseGuards(JwtAuthGuard)
export class WishlistsController {
  constructor(private readonly wishlistsService: WishlistsService) {}

  @Post()
  create(@Req() req: Request & { userId: string }, @Body() dto: CreateWishlistDto) {
    return this.wishlistsService.create(req.userId, dto);
  }

  @Get()
  listMine(@Req() req: Request & { userId: string }) {
    return this.wishlistsService.listForUser(req.userId);
  }

  @Get(':id')
  getById(@Req() req: Request & { userId: string }, @Param('id') id: string) {
    return this.wishlistsService.getById(id, req.userId);
  }

  @Patch(':id')
  update(@Req() req: Request & { userId: string }, @Param('id') id: string, @Body() dto: UpdateWishlistDto) {
    return this.wishlistsService.update(id, req.userId, dto);
  }

  @Delete(':id')
  delete(@Req() req: Request & { userId: string }, @Param('id') id: string) {
    return this.wishlistsService.delete(id, req.userId);
  }

  @Patch(':id/archive')
  setArchived(@Req() req: Request & { userId: string }, @Param('id') id: string, @Body('isArchived') isArchived: boolean) {
    return this.wishlistsService.setArchived(id, req.userId, isArchived);
  }

  @Post(':id/join')
  join(@Req() req: Request & { userId: string }, @Param('id') id: string) {
    return this.wishlistsService.join(id, req.userId);
  }

  @Post(':id/leave')
  leave(@Req() req: Request & { userId: string }, @Param('id') id: string) {
    return this.wishlistsService.leave(id, req.userId);
  }
}
```

Create `src/wishlists/wishlists.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { WishlistsService } from './wishlists.service';
import { WishlistMembersService } from './wishlist-members.service';
import { WishlistsController } from './wishlists.controller';

@Module({
  providers: [WishlistsService, WishlistMembersService],
  controllers: [WishlistsController],
  exports: [WishlistMembersService],
})
export class WishlistsModule {}
```

Edit `src/app.module.ts` to add `WishlistsModule` to `imports`.

- [ ] **Step 11: Build and confirm nothing broke**

Run: `npm run build`
Expected: no TypeScript errors.

- [ ] **Step 12: Commit**

```bash
git add src/wishlists src/app.module.ts
git commit -m "feat: add WishlistsModule with hand-written membership authorization"
```

---

## Task 10: `MostDesiredRule` + `WishlistItemsModule`

**Files:**
- Create: `src/wishlist-items/most-desired-rule.ts`
- Create: `src/wishlist-items/dto/create-item.dto.ts`
- Create: `src/wishlist-items/dto/update-item.dto.ts`
- Create: `src/wishlist-items/wishlist-items.service.ts`
- Create: `src/wishlist-items/wishlist-items.controller.ts`
- Create: `src/wishlist-items/wishlist-items.module.ts`
- Test: `src/wishlist-items/most-desired-rule.spec.ts`
- Test: `src/wishlist-items/wishlist-items.service.spec.ts`

**Interfaces:**
- Consumes: `PrismaService` (Task 3), `WishlistMembersService` (Task 9, exported), `StorageService` (Task 8).
- Produces: `WishlistItemsService.create/update/delete/pick/setMostDesired`. `POST /wishlists/:id/items`, `PATCH/DELETE /wishlists/:id/items/:itemId`, `POST /wishlists/:id/items/:itemId/pick`, `PATCH /wishlists/:id/items/:itemId/most-desired`.

- [ ] **Step 1: Write the failing test for `MostDesiredRule`**

Create `src/wishlist-items/most-desired-rule.spec.ts`:

```typescript
import { needsClearingOthers } from './most-desired-rule';

describe('needsClearingOthers', () => {
  it('is true when marking an item most-desired', () => {
    expect(needsClearingOthers(true)).toBe(true);
  });

  it('is false when unmarking', () => {
    expect(needsClearingOthers(false)).toBe(false);
  });
});
```

- [ ] **Step 2: Run it to verify it fails**

Run: `npm test -- most-desired-rule.spec`
Expected: FAIL — `needsClearingOthers` doesn't exist.

- [ ] **Step 3: Implement it**

Create `src/wishlist-items/most-desired-rule.ts`:

```typescript
/**
 * A wishlist may hold at most one most-desired item. Marking a new item
 * most-desired therefore requires clearing the flag on every other item
 * in the same wishlist in the same operation.
 */
export function needsClearingOthers(isMostDesired: boolean): boolean {
  return isMostDesired;
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `npm test -- most-desired-rule.spec`
Expected: PASS

- [ ] **Step 5: Write the DTOs**

Create `src/wishlist-items/dto/create-item.dto.ts`:

```typescript
import { IsOptional, IsString } from 'class-validator';

export class CreateItemDto {
  @IsString() id: string;
  @IsString() name: string;
  @IsOptional() @IsString() description?: string;
  @IsOptional() @IsString() itemLink?: string;
  @IsOptional() @IsString() price?: string;
}
```

Create `src/wishlist-items/dto/update-item.dto.ts`:

```typescript
import { IsOptional, IsString } from 'class-validator';

export class UpdateItemDto {
  @IsOptional() @IsString() name?: string;
  @IsOptional() @IsString() description?: string;
  @IsOptional() @IsString() itemLink?: string;
  @IsOptional() @IsString() price?: string;
}
```

- [ ] **Step 6: Write the failing test for `WishlistItemsService`**

Create `src/wishlist-items/wishlist-items.service.spec.ts`:

```typescript
import { ForbiddenException } from '@nestjs/common';
import { WishlistItemsService } from './wishlist-items.service';

describe('WishlistItemsService', () => {
  function buildService() {
    const prisma = {
      wishlistItem: {
        create: jest.fn(),
        update: jest.fn(),
        updateMany: jest.fn(),
        delete: jest.fn(),
      },
      $transaction: jest.fn((ops: Promise<unknown>[]) => Promise.all(ops)),
    } as any;
    const members = { isMember: jest.fn().mockResolvedValue(true) } as any;
    return { service: new WishlistItemsService(prisma, members), prisma, members };
  }

  it('create rejects a non-member', async () => {
    const { service, members } = buildService();
    members.isMember.mockResolvedValue(false);

    await expect(service.create('wl-1', 'stranger', { id: 'it-1', name: 'Book' })).rejects.toThrow(ForbiddenException);
  });

  it('create inserts the item under the wishlist', async () => {
    const { service, prisma } = buildService();
    await service.create('wl-1', 'user-1', { id: 'it-1', name: 'Book' });

    expect(prisma.wishlistItem.create).toHaveBeenCalledWith({
      data: expect.objectContaining({ id: 'it-1', wishlistId: 'wl-1', name: 'Book' }),
    });
  });

  it('pick sets isPicked and pickedBy for the requesting user', async () => {
    const { service, prisma } = buildService();
    await service.pick('wl-1', 'it-1', 'user-1');

    expect(prisma.wishlistItem.update).toHaveBeenCalledWith({
      where: { id: 'it-1' },
      data: { isPicked: true, pickedBy: 'user-1' },
    });
  });

  it('setMostDesired(true) clears other items in the wishlist first, then sets this one', async () => {
    const { service, prisma } = buildService();
    await service.setMostDesired('wl-1', 'it-1', 'user-1', true);

    expect(prisma.wishlistItem.updateMany).toHaveBeenCalledWith({
      where: { wishlistId: 'wl-1', id: { not: 'it-1' } },
      data: { isMostDesired: false },
    });
    expect(prisma.wishlistItem.update).toHaveBeenCalledWith({
      where: { id: 'it-1' },
      data: { isMostDesired: true },
    });
  });

  it('setMostDesired(false) only updates this item, no clearing', async () => {
    const { service, prisma } = buildService();
    await service.setMostDesired('wl-1', 'it-1', 'user-1', false);

    expect(prisma.wishlistItem.updateMany).not.toHaveBeenCalled();
    expect(prisma.wishlistItem.update).toHaveBeenCalledWith({
      where: { id: 'it-1' },
      data: { isMostDesired: false },
    });
  });
});
```

- [ ] **Step 7: Run it to verify it fails**

Run: `npm test -- wishlist-items.service.spec`
Expected: FAIL — `WishlistItemsService` doesn't exist.

- [ ] **Step 8: Implement `WishlistItemsService`**

Create `src/wishlist-items/wishlist-items.service.ts`:

```typescript
import { ForbiddenException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { WishlistMembersService } from '../wishlists/wishlist-members.service';
import { CreateItemDto } from './dto/create-item.dto';
import { UpdateItemDto } from './dto/update-item.dto';
import { needsClearingOthers } from './most-desired-rule';

@Injectable()
export class WishlistItemsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly members: WishlistMembersService,
  ) {}

  private async assertMember(wishlistId: string, userId: string) {
    if (!(await this.members.isMember(wishlistId, userId))) {
      throw new ForbiddenException('Not a member of this wishlist');
    }
  }

  async create(wishlistId: string, userId: string, dto: CreateItemDto) {
    await this.assertMember(wishlistId, userId);
    return this.prisma.wishlistItem.create({
      data: {
        id: dto.id,
        wishlistId,
        name: dto.name,
        description: dto.description ?? '',
        itemLink: dto.itemLink ?? '',
        price: dto.price,
      },
    });
  }

  async update(wishlistId: string, itemId: string, userId: string, dto: UpdateItemDto, imageUrl?: string) {
    await this.assertMember(wishlistId, userId);
    const data: Record<string, unknown> = {};
    if (dto.name !== undefined) data.name = dto.name;
    if (dto.description !== undefined) data.description = dto.description;
    if (dto.itemLink !== undefined) data.itemLink = dto.itemLink;
    if (dto.price !== undefined) data.price = dto.price;
    if (imageUrl !== undefined) data.imageUrl = imageUrl;
    return this.prisma.wishlistItem.update({ where: { id: itemId }, data });
  }

  async delete(wishlistId: string, itemId: string, userId: string) {
    await this.assertMember(wishlistId, userId);
    await this.prisma.wishlistItem.delete({ where: { id: itemId } });
    return { success: true };
  }

  async pick(wishlistId: string, itemId: string, userId: string) {
    await this.assertMember(wishlistId, userId);
    return this.prisma.wishlistItem.update({
      where: { id: itemId },
      data: { isPicked: true, pickedBy: userId },
    });
  }

  async setMostDesired(wishlistId: string, itemId: string, userId: string, isMostDesired: boolean) {
    await this.assertMember(wishlistId, userId);
    if (needsClearingOthers(isMostDesired)) {
      await this.prisma.wishlistItem.updateMany({
        where: { wishlistId, id: { not: itemId } },
        data: { isMostDesired: false },
      });
    }
    return this.prisma.wishlistItem.update({ where: { id: itemId }, data: { isMostDesired } });
  }
}
```

- [ ] **Step 9: Run the test to verify it passes**

Run: `npm test -- wishlist-items.service.spec`
Expected: PASS

- [ ] **Step 10: Write the controller and module**

Create `src/wishlist-items/wishlist-items.controller.ts`:

```typescript
import { Body, Controller, Delete, Param, Patch, Post, Req, UploadedFile, UseGuards, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Request } from 'express';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { WishlistItemsService } from './wishlist-items.service';
import { StorageService } from '../storage/storage.service';
import { CreateItemDto } from './dto/create-item.dto';
import { UpdateItemDto } from './dto/update-item.dto';

@Controller('wishlists/:wishlistId/items')
@UseGuards(JwtAuthGuard)
export class WishlistItemsController {
  constructor(
    private readonly itemsService: WishlistItemsService,
    private readonly storageService: StorageService,
  ) {}

  @Post()
  @UseInterceptors(FileInterceptor('file'))
  async create(
    @Req() req: Request & { userId: string },
    @Param('wishlistId') wishlistId: string,
    @Body() dto: CreateItemDto,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    const item = await this.itemsService.create(wishlistId, req.userId, dto);
    if (file) {
      const imageUrl = await this.storageService.uploadItemImage(dto.id, file.buffer, file.mimetype);
      return this.itemsService.update(wishlistId, dto.id, req.userId, {}, imageUrl);
    }
    return item;
  }

  @Patch(':itemId')
  @UseInterceptors(FileInterceptor('file'))
  async update(
    @Req() req: Request & { userId: string },
    @Param('wishlistId') wishlistId: string,
    @Param('itemId') itemId: string,
    @Body() dto: UpdateItemDto,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    const imageUrl = file
      ? await this.storageService.uploadItemImage(itemId, file.buffer, file.mimetype)
      : undefined;
    return this.itemsService.update(wishlistId, itemId, req.userId, dto, imageUrl);
  }

  @Delete(':itemId')
  delete(@Req() req: Request & { userId: string }, @Param('wishlistId') wishlistId: string, @Param('itemId') itemId: string) {
    return this.itemsService.delete(wishlistId, itemId, req.userId);
  }

  @Post(':itemId/pick')
  pick(@Req() req: Request & { userId: string }, @Param('wishlistId') wishlistId: string, @Param('itemId') itemId: string) {
    return this.itemsService.pick(wishlistId, itemId, req.userId);
  }

  @Patch(':itemId/most-desired')
  setMostDesired(
    @Req() req: Request & { userId: string },
    @Param('wishlistId') wishlistId: string,
    @Param('itemId') itemId: string,
    @Body('isMostDesired') isMostDesired: boolean,
  ) {
    return this.itemsService.setMostDesired(wishlistId, itemId, req.userId, isMostDesired);
  }
}
```

Create `src/wishlist-items/wishlist-items.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { WishlistItemsService } from './wishlist-items.service';
import { WishlistItemsController } from './wishlist-items.controller';
import { WishlistsModule } from '../wishlists/wishlists.module';
import { StorageModule } from '../storage/storage.module';

@Module({
  imports: [WishlistsModule, StorageModule],
  providers: [WishlistItemsService],
  controllers: [WishlistItemsController],
})
export class WishlistItemsModule {}
```

Edit `src/app.module.ts` to add `WishlistItemsModule` to `imports`.

- [ ] **Step 11: Build and confirm nothing broke**

Run: `npm run build`
Expected: no TypeScript errors.

- [ ] **Step 12: Commit**

```bash
git add src/wishlist-items src/app.module.ts
git commit -m "feat: add WishlistItemsModule with most-desired clearing rule"
```

---

## Task 11: `RealtimeGateway` (Socket.io)

**Files:**
- Create: `src/realtime/realtime.gateway.ts`
- Create: `src/realtime/realtime.module.ts`
- Modify: `src/wishlists/wishlists.module.ts`
- Modify: `src/wishlists/wishlists.service.ts`
- Modify: `src/wishlist-items/wishlist-items.module.ts`
- Modify: `src/wishlist-items/wishlist-items.service.ts`
- Test: `src/realtime/realtime.gateway.spec.ts`

**Interfaces:**
- Produces: `RealtimeGateway.emitWishlistUpdated(wishlistId: string, event: string, payload: unknown): void`, and a `join` message handler that puts the connecting socket into room `wishlist:{wishlistId}`. Consumed by `WishlistsService` and `WishlistItemsService` (injected) after every mutation.

- [ ] **Step 1: Write the failing test**

Create `src/realtime/realtime.gateway.spec.ts`:

```typescript
import { RealtimeGateway } from './realtime.gateway';

describe('RealtimeGateway', () => {
  it('emitWishlistUpdated emits to the room named wishlist:{id}', () => {
    const gateway = new RealtimeGateway();
    const emit = jest.fn();
    const to = jest.fn().mockReturnValue({ emit });
    (gateway as any).server = { to };

    gateway.emitWishlistUpdated('wl-1', 'item.updated', { itemId: 'it-1' });

    expect(to).toHaveBeenCalledWith('wishlist:wl-1');
    expect(emit).toHaveBeenCalledWith('item.updated', { itemId: 'it-1' });
  });

  it('handleJoin puts the client socket into the wishlist room', () => {
    const gateway = new RealtimeGateway();
    const join = jest.fn();
    const client = { join } as any;

    gateway.handleJoin({ wishlistId: 'wl-1' }, client);

    expect(join).toHaveBeenCalledWith('wishlist:wl-1');
  });
});
```

- [ ] **Step 2: Run it to verify it fails**

Run: `npm test -- realtime.gateway.spec`
Expected: FAIL — `RealtimeGateway` doesn't exist.

- [ ] **Step 3: Implement it**

Create `src/realtime/realtime.gateway.ts`:

```typescript
import { SubscribeMessage, WebSocketGateway, WebSocketServer } from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

@WebSocketGateway({ cors: { origin: '*' } })
export class RealtimeGateway {
  @WebSocketServer()
  server: Server;

  @SubscribeMessage('join')
  handleJoin(payload: { wishlistId: string }, client: Socket) {
    client.join(`wishlist:${payload.wishlistId}`);
  }

  emitWishlistUpdated(wishlistId: string, event: string, payload: unknown): void {
    this.server.to(`wishlist:${wishlistId}`).emit(event, payload);
  }
}
```

Create `src/realtime/realtime.module.ts`:

```typescript
import { Global, Module } from '@nestjs/common';
import { RealtimeGateway } from './realtime.gateway';

@Global()
@Module({
  providers: [RealtimeGateway],
  exports: [RealtimeGateway],
})
export class RealtimeModule {}
```

Edit `src/app.module.ts` to add `RealtimeModule` to `imports`.

- [ ] **Step 4: Run the test to verify it passes**

Run: `npm test -- realtime.gateway.spec`
Expected: PASS

- [ ] **Step 5: Wire emits into `WishlistsService`**

Edit `src/wishlists/wishlists.service.ts` — inject `RealtimeGateway` and emit after each mutating method. Update the constructor and the five mutating methods:

```typescript
import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { WishlistMembersService } from './wishlist-members.service';
import { RealtimeGateway } from '../realtime/realtime.gateway';
import { CreateWishlistDto } from './dto/create-wishlist.dto';
import { UpdateWishlistDto } from './dto/update-wishlist.dto';

@Injectable()
export class WishlistsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly members: WishlistMembersService,
    private readonly realtime: RealtimeGateway,
  ) {}

  // create/getById/listForUser unchanged from Task 9 ...

  async update(wishlistId: string, requesterId: string, dto: UpdateWishlistDto) {
    if (!(await this.members.isMember(wishlistId, requesterId))) {
      throw new ForbiddenException('Not a member of this wishlist');
    }
    const data: Record<string, unknown> = {};
    if (dto.name !== undefined) data.name = dto.name;
    if (dto.description !== undefined) data.description = dto.description;
    if (dto.dueDate !== undefined) data.dueDate = new Date(dto.dueDate);
    if (dto.colorTheme !== undefined) data.colorTheme = dto.colorTheme;
    const wishlist = await this.prisma.wishlist.update({ where: { id: wishlistId }, data });
    this.realtime.emitWishlistUpdated(wishlistId, 'wishlist.updated', wishlist);
    return wishlist;
  }

  async setArchived(wishlistId: string, requesterId: string, isArchived: boolean) {
    if (!(await this.members.isMember(wishlistId, requesterId))) {
      throw new ForbiddenException('Not a member of this wishlist');
    }
    const wishlist = await this.prisma.wishlist.update({ where: { id: wishlistId }, data: { isArchived } });
    this.realtime.emitWishlistUpdated(wishlistId, 'wishlist.updated', wishlist);
    return wishlist;
  }

  async join(wishlistId: string, userId: string) {
    await this.prisma.wishlistMember.create({ data: { wishlistId, userId, role: 'member' } });
    this.realtime.emitWishlistUpdated(wishlistId, 'wishlist.member_joined', { userId });
    return { success: true };
  }

  async leave(wishlistId: string, userId: string) {
    await this.prisma.wishlistMember.delete({ where: { wishlistId_userId: { wishlistId, userId } } });
    this.realtime.emitWishlistUpdated(wishlistId, 'wishlist.member_left', { userId });
    return { success: true };
  }
}
```

(`create`, `getById`, `listForUser`, and `delete` keep their Task 9 bodies unchanged — `delete` doesn't need an emit since every member's socket disconnects from a room whose wishlist no longer exists; the client removes it locally on a 200 response.)

Update `src/wishlists/wishlists.service.spec.ts`'s `buildService()` helper to pass a mocked `realtime`:

```typescript
  function buildService() {
    const prisma = {
      wishlist: { create: jest.fn(), findUnique: jest.fn(), findMany: jest.fn(), update: jest.fn(), delete: jest.fn() },
      wishlistMember: { create: jest.fn(), delete: jest.fn(), findMany: jest.fn() },
    } as any;
    const members = { isMember: jest.fn(), isOwner: jest.fn() } as any;
    const realtime = { emitWishlistUpdated: jest.fn() } as any;
    return { service: new WishlistsService(prisma, members, realtime), prisma, members, realtime };
  }
```

Edit `src/wishlists/wishlists.module.ts` to add `RealtimeModule` to `imports` — but since `RealtimeModule` is `@Global()`, this import is unnecessary; skip it (Nest resolves `RealtimeGateway` via the global module automatically).

- [ ] **Step 6: Run the wishlists tests to verify they still pass**

Run: `npm test -- wishlists.service.spec`
Expected: PASS

- [ ] **Step 7: Wire emits into `WishlistItemsService`**

Edit `src/wishlist-items/wishlist-items.service.ts` similarly — inject `RealtimeGateway` and emit after `create`, `update`, `delete`, `pick`, `setMostDesired`:

```typescript
import { ForbiddenException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { WishlistMembersService } from '../wishlists/wishlist-members.service';
import { RealtimeGateway } from '../realtime/realtime.gateway';
import { CreateItemDto } from './dto/create-item.dto';
import { UpdateItemDto } from './dto/update-item.dto';
import { needsClearingOthers } from './most-desired-rule';

@Injectable()
export class WishlistItemsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly members: WishlistMembersService,
    private readonly realtime: RealtimeGateway,
  ) {}

  private async assertMember(wishlistId: string, userId: string) {
    if (!(await this.members.isMember(wishlistId, userId))) {
      throw new ForbiddenException('Not a member of this wishlist');
    }
  }

  async create(wishlistId: string, userId: string, dto: CreateItemDto) {
    await this.assertMember(wishlistId, userId);
    const item = await this.prisma.wishlistItem.create({
      data: {
        id: dto.id,
        wishlistId,
        name: dto.name,
        description: dto.description ?? '',
        itemLink: dto.itemLink ?? '',
        price: dto.price,
      },
    });
    this.realtime.emitWishlistUpdated(wishlistId, 'item.created', item);
    return item;
  }

  async update(wishlistId: string, itemId: string, userId: string, dto: UpdateItemDto, imageUrl?: string) {
    await this.assertMember(wishlistId, userId);
    const data: Record<string, unknown> = {};
    if (dto.name !== undefined) data.name = dto.name;
    if (dto.description !== undefined) data.description = dto.description;
    if (dto.itemLink !== undefined) data.itemLink = dto.itemLink;
    if (dto.price !== undefined) data.price = dto.price;
    if (imageUrl !== undefined) data.imageUrl = imageUrl;
    const item = await this.prisma.wishlistItem.update({ where: { id: itemId }, data });
    this.realtime.emitWishlistUpdated(wishlistId, 'item.updated', item);
    return item;
  }

  async delete(wishlistId: string, itemId: string, userId: string) {
    await this.assertMember(wishlistId, userId);
    await this.prisma.wishlistItem.delete({ where: { id: itemId } });
    this.realtime.emitWishlistUpdated(wishlistId, 'item.deleted', { itemId });
    return { success: true };
  }

  async pick(wishlistId: string, itemId: string, userId: string) {
    await this.assertMember(wishlistId, userId);
    const item = await this.prisma.wishlistItem.update({
      where: { id: itemId },
      data: { isPicked: true, pickedBy: userId },
    });
    this.realtime.emitWishlistUpdated(wishlistId, 'item.updated', item);
    return item;
  }

  async setMostDesired(wishlistId: string, itemId: string, userId: string, isMostDesired: boolean) {
    await this.assertMember(wishlistId, userId);
    if (needsClearingOthers(isMostDesired)) {
      await this.prisma.wishlistItem.updateMany({
        where: { wishlistId, id: { not: itemId } },
        data: { isMostDesired: false },
      });
    }
    const item = await this.prisma.wishlistItem.update({ where: { id: itemId }, data: { isMostDesired } });
    this.realtime.emitWishlistUpdated(wishlistId, 'wishlist.items_changed', { wishlistId });
    return item;
  }
}
```

Update `src/wishlist-items/wishlist-items.service.spec.ts`'s `buildService()` to pass a mocked `realtime`, mirroring the wishlists test change in Step 5.

- [ ] **Step 8: Run the item tests to verify they still pass**

Run: `npm test -- wishlist-items.service.spec`
Expected: PASS

- [ ] **Step 9: Build and confirm nothing broke**

Run: `npm run build`
Expected: no TypeScript errors.

- [ ] **Step 10: Commit**

```bash
git add src/realtime src/wishlists src/wishlist-items src/app.module.ts
git commit -m "feat: add Socket.io RealtimeGateway and wire mutation events"
```

---

## Task 12: `GiftSuggestionsModule`

**Files:**
- Create: `src/gift-suggestions/dto/gift-suggestions.dto.ts`
- Create: `src/gift-suggestions/gift-suggestions.service.ts`
- Create: `src/gift-suggestions/gift-suggestions.controller.ts`
- Create: `src/gift-suggestions/gift-suggestions.module.ts`
- Test: `src/gift-suggestions/gift-suggestions.service.spec.ts`

**Interfaces:**
- Consumes: `HttpService` (`@nestjs/axios`), `ConfigService` (`GEMINI_API_KEY`).
- Produces: `GiftSuggestionsService.suggest(dto): Promise<{ suggestions: string[] }>`. `POST /gift-suggestions`, guarded by `JwtAuthGuard`.

- [ ] **Step 1: Write the DTO**

Create `src/gift-suggestions/dto/gift-suggestions.dto.ts`:

```typescript
import { IsArray, IsInt, IsOptional, IsString } from 'class-validator';

export class GiftSuggestionsDto {
  @IsArray() @IsString({ each: true }) interests: string[];
  @IsInt() age: number;
  @IsOptional() @IsArray() @IsString({ each: true }) existingItems?: string[];
  @IsOptional() @IsString() country?: string;
}
```

- [ ] **Step 2: Write the failing test**

Create `src/gift-suggestions/gift-suggestions.service.spec.ts`:

```typescript
import { of, throwError } from 'rxjs';
import { GiftSuggestionsService } from './gift-suggestions.service';

describe('GiftSuggestionsService', () => {
  function buildService(postImpl: () => any) {
    const http = { post: jest.fn(postImpl) } as any;
    const config = { get: () => 'test-gemini-key' } as any;
    return { service: new GiftSuggestionsService(http, config), http };
  }

  it('returns parsed suggestions on a successful call', async () => {
    const { service } = buildService(() =>
      of({ data: { candidates: [{ content: { parts: [{ text: '["Book", "Puzzle"]' }] } }] } }),
    );

    const result = await service.suggest({ interests: ['reading'], age: 30 });
    expect(result).toEqual({ suggestions: ['Book', 'Puzzle'] });
  });

  it('retries on a 503 and succeeds on the second attempt', async () => {
    let call = 0;
    const { service, http } = buildService(() => {
      call += 1;
      if (call === 1) {
        return throwError(() => ({ response: { status: 503 } }));
      }
      return of({ data: { candidates: [{ content: { parts: [{ text: '["Candle"]' }] } }] } });
    });

    const result = await service.suggest({ interests: ['home'], age: 40 });
    expect(result).toEqual({ suggestions: ['Candle'] });
    expect(http.post).toHaveBeenCalledTimes(2);
  });

  it('gives up after 3 attempts on repeated 500s', async () => {
    const { service, http } = buildService(() => throwError(() => ({ response: { status: 500 } })));

    await expect(service.suggest({ interests: ['music'], age: 25 })).rejects.toBeDefined();
    expect(http.post).toHaveBeenCalledTimes(3);
  });
});
```

- [ ] **Step 3: Run it to verify it fails**

Run: `npm test -- gift-suggestions.service.spec`
Expected: FAIL — `GiftSuggestionsService` doesn't exist.

- [ ] **Step 4: Implement `GiftSuggestionsService`**

Create `src/gift-suggestions/gift-suggestions.service.ts`:

```typescript
import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { firstValueFrom } from 'rxjs';
import { GiftSuggestionsDto } from './dto/gift-suggestions.dto';

const RETRYABLE_STATUSES = [429, 500, 503];
const MAX_ATTEMPTS = 3;

function buildPrompt(dto: GiftSuggestionsDto): string {
  const parts = [
    `Suggest gift ideas for a ${dto.age}-year-old`,
    `with interests: ${dto.interests.join(', ')}.`,
  ];
  if (dto.existingItems?.length) {
    parts.push(`They already have: ${dto.existingItems.join(', ')}.`);
  }
  if (dto.country) {
    parts.push(`They live in ${dto.country}.`);
  }
  parts.push('Respond with a JSON array of gift name strings only.');
  return parts.join(' ');
}

@Injectable()
export class GiftSuggestionsService {
  constructor(
    private readonly http: HttpService,
    private readonly config: ConfigService,
  ) {}

  async suggest(dto: GiftSuggestionsDto): Promise<{ suggestions: string[] }> {
    const apiKey = this.config.get<string>('GEMINI_API_KEY');
    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;
    const body = { contents: [{ parts: [{ text: buildPrompt(dto) }] }] };

    let lastError: unknown;
    for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
      try {
        const response = await firstValueFrom(this.http.post(url, body));
        const text: string = response.data.candidates[0].content.parts[0].text;
        return { suggestions: JSON.parse(text) };
      } catch (error: any) {
        lastError = error;
        const status = error?.response?.status;
        if (!RETRYABLE_STATUSES.includes(status) || attempt === MAX_ATTEMPTS) {
          break;
        }
        await new Promise((resolve) => setTimeout(resolve, 300 * attempt));
      }
    }
    throw new InternalServerErrorException(`Gift suggestion request failed: ${JSON.stringify(lastError)}`);
  }
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `npm test -- gift-suggestions.service.spec`
Expected: PASS

- [ ] **Step 6: Write the controller and module**

Create `src/gift-suggestions/gift-suggestions.controller.ts`:

```typescript
import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { GiftSuggestionsService } from './gift-suggestions.service';
import { GiftSuggestionsDto } from './dto/gift-suggestions.dto';

@Controller('gift-suggestions')
@UseGuards(JwtAuthGuard)
export class GiftSuggestionsController {
  constructor(private readonly giftSuggestionsService: GiftSuggestionsService) {}

  @Post()
  suggest(@Body() dto: GiftSuggestionsDto) {
    return this.giftSuggestionsService.suggest(dto);
  }
}
```

Create `src/gift-suggestions/gift-suggestions.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { GiftSuggestionsService } from './gift-suggestions.service';
import { GiftSuggestionsController } from './gift-suggestions.controller';

@Module({
  imports: [HttpModule],
  providers: [GiftSuggestionsService],
  controllers: [GiftSuggestionsController],
})
export class GiftSuggestionsModule {}
```

Edit `src/app.module.ts` to add `GiftSuggestionsModule` to `imports`.

- [ ] **Step 7: Build and confirm nothing broke**

Run: `npm run build`
Expected: no TypeScript errors.

- [ ] **Step 8: Commit**

```bash
git add src/gift-suggestions src/app.module.ts
git commit -m "feat: add GiftSuggestionsModule calling Gemini directly"
```

---

## Task 13: Global pipes/CORS, Dockerfile, and Railway deploy

**Files:**
- Modify: `src/main.ts`
- Create: `Dockerfile`
- Create: `.dockerignore`

**Interfaces:**
- Produces: a deployed HTTPS URL for the server (recorded for the iOS client migration plan).

- [ ] **Step 1: Wire global validation, CORS, and the port**

Edit `src/main.ts`:

```typescript
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors();
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
```

- [ ] **Step 2: Run the full test suite to confirm everything still passes**

Run: `npm test && npm run test:e2e`
Expected: PASS (all unit tests from Tasks 4–12, plus the health e2e test from Task 2).

- [ ] **Step 3: Write the Dockerfile**

Create `Dockerfile`:

```dockerfile
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npx prisma generate
RUN npm run build

FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --omit=dev
COPY --from=build /app/dist ./dist
COPY --from=build /app/prisma ./prisma
COPY --from=build /app/node_modules/.prisma ./node_modules/.prisma
EXPOSE 3000
CMD ["node", "dist/main.js"]
```

Create `.dockerignore`:

```
node_modules
dist
.env
.git
```

- [ ] **Step 4: Verify the Docker image builds locally**

```bash
docker build -t wishie-server .
```

Expected: image builds successfully with no errors.

- [ ] **Step 5: Commit**

```bash
git add src/main.ts Dockerfile .dockerignore
git commit -m "chore: add global validation/CORS and Dockerfile for Railway deploy"
```

- [ ] **Step 6: Deploy to Railway (manual, human-only — not delegated to a subagent)**

```bash
npm install -g @railway/cli
railway login
railway init
```

In the Railway dashboard for the new project: Variables tab → add `DATABASE_URL`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_JWT_SECRET`, `GEMINI_API_KEY` (the same values from Task 1 and the real Gemini key). Then:

```bash
railway up
```

Expected: Railway builds the Dockerfile and deploys. Note the generated public domain (Settings → Networking → "Generate Domain" if not already public).

- [ ] **Step 7: Smoke-test the deployed server**

```bash
curl https://<your-railway-domain>/health
```

Expected: `{"status":"ok"}`. Record this URL — it's the base URL the iOS client migration plan will point at.
