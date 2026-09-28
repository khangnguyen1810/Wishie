//
//  UserProfileCache.swift
//  Wishie
//

import Foundation

/// Persists the signed-in user's profile so the app can open Home at launch without waiting for
/// `/profiles/me`. Tokens stay in the Keychain via `SessionStore`; the profile isn't secret, so
/// it lives in UserDefaults.
protocol UserProfileCaching {
    func load() -> UserModel?
    func save(_ user: UserModel)
    func clear()
}

final class UserProfileCache: UserProfileCaching {
    private let defaults: UserDefaults
    private let key = "wishie.auth.cachedProfile"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> UserModel? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(UserModel.self, from: data)
    }

    func save(_ user: UserModel) {
        var user = user
        user.password = ""
        guard let data = try? JSONEncoder().encode(user) else { return }
        defaults.set(data, forKey: key)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}
