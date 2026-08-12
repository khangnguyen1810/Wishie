//
//  Constants.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 11/2/26.
//

enum WishieConstants {
    static let userIdKey: String = "userid"
    static let firebaseUserPath: String = "users"
    static let firebaseWishlistPath: String = "wishlists"
    static let hasSeenHomeTutorial: String = "hasSeenHomeTutorial"
    /// Google OAuth **web** client ID — must match `GOOGLE_CLIENT_ID` configured on the wishie-server backend.
    /// Find it in Google Cloud Console → APIs & Services → Credentials → OAuth 2.0 Client IDs (Web application type).
    /// REQUIRED: replace this placeholder with the real value before manually testing Google Sign-In (Task 7).
    static let googleWebClientID: String = "946256552157-u6haj99t0cocjt92nh149duf6bd6o86e.apps.googleusercontent.com"
}
