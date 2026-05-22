import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel: ProfileViewModel = ProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            BaseWishieScreen {
                TopAppBar {
                    Circle()
                        .fill(.lightYellow)
                        .frame(width: 50, height: 50)
                        .overlay {
                            Image("back_icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20)
                        }
                        .onTapGesture {
                            dismiss()
                        }
                } center: {
                    Text("Profile")
                        .font(.wishies(.bold, 20))
                        .foregroundStyle(.black)
                } trailing: {
                    Circle()
                        .fill(.lightYellow)
                        .frame(width: 50, height: 50)
                        .overlay {
                            Image("edit_icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20)
                        }
                        .onTapGesture {
                            path.append(Route.editProfile)
                        }
                }
            } content: {
                ScrollView {
                    VStack(spacing: 24) {
                        avatarView
                            .padding(.top, 20)

                        if !viewModel.errorMessage.isEmpty {
                            Text(viewModel.errorMessage)
                                .font(.wishies(.regular, 15))
                                .foregroundStyle(.wishiePink)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }

                        VStack(spacing: 0) {
                            profileInfoRow(label: "Full Name", value: viewModel.userInfo.getFullName())
                            profileInfoRow(label: "Date of Birth", value: viewModel.userInfo.dateOfBirth.toShortDateString())
                            profileInfoRow(label: "Email", value: viewModel.userInfo.email)
                            profileInfoRow(label: "Phone", value: viewModel.userInfo.phone)
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                }

                WishieButton(
                    title: "Log out",
                    enabled: true,
                    filColor: .wishiePink,
                    titleColor: .black
                ) {
                    authViewModel.logOut()
                }
                .padding(.bottom, 20)
            }
            .showFullScreenDialog($viewModel.isLoading)
            .task {
                await viewModel.fetchUserInfo()
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .editProfile:
                    EditProfileView(userModel: viewModel.userInfo)
                        .onDisappear {
                            Task {
                                await viewModel.fetchUserInfo()
                            }
                        }
                default:
                    EmptyView()
                }
            }
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        if let avatarUrl = viewModel.userInfo.avatarUrl, !avatarUrl.isEmpty {
            AsyncImage(url: URL(string: avatarUrl)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                default:
                    Circle()
                        .fill(.lightYellow)
                        .frame(width: 100, height: 100)
                        .overlay {
                            Image("user")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50)
                        }
                }
            }
        } else {
            Circle()
                .fill(.lightYellow)
                .frame(width: 100, height: 100)
                .overlay {
                    Image("user")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50)
                }
        }
    }

    @ViewBuilder
    private func profileInfoRow(label: String, value: String) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Text(label)
                    .font(.wishies(.regular, 16))
                    .foregroundStyle(.black)
                Spacer()
                Text(value.isEmpty ? "-" : value)
                    .font(.wishies(.bold, 16))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.vertical, 14)
        }
    }
}
