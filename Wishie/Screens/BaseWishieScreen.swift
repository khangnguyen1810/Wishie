//
//  BaseWishieScreen.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 13/12/25.
//

import SwiftUI

struct BaseWishieScreen<
    Background: View,
    TopBar: View,
    Content: View
>: View {

    let background: Background
    let topBar: TopBar
    let content: Content
    let contentPadding: CGFloat

    init(
        @ViewBuilder background: () -> Background = { Color.lightYellow1 },
        @ViewBuilder topBar: () -> TopBar,
        @ViewBuilder content: () -> Content,
        contentPadding: CGFloat = 10
    ) {
        self.background = background()
        self.topBar = topBar()
        self.content = content()
        self.contentPadding = contentPadding
    }

    var body: some View {
        ZStack(alignment: .top) {
            background.ignoresSafeArea()
            VStack {
                topBar
                    .padding(.horizontal, 10)
                content
                    .padding(.horizontal, contentPadding)
                    .ignoresSafeArea()
            }
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
