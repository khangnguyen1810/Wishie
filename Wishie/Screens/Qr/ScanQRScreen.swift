//
//  ScanQRScreen.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 26/1/26.
//

import SwiftUI
import PhotosUI

struct ScanQRScreen: View {
    @StateObject var viewModel = ScanQRScreenViewModel()
    @Environment(\.dismiss) private var dismiss
    @State var animate: Bool = false
    @State private var selectedImage: UIImage?
    @Binding var path: NavigationPath
    var body: some View {
        ZStack (alignment: .topLeading) {
            QRScannerView(onResult: { value in
                Task {
                   await viewModel.handleResult(value)
                }
            }, restartScanning: $viewModel.shouldRestartScanning)
            .onChange(of: viewModel.preview) { _, preview in
                guard let preview else { return }
                path.append(Route.wishListInfoScreen(preview: preview))
                // `preview` is consumed by the push above; clearing it lets a later scan of the
                // same code produce a fresh change notification.
                viewModel.didNavigateToPreview()
            }
            .onChange(of: selectedImage) { _, newImage in
                guard let image = newImage else { return }
                viewModel.detectQRCode(from: image)
            }
            .ignoresSafeArea()
            .overlay {
                ScannerAreaView(animate: $animate)
            }
            .overlay {
                if viewModel.isScanning {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(1.5)
                }
            }

            VStack {
                HStack {
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
                    
                    Spacer()
                }
                
                Spacer()
                
                ImagePickerBox(height: 60, selectedImage: $selectedImage) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 24))
                            .foregroundColor(.black)
                        
                        Text("Choose from Library")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.lightYellow)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .padding(10)
        }
        .navigationBarBackButtonHidden()
        .showDialogIfNeeded($viewModel.showError, title: viewModel.errorTitle, message: viewModel.errorMessage)
        // Observing the flag rather than passing `onOk:` — `DialogView` also dismisses on a
        // tap outside, which never calls the confirm handler and would leave the camera frozen.
        .onChange(of: viewModel.showError) { _, isShowing in
            guard !isShowing else { return }
            viewModel.didDismissError()
        }
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
