import SwiftUI

/// Renders product artwork from either representation: LinkPresentation hands
/// back a decoded `UIImage`, the WebView scraper an image URL.
struct WishieProductImage: View {
    let localImage: UIImage?
    let url: String?
    let contentMode: ContentMode
    let placeholderSize: CGFloat

    init(
        localImage: UIImage?,
        url: String?,
        contentMode: ContentMode = .fill,
        placeholderSize: CGFloat = 100
    ) {
        self.localImage = localImage
        self.url = url
        self.contentMode = contentMode
        self.placeholderSize = placeholderSize
    }

    var body: some View {
        if let localImage {
            Image(uiImage: localImage)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else if let url, !url.isEmpty {
            WishieWebImage(
                url: url,
                contentMode: contentMode,
                placeholderSize: placeholderSize
            )
        }
    }
}
