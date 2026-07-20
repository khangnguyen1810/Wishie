import SwiftUI
import DotLottie

struct GiftSuggestionsSheet: View {
    @StateObject private var viewModel: GiftSuggestionViewModel
    private let onAdd: (WishlistItem) -> Void

    @State private var selectedInterestIds: Set<String> = []
    @State private var addedIds: Set<String> = []

    init(existingItemNames: [String], onAdd: @escaping (WishlistItem) -> Void) {
        self.onAdd = onAdd
        _viewModel = StateObject(wrappedValue: GiftSuggestionViewModel(existingItemNames: existingItemNames))
    }

    var body: some View {
        VStack(spacing: 16) {
            Capsule().fill(.gray.opacity(0.3)).frame(width: 40, height: 4).padding(.top, 12)
            Text("Gift ideas for you").font(.wishies(.bold, 20))

            content
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .task { await viewModel.start() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .idle, .loading:
            loadingView
        case .needsInterests:
            interestPicker
        case .results, .empty:
            resultsView
        case .error(let message):
            errorView(message)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            DotLottieAnimation(fileName: "giftloading", config: AnimationConfig(autoplay: true, loop: true)).view()
                .frame(width: 100)
            Text("Finding gifts that match your interests…")
                .font(.wishies(.regular, 14))
                .foregroundStyle(.gray)
        }
        .frame(maxHeight: .infinity)
    }

    private var resultsView: some View {
        VStack(spacing: 12) {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(viewModel.suggestions) { suggestion in
                        GiftSuggestionCard(suggestion: suggestion) {
                            onAdd(suggestion.toWishlistItem())
                            addedIds.insert(suggestion.id)
                        }
                        .opacity(addedIds.contains(suggestion.id) ? 0.5 : 1)
                        .disabled(addedIds.contains(suggestion.id))
                    }
                }
                .padding(.vertical, 4)
            }
            if viewModel.phase == .empty {
                Text("We couldn't find enough matches. Try again?")
                    .font(.wishies(.regular, 13))
                    .foregroundStyle(.gray)
                WishieButton(title: "Try again", enabled: true) { Task { await viewModel.generate() } }
            }
        }
    }

    private var interestPicker: some View {
        VStack(spacing: 12) {
            Text("Pick a few interests so we can suggest gifts")
                .font(.wishies(.regular, 14))
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(hobbyCategories) { category in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(category.title).font(.wishies(.bold, 16))
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 10)], spacing: 10) {
                                ForEach(category.items) { item in
                                    HobbyChipView(
                                        item: item,
                                        isSelected: selectedInterestIds.contains(item.id),
                                        onTap: {
                                            if selectedInterestIds.contains(item.id) {
                                                selectedInterestIds.remove(item.id)
                                            } else {
                                                selectedInterestIds.insert(item.id)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
            }
            WishieButton(title: "Continue", enabled: !selectedInterestIds.isEmpty) {
                Task { await viewModel.saveInterestsAndContinue(Array(selectedInterestIds)) }
            }
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text(message)
                .font(.wishies(.regular, 14))
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
            WishieButton(title: "Try again", enabled: true) { Task { await viewModel.generate() } }
        }
        .frame(maxHeight: .infinity)
    }
}
