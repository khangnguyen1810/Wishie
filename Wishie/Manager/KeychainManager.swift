//
//  KeychainManager.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 14/10/25.
//


import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    private init() {}
    
    func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        // Xoá bản cũ (nếu có)
        let query = [kSecClass: kSecClassGenericPassword,
                     kSecAttrAccount: key] as CFDictionary
        SecItemDelete(query)

        // Lưu bản mới
        let attributes = [kSecClass: kSecClassGenericPassword,
                          kSecAttrAccount: key,
                          kSecValueData: data] as CFDictionary
        let status = SecItemAdd(attributes, nil)
        if status != errSecSuccess {
            print("❌ Save error: \(status)")
        }
    }

    func load(key: String) -> String? {
        let query = [kSecClass: kSecClassGenericPassword,
                     kSecAttrAccount: key,
                     kSecReturnData: true,
                     kSecMatchLimit: kSecMatchLimitOne] as CFDictionary

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query, &dataTypeRef)
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        } else {
            return nil
        }
    }

    func delete(key: String) {
        let query = [kSecClass: kSecClassGenericPassword,
                     kSecAttrAccount: key] as CFDictionary
        SecItemDelete(query)
    }
}