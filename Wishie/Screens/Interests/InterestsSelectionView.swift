import SwiftUI

struct InterestsSelectionView: View {
    @EnvironmentObject var rootNavigationCoordinator: RootNavigationCoordinator
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: InterestsViewModel

    init() {
        _viewModel = StateObject(wrappedValue: InterestsViewModel())
    }

    var body: some View {
        BaseWishieScreen {
            TopAppBar {
                EmptyView()
            } center: {
                Text("Your Interests")
                    .font(.wishies(.bold, 20))
            } trailing: {
                EmptyView()
            }
        } content: {
            VStack(spacing: 0) {
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(viewModel.categories) { category in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(category.title)
                                    .font(.wishies(.bold, 16))

                                LazyVGrid(
                                    columns: [GridItem(.adaptive(minimum: 110), spacing: 10)],
                                    spacing: 10
                                ) {
                                    ForEach(category.items) { item in
                                        HobbyChipView(
                                            item: item,
                                            isSelected: viewModel.isSelected(item),
                                            onTap: { viewModel.toggle(item: item) }
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 16)
                }

                WishieButton(title: "Save & Continue", enabled: !viewModel.isLoading) {
                    Task { await viewModel.saveInterests() }
                }

                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .font(.wishies(.regular, 14))
                        .foregroundStyle(.red)
                        .padding(.top, 8)
                }
            }
        }
        .onAppear {
            viewModel.populate(existingInterests: authViewModel.userInfo.interests)
        }
        .onChange(of: viewModel.isSaveSuccess) { _, success in
            if success {
                rootNavigationCoordinator.completeInterestsSetup()
            }
        }
    }
}
