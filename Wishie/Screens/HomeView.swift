//
//  HomeView.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 14/10/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    var body: some View {
        VStack {
            Text("Hello, User!")
            Button {
                authViewModel.logOut()
            } label: {
                Text("Log out")
            }

        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
}
