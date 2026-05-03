//
//  ScanQRScreen.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 26/1/26.
//

import SwiftUI
struct ScanQRScreen: View {
    @StateObject var viewModel = ScanQRScreenViewModel()
    @Environment(\.dismiss) private var dismiss
    @State var animate: Bool = false
    @Binding var path: NavigationPath
    var body: some View {
        ZStack (alignment: .topLeading) {
            QRScannerView { value in
                viewModel.handleResult(value)
            }
            .onChange(of: viewModel.result) {_, payload in
                path.append(
                    Route.wishListInfoScreen(
                        wishlistId: payload.wishListId,
                    )
                )
            }
            .ignoresSafeArea()
            .overlay {
                ScannerAreaView(animate: $animate)
            }
            Circle()
                .fill(.lightYellow)
                .frame(width: 50, height: 50)
                .overlay(content: {
                    Image("back_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20)
                })
                .onTapGesture {
                    dismiss()
                }
                .padding(10)
        }
        .navigationBarBackButtonHidden()
        .showDialogIfNeeded($viewModel.showError, title: viewModel.errorTitle, message: viewModel.errorMessage)
    }
}

struct ScannerAreaView: View {
    @Binding var animate: Bool
    var rotationDegrees: [Double] = [0, 90, 180, 270]
    @State var timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Rectangle()
                .blendMode(.destinationOut)
                .clipShape(.rect(cornerRadius: 20))
            
            ForEach(0..<4) { item in
                EdgeRectangleView(animate: $animate)
                    .rotationEffect(Angle(degrees: rotationDegrees[item]))
            }
            .padding(20)
        }
        .onReceive(timer, perform: { _ in
            animate.toggle()
        })
        .frame(width: animate ? 320 : 300, height: animate ? 320 : 300)
        .animation(.easeInOut(duration: 0.9), value: animate)
    }
}

struct EdgeRectangleView: View {
    @Binding var animate: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .trim(from: animate ? 0.35 : 0.34, to: animate ? 0.4 : 0.41)
            .stroke(
                Color(.lightYellow),
                style: StrokeStyle(lineWidth: 10, lineCap: .round)
            )
    }
}
