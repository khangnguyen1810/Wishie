# Testing Phase Checklist

## Purpose

Document the project's testing strategies, frameworks, standards, and conventions to guide unit test implementation and ensure tests follow established practices.

## Test Architecture

{{Define the overall testing strategy and pyramid.
* **Testing Pyramid:** Ratio of Unit : Integration : E2E tests (e.g., 70:20:10)
* **Test Framework:** Primary testing frameworks used (e.g., Jest, pytest, JUnit, Cypress)
* **Test Runner:** How tests are executed (e.g., parallel execution, test sharding)
* **Test Organization:** How tests are structured relative to source code (e.g., `__tests__` folders, `.spec.ts` suffix, separate `/tests` directory)}}

## Unit Testing Standards

{{Define standards for unit tests.
* **Isolation Strategy:** How dependencies are mocked/stubbed (e.g., Jest mocks, Mockito, test doubles)
* **Naming Convention:** Test naming pattern (e.g., `should_returnX_when_Y`, `describe/it` blocks)
* **AAA Pattern:** Enforce Arrange-Act-Assert structure
* **What to Test:** Pure functions, business logic, edge cases, error conditions}}

## Integration Testing Standards (If available or exclude heading)

{{Define how components are tested together.
* **Scope:** What integrations are tested (e.g., API + Database, Service + External API)
* **Test Database Strategy:** (e.g., in-memory DB, Docker containers, test schema)
* **Data Seeding:** How test data is created and cleaned up (fixtures, factories, migrations)
* **External Service Handling:** Use of mocks, stubs, or contract tests for third-party APIs}}

## End-to-End (E2E) Testing (If available or exclude heading)

{{Define browser/system-level testing approach.
* **E2E Framework:** (e.g., Cypress, Playwright, Selenium, Detox for mobile)
* **Critical User Journeys:** List the flows that must always have E2E coverage
* **Environment:** Where E2E tests run (e.g., staging environment, local Docker)
* **Data Management:** How E2E test data is isolated and reset
* **Flakiness Mitigation:** Strategies to reduce test flakiness (retries, waits, stable selectors)}}

## API Testing (If available or exclude heading)

{{Define API-level testing standards.
* **Contract Testing:** Tools used (e.g., Pact, OpenAPI validation)
* **Request/Response Validation:** Schema validation approach
* **Authentication in Tests:** How auth tokens are handled in test suites
* **API Test Tools:** (e.g., Supertest, REST Assured, Postman/Newman)}}

## Performance Testing (If available or exclude heading)

{{Define performance validation approach.
* **Load Testing Tools:** (e.g., k6, JMeter, Gatling, Artillery)
* **Benchmarks:** Target response times, throughput, and error rates
* **Stress Testing:** How system limits are identified
* **Performance Budgets:** FE bundle size limits, API latency SLAs}}

## Security Testing (If available or exclude heading)

{{Define security validation approach.
* **SAST Tools:** Static analysis tools (e.g., SonarQube, Snyk, CodeQL)
* **DAST Tools:** Dynamic scanning tools (e.g., OWASP ZAP, Burp Suite)
* **Dependency Scanning:** How vulnerable dependencies are detected
* **Penetration Testing:** Frequency and scope of manual security reviews}}

## Accessibility Testing (INCLUDE if project has FE)

{{Define a11y testing standards.
* **Standards Compliance:** Target level (e.g., WCAG 2.1 AA)
* **Automated Tools:** (e.g., axe-core, Lighthouse, Pa11y)
* **Manual Testing:** Screen reader testing, keyboard navigation checks}}

## Visual Regression Testing (INCLUDE if project has FE)

{{Define UI consistency testing.
* **Tools:** (e.g., Percy, Chromatic, BackstopJS, Playwright screenshots)
* **Baseline Management:** How reference screenshots are maintained
* **Threshold:** Acceptable pixel difference percentage
* **Component Coverage:** Which components have visual tests}}

## Test Data Management

{{Define how test data is handled.
* **Fixtures:** Location and format of static test data
* **Factories/Builders:** Tools for generating dynamic test data (e.g., Faker, FactoryBot)
* **Database State:** Reset strategy between tests (truncate, transactions, snapshots)
* **Sensitive Data:** How PII/secrets are handled in test environments}}

## Mocking & Stubbing Strategy

{{Define dependency isolation approach.
* **Mock Libraries:** (e.g., Jest mocks, Sinon, WireMock, MSW)
* **What to Mock:** External APIs, time-dependent functions, non-deterministic behavior
* **What NOT to Mock:** Core business logic, database in integration tests
* **Mock Data Location:** Where mock responses/fixtures are stored}}

## Test Environment Strategy

{{Define test environment configuration.
* **Environment Parity:** How test environments mirror production
* **Environment Variables:** How test-specific config is managed
* **Containerization:** Docker/Docker Compose setup for tests
* **CI Environment:** Specs and configuration for CI test runners}}

## Test Maintenance Guidelines

{{Define practices for sustainable tests.
* **DRY Principles:** Shared test utilities, custom matchers, helper functions
* **Test Isolation:** Each test must be independent and idempotent
* **Cleanup Requirements:** teardown/afterEach patterns
* **Skip/Pending Policy:** When it's acceptable to skip tests (with required annotations)
* **Test Review Standards:** What reviewers should check in test code}}
