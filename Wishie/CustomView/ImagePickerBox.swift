//
//  ImagePickerBox.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 17/12/25.
//


import PhotosUI
import SwiftUI
struct ImagePickerBox<Content: View>: View {
    let height: CGFloat
    
    @State private var selectedItem: PhotosPickerItem?
    @Binding var selectedImage: UIImage?
    @ViewBuilder let content: () -> Content

    var body: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images
        ) {
            content()
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
        }
    }
}
