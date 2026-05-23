import SwiftUI

struct EditProfileView: View {
    let userModel: UserModel
    @StateObject private var viewModel = EditProfileViewModel()
    @State private var showDatePicker: Bool = false
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
                Text("Edit Profile")
                    .font(.wishies(.bold, 20))
                    .foregroundStyle(.black)
            }
        } content: {
            ScrollView {
                VStack(spacing: 24) {
                    ImagePickerBox(height: 100, selectedImage: $viewModel.selectedAvatar) {
                        if let avatar = viewModel.selectedAvatar {
                            Image(uiImage: avatar)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else if let url = viewModel.existingAvatarUrl, !url.isEmpty {
                            AsyncImage(url: URL(string: url)) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipped()
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(.lightYellow)
                                        .frame(width: 100, height: 100)
                                }
                            }
                            .frame(width: 100, height: 100)
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
                    .padding(.top, 20)

                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .font(.wishies(.regular, 15))
                            .foregroundStyle(.wishiePink)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }

                    VStack(spacing: 24) {
                        HStack {
                            VStack(spacing: 8) {
                                Text("First Name")
                                    .font(.wishies(.bold, 17))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                TextField("First name", text: $viewModel.firstName)
                                    .font(.wishies(.regular, 17))
                                    .textInputAutocapitalization(.never)
                                    .padding(.horizontal, 15)
                                    .frame(height: 56)
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(.lightYellow)
                                    )
                            }
                            
                            VStack {
                                Text("Last Name")
                                    .font(.wishies(.bold, 17))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                TextField("Last name", text: $viewModel.lastName)
                                    .font(.wishies(.regular, 17))
                                    .padding(.horizontal, 15)
                                    .textInputAutocapitalization(.never)
                                    .frame(height: 56)
                                    .background {
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(.lightYellow)
                                        
                                    }
                            }
                        }
                        VStack {
                            Text("Phone")
                                .font(.wishies(.bold, 17))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            TextField("Phone", text: $viewModel.phone)
                                .font(.wishies(.regular, 17))
                                .padding(.horizontal, 15)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.phonePad)
                                .frame(height: 56)
                                .background {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(.lightYellow)
                                        
                                }
                        }

                        VStack {
                            Text("Email")
                                .font(.wishies(.bold, 17))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(userModel.email.isEmpty ? "-" : userModel.email)
                                .font(.wishies(.regular, 17))
                                .padding(.horizontal, 15)
                                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                                .background {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(.lightGrey.opacity(0.4))
                                }
                        }

                        VStack {
                            Text("Date of Birth")
                                .font(.wishies(.bold, 17))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            DateInputView(isCreating: $showDatePicker , date: $viewModel.dateOfBirth)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 10)
            }

            WishieButton(
                title: "Save",
                enabled: !viewModel.isLoading,
                filColor: .wishiePink,
                titleColor: .black
            ) {
                Task {
                    await viewModel.saveProfile()
                }
            }
            .padding(.horizontal,16)
            .padding(.bottom, 20)
        }
        .showFullScreenDialog($viewModel.isLoading)
        .onAppear {
            viewModel.populate(from: userModel)
        }
        .onChange(of: viewModel.isSaveSuccess) { _, success in
            if success {
                dismiss()
            }
        }
    }
}
