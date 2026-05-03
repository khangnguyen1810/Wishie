//
//  LoginOrSignUpScreen.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 7/10/25.
//

import SwiftUI

struct LoginOrSignUpScreen: View {
    let listImage = ["bgimg1","bgimg2", "bgimg3", "bgimg4"]
    let listImage2 = ["bgimg5","bgimg6", "bgimg7", "bgimg8"]
    @State private var path = NavigationPath()
    @EnvironmentObject var authViewModel: AuthViewModel
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Image("bgimg7")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .opacity(0.8)
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [.darkGrey.opacity(0.5), .black.opacity(0.9)]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .ignoresSafeArea()
                VStack (spacing: -290) {
                    BackgroundAnimationView(listImage: listImage)
                        .rotationEffect(.degrees(-15))
                        .scaleEffect(1.3)
                        .offset(x: 40)
                        .ignoresSafeArea()
                    BackgroundAnimationView(listImage: listImage2)
                        .rotationEffect(.degrees(-15))
                        .scaleEffect(1.3)
                        .offset(x: 40)
                        .ignoresSafeArea()
                }
                .offset(y:30)
                VStack {
                    Spacer()
                    Image("pen")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    Text("Wishie")
                        .font(.wishies(.bold, 30))
                        .foregroundStyle(.white)
                    WishieButton(
                        title: "Login",
                        enabled: true,
                        width: UIScreen.main.bounds.width * 0.9
                    ) {
                        path.append("login")
                    }
                    WishieButton(
                        title: "Sign up",
                        enabled: true,
                        filColor: .black,
                        titleColor: .lightYellow,
                        width: UIScreen.main.bounds.width * 0.9
                    ) {
                        path.append("signup")
                    }
                }
                .padding(.bottom,50)
               
            }
            .navigationDestination(for: String.self) { path in
                switch(path) {
                case "login":
                    LoginView()
                        .environmentObject(authViewModel)
                        .navigationBarBackButtonHidden()
                case "signup":
                    SignUpView()
                        .environmentObject(authViewModel)
                        .navigationBarBackButtonHidden()
                default:
                    ContentUnavailableView("Login Screen", systemImage: "person.fill")
                }
            }
        }
    }
}
struct BackgroundAnimationView: View {
    var listImage: [String]
    @State private var xOffset: CGFloat = 0
    @State private var totalWidth: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            let imageWidth = geo.size.width / 4.6
            let spacing: CGFloat = 10
            let repeatedList = Array(repeating: listImage, count: 2).flatMap { $0 } // nhân đôi mảng cho loop mượt
            
            HStack(spacing: spacing) {
                ForEach(repeatedList.indices, id: \.self) { i in
                    imageBackground(name: repeatedList[i], width: imageWidth, height: imageWidth * 1.45)
                }
            }
            .offset(x: xOffset)
            .onAppear {
                totalWidth = (imageWidth + spacing) * CGFloat(listImage.count)
                startInfiniteScroll(width: totalWidth)
            }
        }
        .clipped()
    }
    
    private func startInfiniteScroll(width: CGFloat) {
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: true)) {
            xOffset = -width
        }
    }
    
    @ViewBuilder
    func imageBackground(name: String, width: CGFloat, height: CGFloat) -> some View {
        Image(name)
            .resizable()
            .scaledToFill()
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .clipped()
    }
}
