//
//  StickyHeaderView.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 18/3/26.
//



import SwiftUI

struct StickyHeaderView<Content: View>: View {
    @State private var offsetY: CGFloat = 0
    @State private var measuredHeight: CGFloat = 0
    @Binding var isSharing: Bool
    var headerBgColor: String = ""
    var buttonColor: String = ""
    var titlePage: String
    var iconTitlePage: String?
    var wishlistTitle: String?
    var owner: String?
    var wishlistId: String
    let backAction: () -> Void
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        ZStack {
            GeometryReader { proxy in
                let safeArea = proxy.safeAreaInsets.top
                ScrollView(.vertical, showsIndicators: false) {
                    
                    VStack (spacing: 0) {
                        headerView(
                            safeArea,
                            headerColor: headerBgColor,
                            buttonColor: buttonColor
                        )
                            .zIndex(1)
                            .offset(y: -offsetY)
                        content()
                            .background(Rectangle().fill(.white))
                            .zIndex(0)
                        Spacer()
                    }
                    .offset(coordinateSpace: .named("SCROLL")) { offset in
                     
                        offsetY = min(offset, 0)
                    }
                }
                .coordinateSpace(name: "SCROLL")
                .ignoresSafeArea()
            }
        }
        .ignoresSafeArea()
    }
    @ViewBuilder
    func headerView(_ safeAreaTop: CGFloat, headerColor: String = "#FEF3D7", buttonColor: String = "#F1D790") -> some View {
        let progress = -(offsetY / 80) > 1 ? -1 : (offsetY > 0 ? 0 : (offsetY / 80))
        let headerHeight: CGFloat = 200
        let minVisibleHeight: CGFloat = 130 + safeAreaTop
        VStack {
            ZStack {
                HStack {
                    Circle()
                        .fill(Color(hex: buttonColor))
                        .frame(width: 40, height: 40)
                        .overlay(content: {
                            Image("back_icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 17)
                                .foregroundStyle(.white)
                        })
                        .onTapGesture {
                            backAction()
                        }
                    Spacer()
                    Circle()
                        .fill(Color(hex: buttonColor))
                        .frame(width: 40, height: 40)
                        .overlay(content: {
                            Image("share")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 17)
                                .foregroundStyle(.white)
                        })
                        .onTapGesture {
                            isSharing = true
                        }
                }
                .padding(.horizontal)
                Text(titlePage)
                    .font(.wishies(.bold, 20))
                    .foregroundStyle(.black)
            }
            .padding(.horizontal, -progress * 10)
            .opacity(progress + 1)
            VStack {
                Text(wishlistTitle ?? "Wishlist's name")
                    .font(.wishies(.bold, 25))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .preference(
                                    key: TextHeightKey.self,
                                    value: geo.size.height
                                )
                        }
                    )
                    .onPreferenceChange(TextHeightKey.self) { height in
                        measuredHeight = height
                    }
                Text("by \(owner ?? "owner's name")")
                    .font(.wishies(.light, 15))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 30 )
            .padding(.horizontal,15)
            .offset(y: max(offsetY, -(headerHeight - minVisibleHeight)))
        }
        .frame(height: measuredHeight > 30 ? headerHeight + 30 : headerHeight)
        .padding(.top, safeAreaTop + 20)
        .background {
            InverseRoundedRectangle(radius: 30, )
                .fill(Color(hex: headerColor).lightened(by: 0.45))
                .padding(.bottom, -progress * 65)
        }
    }
}

struct OffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    @ViewBuilder
    func offset(coordinateSpace: CoordinateSpace, completion: @escaping(CGFloat) -> ()) -> some View {
        self
            .overlay {
                GeometryReader { proxy in
                    let minY = proxy.frame(in: .global).minY
                    Color.clear
                        .preference(key: OffsetKey.self, value: minY)
                        .onPreferenceChange(OffsetKey.self) { offset in
                            completion(offset)
                        }
                }
            }
    }
}

struct InverseRoundedRectangle: Shape {
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        
        path.addQuadCurve(to: CGPoint(x: radius, y: rect.height - radius),
                          control: CGPoint(x: 0, y: rect.height - radius))
        
        path.addLine(to: CGPoint(x: rect.width - radius, y: rect.height - radius))
        path.addQuadCurve(to: CGPoint(x: rect.width, y: rect.height),
                          control: CGPoint(x: rect.width, y: rect.height - radius))
        
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: .zero)
        
        return path
    }
}
