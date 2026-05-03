import PhotosUI

struct ImagePickerBox: View {
    let height: CGFloat

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    var body: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images
        ) {
            RoundedRectangle(cornerRadius: 10)
                .fill(.wishiePink)
                .frame(height: height * 0.8)
                .overlay {
                    VStack {
                        if let selectedImage {
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
        .onChange(of: selectedItem) { newItem in
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