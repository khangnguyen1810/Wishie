//
//  CreateWishlistPage2.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 15/12/25.
//

import SwiftUI

struct CreateWishlistPage2: View {
    @EnvironmentObject var createWishlistViewModel: CreateWishlistViewModel
    @State private var showAddItemOptionSheet: Bool = false
    @State private var showPasteLinkSheet: Bool = false
    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Add your gift ideas")
                .font(.wishies(.bold, 18))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Photos and details help friends pick the perfect gift.")
                .font(.wishies(.regular, 14))
                .foregroundStyle(.black.opacity(0.65))
                .frame(maxWidth: .infinity, alignment: .leading)
            List {
                ForEach($createWishlistViewModel.items) { $item in
                    WishlistItemCard(item: $item)
                        .environmentObject(createWishlistViewModel)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.lightYellow1)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                .onDelete { indexSet in
                    createWishlistViewModel.items.remove(atOffsets: indexSet)
                }
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.wishiePink)
                    Text("Add another gift")
                        .font(.wishies(.bold, 15))
                        .foregroundStyle(.wishiePink)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.lightYellow1)
                .onTapGesture {
                    showAddItemOptionSheet = true
                }
                .padding(.bottom, 100)
            }
            .listStyle(.plain)
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: keyboardHeight) }
            .scrollDismissesKeyboard(.interactively)
        }
        .keyboardHeight($keyboardHeight)
        .sheet(isPresented: $showAddItemOptionSheet) {
            AddItemOptionSheet(
                onPasteLink: {
                    showAddItemOptionSheet = false
                    showPasteLinkSheet = true
                },
                onManual: {
                    createWishlistViewModel.items.append(WishlistItem())
                    showAddItemOptionSheet = false
                }
            )
            .presentationDetents([.height(280)])
        }
        .sheet(isPresented: $showPasteLinkSheet) {
            PasteLinkSheet()
                .environmentObject(createWishlistViewModel)
                .presentationDetents([.large])
        }
    }
}

struct WishlistItemCard: View {
    private enum CreateWishlistItemField: Hashable {
        case name, description, itemLink, price
    }

    @Binding var item: WishlistItem
    @FocusState private var focusedField: CreateWishlistItemField?
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Gift idea")
                    .font(.wishies(.bold, 13))
                    .foregroundStyle(.wishiePink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.wishiePink.opacity(0.12))
                    .clipShape(Capsule())
                Spacer()
            }
            ImagePickerBox(height: 180, selectedImage: $item.localImage) {
                ZStack {
                    if let selectedImage = item.localImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, minHeight: 180)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else if let remoteUrl = item.image, !remoteUrl.isEmpty {
                        WishieWebImage(url: remoteUrl)
                            .frame(maxWidth: .infinity, minHeight: 180)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        VStack(spacing: 8) {
                            Image("upload")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 26, height: 26)
                            Text("Add photo")
                                .font(.wishies(.regular, 12))
                                .foregroundStyle(.black)
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 180)
                .background(.wishiePink)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            VStack(alignment: .leading, spacing: 12) {
                TextField("Item name", text: $item.name)
                    .font(.wishies(.bold, 17))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.lightYellow)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .focused($focusedField, equals: .name)
                TextField("About this item...", text: $item.description, axis: .vertical)
                    .font(.wishies(.italic, 14))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(height: 74, alignment: .topLeading)
                    .lineLimit(2...4)
                    .background(.lightYellow)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .focused($focusedField, equals: .description)
                TextField("Paste product link", text: $item.itemLink)
                    .font(.wishies(.regular, 15))
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.lightYellow)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .focused($focusedField, equals: .itemLink)
                TextField(
                    "Price (optional)",
                    text: Binding(
                        get: { item.price ?? "" },
                        set: { item.price = $0.isEmpty ? nil : $0 }
                    )
                )
                .font(.wishies(.regular, 15))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.lightYellow)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .focused($focusedField, equals: .price)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.black.opacity(0.04), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 5)
        .toolbar {
            if focusedField != nil {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
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
