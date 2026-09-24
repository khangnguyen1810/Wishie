//
//  HomeAddSheet.swift
//  Wishie
//

import SwiftUI

struct HomeAddSheet: View {
    var type: SheetType
    var onScanQR: () -> Void
    var onCreateNew: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#FEF9EC"), Color(hex: "#FEF3D7")],
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()
            if type == .add {
                VStack(spacing: 16) {
                    Text("What would you like to do?")
                        .font(.wishies(.bold, 16))
                        .foregroundStyle(Color.darkGrey)
                        .padding(.top, 30)
                    HomeAddSheetOption(image: "qr_icon", title: "Scan QR code")
                        .onTapGesture(perform: onScanQR)
                    HomeAddSheetOption(image: "create_new_icon", title: "Create new wishlist")
                        .onTapGesture(perform: onCreateNew)
                }
                .padding()
            }
        }
    }
}

private struct HomeAddSheetOption: View {
    var image: String
    var title: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "#FF9A76"), Color(hex: "#FEF3D7")],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                )
                .frame(maxWidth: .infinity)
                .frame(height: 56)
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#FF9A76"), Color(hex: "#F4667A")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    Image(image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24)
                        .padding(.leading, 8)
                }
                .padding(.leading, 12)
                Text(title)
                    .font(.wishies(.bold, 16))
                    .foregroundStyle(Color.black)
                    .padding(.leading, 10)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.darkGrey)
                    .padding(.trailing, 16)
            }
        }
    }
}
