import SwiftUI

struct InterestsSelectionView: View {
    @EnvironmentObject var rootNavigationCoordinator: RootNavigationCoordinator
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: InterestsViewModel
    @Environment(\.dismiss) private var dismiss
    private let isOnboarding: Bool

    init(isOnboarding: Bool = true) {
        self.isOnboarding = isOnboarding
        _viewModel = StateObject(wrappedValue: InterestsViewModel())
    }

    var body: some View {
        BaseWishieScreen {
            TopAppBar {
                if !isOnboarding {
                    Circle()
                        .fill(.lightYellow)
                        .frame(width: 40, height: 40)
                        .overlay {
                            Image("back_icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 17)
                        }
                        .onTapGesture {
                            dismiss()
                        }
                } else {
                    EmptyView()
                }
            } center: {
                Text("Your Interests")
                    .font(.wishies(.bold, 20))
            } trailing: {
                EmptyView()
            }
        } content: {
            GeometryReader { proxy in
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

                    WishieButton(title: isOnboarding ? "Save & Continue" : "Save", enabled: !viewModel.isLoading) {
                        Task { await viewModel.saveInterests() }
                    }
                    .padding(.bottom, max(proxy.safeAreaInsets.bottom, 30))

                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .font(.wishies(.regular, 14))
                            .foregroundStyle(.red)
                            .padding(.top, 8)
                    }
                }
            }
        }
        .interactiveDismissDisabled(isOnboarding)
        .onAppear {
            viewModel.populate(existingInterests: authViewModel.userInfo.interests)
        }
        .onChange(of: viewModel.isSaveSuccess) { _, success in
            if success {
                if isOnboarding {
                    rootNavigationCoordinator.completeInterestsSetup()
                } else {
                    authViewModel.userInfo.interests = Array(viewModel.selectedInterestIds)
                    dismiss()
                }
            }
        }
    }
}
