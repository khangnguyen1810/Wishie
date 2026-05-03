//
//  SupabaseManager.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 17/12/25.
//

import Foundation
import Supabase
final class SupabaseManager {
    static let shared = SupabaseManager()
    let client: SupabaseClient
    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://tgllzmczxgqmyxzuxquv.supabase.co")!,
            supabaseKey: "sb_publishable_c1RQq8HSJciCHPEGtbKcMg_J6bfFAVV"
        )
    }
}
