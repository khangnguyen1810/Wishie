//
//  BaseWishieScreen.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 13/12/25.
//

import SwiftUI

struct BaseWishieScreen<
    TopBar: View,
    Content: View
>: View {
    
    let topBar: TopBar
    let content: Content
    
    init(
        @ViewBuilder topBar: () -> TopBar,
        @ViewBuilder content: () -> Content
    ) {
        self.topBar = topBar()
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lightYellow1.ignoresSafeArea()
            VStack {
                topBar
                content
                    .ignoresSafeArea()
            }
            .padding(.horizontal, 15)
        }
        .navigationBarBackButtonHidden()
    }
}
struct TopAppBar<
    Leading: View,
    Center: View,
    Trailing: View
>: View {
    
    let leading: Leading
    let center: Center
    let trailing: Trailing
    
    init(
        @ViewBuilder leading: () -> Leading = { EmptyView()},
        @ViewBuilder center: () -> Center = { EmptyView()},
        @ViewBuilder trailing: () -> Trailing = { EmptyView()}
    ) {
        self.leading = leading()
        self.center = center()
        self.trailing = trailing()
    }
    
    var body: some View {
        ZStack {
            HStack {
                leading
                Spacer()
                trailing
            }
            center
                .frame(maxWidth: .infinity/2)
        }
    }
}

