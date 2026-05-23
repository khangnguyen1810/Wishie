# Task 4: Create `EditProfileView`

- [ ] 4.1: In `Wishie/Screens/Profile/EditProfileView.swift` CREATE:
  - Define `struct EditProfileView: View` with `let userModel: UserModel` stored property, `@StateObject private var viewModel = EditProfileViewModel()`, and `@Environment(\.dismiss) private var dismiss`.
  - Use `BaseWishieScreen` as root:
    - `topBar`: `TopAppBar` with `leading` slot containing a `Circle().fill(.lightYellow).frame(width: 50, height: 50).overlay { Image("back_icon").resizable().scaledToFit().frame(width: 20) }.onTapGesture { dismiss() }` and `center` slot containing `Text("Edit Profile").font(.wishies(.bold, 20)).foregroundStyle(.black)`.
    - `content`: a `ScrollView` containing a `VStack(spacing: 24)` followed (outside the ScrollView) by a save button and padding.
  - Inside the `VStack(spacing: 24)` in the `ScrollView`:
    - **Avatar picker**: `ImagePickerBox(height: 100, selectedImage: $viewModel.selectedAvatar)` wrapping an avatar circle of 100×100. Display priority: (1) if `viewModel.selectedAvatar != nil`, show `Image(uiImage: viewModel.selectedAvatar!).resizable().scaledToFill().frame(width: 100, height: 100).clipShape(Circle())`; (2) else if `viewModel.existingAvatarUrl` is non-nil and non-empty, show `AsyncImage(url: URL(string: viewModel.existingAvatarUrl!))` with `.scaledToFill().frame(width: 100, height: 100).clipShape(Circle())` on success and a `Circle().fill(.lightYellow).frame(width: 100, height: 100)` placeholder; (3) else show `Circle().fill(.lightYellow).frame(width: 100, height: 100).overlay { Image("user").resizable().scaledToFit().frame(width: 50) }`.
    - **Error message**: `if !viewModel.errorMessage.isEmpty { Text(viewModel.errorMessage).font(.wishies(.regular, 15)).foregroundStyle(.wishiePink).multilineTextAlignment(.center).padding(.horizontal, 16) }`.
    - **Form fields** using the label-above-field pattern from `SignUpView`:
      - First name: `Text("First Name").font(.wishies(.bold, 17)).frame(maxWidth: .infinity, alignment: .leading)` + `TextField("First name", text: $viewModel.firstName).font(.wishies(.regular, 17)).padding(.horizontal, 15).textInputAutocapitalization(.never).background { RoundedRectangle(cornerRadius: 15).fill(.lightYellow).frame(height: 56) }`.
      - Last name: same structure with `"Last Name"` / `"Last name"` label and `$viewModel.lastName`.
      - Phone: same structure with `"Phone"` / `"Phone"` label, `$viewModel.phone`, and `.keyboardType(.phonePad)`.
      - Email (read-only): `Text("Email").font(.wishies(.bold, 17)).frame(maxWidth: .infinity, alignment: .leading)` + `Text(userModel.email.isEmpty ? "-" : userModel.email).font(.wishies(.regular, 17)).padding(.horizontal, 15).frame(maxWidth: .infinity, minHeight: 56, alignment: .leading).background { RoundedRectangle(cornerRadius: 15).fill(.lightGrey.opacity(0.4)) }`.
      - Date of Birth: `Text("Date of Birth").font(.wishies(.bold, 17)).frame(maxWidth: .infinity, alignment: .leading)` + `DateInputView(isCreating: false, date: $viewModel.dateOfBirth)`.
  - Below the `ScrollView` (still inside `BaseWishieScreen` content), place `WishieButton(title: "Save", enabled: !viewModel.isLoading, filColor: .wishiePink, titleColor: .black) { Task { await viewModel.saveProfile() } }.padding(.bottom, 20)`.
  - Apply `.showFullScreenDialog($viewModel.isLoading)` to the `BaseWishieScreen`.
  - Apply `.onAppear { viewModel.populate(from: userModel) }` to the `BaseWishieScreen`.
  - Apply `.onChange(of: viewModel.isSaveSuccess) { _, success in if success { dismiss() } }` to the `BaseWishieScreen`.

