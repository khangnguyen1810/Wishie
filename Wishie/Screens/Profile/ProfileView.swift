import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel: ProfileViewModel = ProfileViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
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
            }
        } content: {
            ScrollView {
                VStack(spacing: 24) {
                    Circle()
                        .fill(.lightYellow)
                        .frame(width: 100, height: 100)
                        .overlay {
                            Image("user")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50)
                        }
                        .padding(.top, 20)

                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .font(.wishies(.regular, 15))
                            .foregroundStyle(.wishiePink)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }

                    profileInfoRow(label: "Full Name", value: viewModel.userInfo.getFullName())
                    profileInfoRow(label: "Date of Birth", value: viewModel.userInfo.dateOfBirth.toShortDateString())
                    profileInfoRow(label: "Email", value: viewModel.userInfo.email)
                    profileInfoRow(label: "Phone", value: viewModel.userInfo.phone)
                }
                .padding(.vertical, 10)
            }

            WishieButton(
                title: "Log out",
                enabled: true,
                filColor: .wishiePink,
                titleColor: .white
            ) {
                authViewModel.logOut()
            }
            .padding(.bottom, 20)
        }
        .showFullScreenDialog($viewModel.isLoading)
        .task {
            await viewModel.fetchUserInfo()
        }
    }

    @ViewBuilder
    private func profileInfoRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.wishies(.regular, 16))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(value.isEmpty ? "-" : value)
                .font(.wishies(.bold, 17))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 15)
                .background {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.lightYellow)
                        .frame(height: 56)
                }
        }
    }
}
