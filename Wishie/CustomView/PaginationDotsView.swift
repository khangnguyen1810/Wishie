//
//  PaginationDotsView.swift
//  Wishie
//

import SwiftUI

struct PaginationDotsView: View {
    let count: Int
    let currentIndex: Int
    let activeColor: Color
    let inactiveColor: Color

    init(count: Int,
         currentIndex: Int,
         activeColor: Color = Color("obInk"),
         inactiveColor: Color = Color("obInk").opacity(0.25)) {
        self.count = count
        self.currentIndex = currentIndex
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == currentIndex ? activeColor : inactiveColor)
                    .frame(width: index == currentIndex ? 20 : 8, height: 8)
                    .animation(.easeOut(duration: 0.25), value: currentIndex)
            }
        }
    }
}

#Preview {
    PaginationDotsView(count: 3, currentIndex: 1)
}
