import Foundation

protocol KeychainStoring {
    func save(key: String, value: String)
    func load(key: String) -> String?
    func delete(key: String)
}

extension KeychainManager: KeychainStoring {}

actor SessionStore {
    static let shared = SessionStore()

    private let keychain: KeychainStoring
    private let accessTokenKey = "wishie.auth.accessToken"
    private let refreshTokenKey = "wishie.auth.refreshToken"
    private let userIdKey = "wishie.auth.userId"
    private let emailKey = "wishie.auth.email"

    private var cachedSession: AuthSession?
    private var refreshTask: Task<AuthSession, Error>?
    /// Bumped by `clear()` so an in-flight refresh that resolves after a logout can detect it ran
    /// during the `await` and avoid resurrecting a session that was explicitly cleared.
    private var generation = 0

    init(keychain: KeychainStoring = KeychainManager.shared) {
        self.keychain = keychain
    }

    func current() -> AuthSession? {
        if let cachedSession {
            return cachedSession
        }
        guard let accessToken = keychain.load(key: accessTokenKey),
              let refreshToken = keychain.load(key: refreshTokenKey),
              let userId = keychain.load(key: userIdKey),
              let email = keychain.load(key: emailKey) else {
            return nil
        }
        let session = AuthSession(accessToken: accessToken, refreshToken: refreshToken, userId: userId, email: email)
        cachedSession = session
        return session
    }

    func save(_ session: AuthSession) {
        keychain.save(key: accessTokenKey, value: session.accessToken)
        keychain.save(key: refreshTokenKey, value: session.refreshToken)
        keychain.save(key: userIdKey, value: session.userId)
        keychain.save(key: emailKey, value: session.email)
        cachedSession = session
    }

    func clear() {
        keychain.delete(key: accessTokenKey)
        keychain.delete(key: refreshTokenKey)
        keychain.delete(key: userIdKey)
        keychain.delete(key: emailKey)
        cachedSession = nil
        refreshTask = nil
        generation += 1
    }

    func refreshedSession(using refresher: @escaping @Sendable (String) async throws -> AuthSession) async throws -> AuthSession {
        let startGeneration = generation
        let task: Task<AuthSession, Error>
        if let refreshTask {
            task = refreshTask
        } else {
            guard let refreshToken = current()?.refreshToken else {
                throw APIError.sessionExpired
            }
            let newTask = Task<AuthSession, Error> {
                try await refresher(refreshToken)
            }
            refreshTask = newTask
            task = newTask
        }
        do {
            let newSession = try await task.value
            refreshTask = nil
            // If clear() ran while we were suspended awaiting the refresh (e.g. the user logged
            // out), do not resurrect the session by saving the now-stale refreshed tokens.
            guard generation == startGeneration else {
                throw APIError.sessionExpired
            }
            save(newSession)
            return newSession
        } catch {
            refreshTask = nil
            if generation == startGeneration {
                clear()
            }
            throw APIError.sessionExpired
        }
    }
}
