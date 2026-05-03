//
//  DialogView.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 15/10/25.
//

import SwiftUI
import DotLottie
struct DialogView: View {
    @Binding var isShowDialog: Bool
    
    var errorTitle: String?
    var errorMessage: String?
    
    var showCancel: Bool = true
    
    var onConfirm: (() -> Void)?
    var onCancel: (() -> Void)?
    
    var body: some View {
        ZStack {
            if isShowDialog {
                Color.lightGrey.opacity(0.3).ignoresSafeArea()
                    .onTapGesture {
                        isShowDialog = false
                    }
                ZStack {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .padding(.top,30)
                        // Dialog message
                        Text(errorTitle ?? "General Error")
                            .font(.wishies(.bold, 22))
                            .padding(.top,30)
                            .padding(.horizontal,20)
                        Text(errorMessage ?? "This is a general error, please try again later.")
                            .font(.wishies(.regular, 16))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical,30)
                            .padding(.horizontal,20)
                        HStack(spacing: 12) {
                            if showCancel {
                                Button(action: {
                                    onCancel?()
                                    isShowDialog = false
                                }) {
                                    Text("Cancel")
                                        .font(.system(size: 16, weight: .bold, design: .default))
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.red)
                                        .clipShape(RoundedRectangle(cornerRadius: 15))
                                        .padding()
                                }
                            }
                            Button(action: {
                                onConfirm?()
                                isShowDialog = false
                            }) {
                                Text("OK")
                                    .font(.system(size: 16, weight: .bold, design: .default))
                                    .foregroundColor(.black)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.lightYellow)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                    .padding()
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .padding(.horizontal, 40)
            }
        }
    }
}

#Preview {
    FullScreenLoading(isShowDialog: .constant(true))
}

struct FullScreenLoading: View {
    @Binding var isShowDialog: Bool
    var body: some View {
        ZStack {
            if isShowDialog {
                Color.lightGrey.opacity(0.3).ignoresSafeArea()
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.lightYellow)
                    .frame(
                        width: UIScreen.main.bounds.width/4,
                        height:  UIScreen.main.bounds.width/4
                    )
                    .overlay {
                        DotLottieAnimation(fileName: "giftloading", config: AnimationConfig(autoplay: true, loop: true)).view()
                            .frame(width: 80)
                    }
            }
        }
    }
}

extension View {
    func showDialogIfNeeded(
        _ isPresented: Binding<Bool>,
        title: String?, message: String?,
        showCancel: Bool = false,
        onOk: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil) -> some View {
            self.overlay {
                if isPresented.wrappedValue {
                    DialogView(
                        isShowDialog: isPresented,
                        errorTitle: title,
                        errorMessage: message,
                        showCancel: showCancel,
                        onConfirm: onOk,
                        onCancel: onCancel
                    )
                }
            }
        }
    func showFullScreenDialog(_ isPresented: Binding<Bool>) -> some View {
        self.overlay {
            if isPresented.wrappedValue {
                FullScreenLoading(isShowDialog: isPresented)
            }
        }
    }
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
