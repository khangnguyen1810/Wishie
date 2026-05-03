//
//  CreateWishlistPage2.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 15/12/25.
//

import SwiftUI

struct CreateWishlistPage2: View {
    @EnvironmentObject var createWishlistViewModel: CreateWishlistViewModel
    var body: some View {
        Text("Wishlist gift items...")
            .font(.wishies(.regular, 17))
            .frame(maxWidth: .infinity, alignment: .leading)
        GeometryReader { geo in
            List {
                ForEach($createWishlistViewModel.items) { $item in
                    WishlistItemCard(item: $item, height: geo.size.height * 0.3)
                        .environmentObject(createWishlistViewModel)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.lightYellow1)
                }
                .onDelete { indexSet in
                    createWishlistViewModel.items.remove(atOffsets: indexSet)
                }
                Text("+ add new item")
                    .font(.wishies(.regular, 14))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.lightYellow1)
                    .onTapGesture {
                        createWishlistViewModel.items.append(WishlistItem())
                    }
                    .padding(.bottom,100)
                
            }
            .listStyle(.plain)
            .scrollIndicators(.hidden)
        }
    }
}

struct WishlistItemCard: View {
    @Binding var item: WishlistItem
    @FocusState var isInputActive: Bool
    @State private var maxWidth: CGFloat = .infinity
    var height: CGFloat = 100
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                TextField("Item name", text: $item.name)
                    .font(.wishies(.bold, 17))
                    .textFieldStyle(.plain)
                TextField("About this item...", text: $item.description, axis: .vertical)
                    .font(.wishies(.italic, 14))
                    .frame(height: 60, alignment: .topLeading)
                    .lineLimit(2...4)
                    .focused($isInputActive)
                TextField("Paste product link", text: $item.itemLink)
                    .font(.wishies(.regular, 15))
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.plain)

            }
            .frame(maxWidth: maxWidth * 0.6, alignment: .leading)
            ImagePickerBox(
                height: height*0.8,
                selectedImage: $item.localImage) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.wishiePink)
                        .frame(height: height * 0.8)
                        .overlay {
                            VStack {
                                if let selectedImage = item.localImage {
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .scaledToFill()
                                        .clipped()
                                } else {
                                    Image("upload")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)

                                    Text("Add image")
                                        .font(.wishies(.regular, 10))
                                        .foregroundStyle(.black)
                                }
                            }
                        }
                }
            
        }
        .padding(10)
        .frame(maxWidth: maxWidth)
        .frame(height: height)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(
                    colors: [
                        .wishiePink.opacity(0.5),
                        .lightYellow1.opacity(0.5)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing)
                )
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                VStack {
                    Spacer()
                    Button("Done") {
                        isInputActive = false
                    }
                }
            }
        }
    }
}

#Preview {
    CreateWishlistPage2()
        .environmentObject(CreateWishlistViewModel())
}
