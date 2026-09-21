import SwiftUI
import DotLottie
import SDWebImageSwiftUI

struct ProfileView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var editViewModel: EditProfileViewModel = EditProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            BaseWishieScreen {
                TopAppBar {
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
                } center: {
                    Text("Profile")
                        .font(.wishies(.bold, 20))
                        .foregroundStyle(.black)
                } trailing: {
                    Circle()
                        .fill(.lightYellow)
                        .frame(width: 40, height: 40)
                        .overlay {
                            Image("edit_icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 17)
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

                        if !authViewModel.userInfoError.isEmpty {
                            Text(authViewModel.userInfoError)
                                .font(.wishies(.regular, 15))
                                .foregroundStyle(.wishiePink)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }

                        VStack(spacing: 0) {
                            profileInfoRow(label: "Full Name", value: authViewModel.userInfo.getFullName())
                            profileInfoRow(label: "Date of Birth", value: authViewModel.userInfo.dateOfBirth.toShortDateString())
                            profileInfoRow(label: "Email", value: authViewModel.userInfo.email)
                            profileInfoRow(label: "Phone", value: authViewModel.userInfo.phone)
                            profileInfoRow(
                                label: "Interests",
                                value: authViewModel.userInfo.interests.isEmpty ? "-" : "\(authViewModel.userInfo.interests.count) selected"
                            )
                            .onTapGesture {
                                path.append(Route.editInterests)
                            }
                            profileInfoRow(label: "Archived wishlists", value: "")
                                .onTapGesture {
                                    path.append(Route.archivedWishlists)
                                }
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
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .editProfile:
                    EditProfileView(userModel: authViewModel.userInfo, viewModel: editViewModel)
                case .editInterests:
                    InterestsSelectionView(isOnboarding: false)
                case .archivedWishlists:
                    ArchivedWishlistsView()
                default:
                    EmptyView()
                }
            }
            .onChange(of: editViewModel.updatedUser) { _, updated in
                if let updated {
                    authViewModel.userInfo = updated
                }
            }
        }
        .showFullScreenDialog($authViewModel.isShowProgress)
    }

    @ViewBuilder
    private var avatarView: some View {

        if let avatarUrl = authViewModel.userInfo.avatarUrl,
           !avatarUrl.isEmpty {

            WishieWebImage(url: avatarUrl)
                .transition(.fade(duration: 0.25))
                .frame(width: 100, height: 100)
                .clipped()
                .clipShape(Circle())
            .transition(.fade(duration: 0.25))
            .frame(width: 100, height: 100)
            .clipped()
            .clipShape(Circle())

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
