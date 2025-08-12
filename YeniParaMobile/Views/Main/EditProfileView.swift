import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @ObservedObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var fullName: String = ""
    @State private var phoneNumber: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var profileImage: UIImage?
    
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showDeletePhotoAlert = false
    @State private var showImagePicker = false
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Bar
                navigationBar
                
                // Content
                ScrollView {
                    VStack(spacing: 32) {
                        profilePhotoSection
                        userInfoForm
                        Spacer(minLength: 100)
                    }
                }
            }
            
            if isSaving {
                loadingOverlay
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                isLoading = true
                await authVM.getUserProfile()
                loadUserData()
                isLoading = false
            }
        }
        .onChange(of: selectedPhoto) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    selectedPhotoData = data
                    profileImage = UIImage(data: data)
                }
            }
        }
        .alert("Profil Güncelleme", isPresented: $showAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert("Fotoğrafı Sil", isPresented: $showDeletePhotoAlert) {
            Button("Sil", role: .destructive) {
                deleteProfilePhoto()
            }
            Button("İptal", role: .cancel) { }
        } message: {
            Text("Profil fotoğrafınızı silmek istediğinizden emin misiniz?")
        }
    }
    
    // MARK: - View Components
    
    private var navigationBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                    Text("İptal")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(AppColors.textPrimary)
            }
            
            Spacer()
            
            Text("Profili Düzenle")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Button(action: saveProfile) {
                Text("Kaydet")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primary)
            }
            .disabled(isSaving)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AppColors.background)
    }
    
    private var profilePhotoSection: some View {
        VStack(spacing: 16) {
            // Photo
            Button(action: { showImagePicker = true }) {
                profileImageView
            }
            .buttonStyle(.plain)
            
            // Photo Actions
            HStack(spacing: 20) {
                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Text("Fotoğraf Seç")
                        .font(.subheadline)
                        .foregroundColor(AppColors.primary)
                }
                
                if authVM.userProfile?.user.profilePhotoPath != nil || profileImage != nil {
                    Button(action: {
                        showDeletePhotoAlert = true
                    }) {
                        Text("Fotoğrafı Sil")
                            .font(.subheadline)
                            .foregroundColor(AppColors.error)
                    }
                }
            }
        }
        .padding(.top, 20)
    }
    
    @ViewBuilder
    private var profileImageView: some View {
        Group {
            if let profileImage = profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
            } else {
                ProfileImageView(
                    photoPath: authVM.userProfile?.user.profilePhotoPath,
                    size: 120,
                    fallbackIcon: nil,
                    fallbackText: getInitials()
                )
            }
        }
        .overlay(alignment: .bottomTrailing) {
            cameraButton
        }
    }
    
    private var cameraButton: some View {
        Circle()
            .fill(AppColors.primary)
            .frame(width: 36, height: 36)
            .overlay(
                Image(systemName: "camera.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            )
    }
    
    private var userInfoForm: some View {
        VStack(spacing: 20) {
            // Full Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Ad Soyad")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                TextField("Ad Soyad", text: $fullName)
                    .textFieldStyle(CustomTextFieldStyle())
            }
            
            // Phone Number
            VStack(alignment: .leading, spacing: 8) {
                Text("Telefon Numarası")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                TextField("Telefon Numarası", text: $phoneNumber)
                    .textFieldStyle(CustomTextFieldStyle())
                    .keyboardType(.phonePad)
            }
            
            // Email (Read-only)
            VStack(alignment: .leading, spacing: 8) {
                Text("E-posta")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                readOnlyField(text: authVM.userProfile?.user.email ?? "")
            }
            
            // Username (Read-only)
            VStack(alignment: .leading, spacing: 8) {
                Text("Kullanıcı Adı")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                readOnlyField(text: "@\(authVM.username)")
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func readOnlyField(text: String) -> some View {
        HStack {
            Text(text)
                .foregroundColor(AppColors.textTertiary)
            Spacer()
            Image(systemName: "lock.fill")
                .font(.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .padding()
        .background(AppColors.cardBackground.opacity(0.5))
        .cornerRadius(12)
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                    .scaleEffect(1.5)
                
                Text("Güncelleniyor...")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textPrimary)
            }
            .padding(24)
            .background(AppColors.cardBackground)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Functions
    
    private func getInitials() -> String {
        if authVM.username.isEmpty {
            return "U"
        } else {
            let username = authVM.username
            if username.count >= 2 {
                return String(username.prefix(2)).uppercased()
            } else {
                return username.uppercased()
            }
        }
    }
    
    private func loadUserData() {
        if let user = authVM.userProfile?.user {
            fullName = user.fullName
            phoneNumber = user.phoneNumber
        }
    }
    
    private func saveProfile() {
        isSaving = true
        
        Task {
            do {
                // Upload photo if selected
                if let photoData = selectedPhotoData {
                    _ = try await APIService.shared.uploadProfilePhoto(imageData: photoData)
                }
                
                // Update profile info
                _ = try await APIService.shared.updateUserProfile(
                    fullName: fullName,
                    phoneNumber: phoneNumber
                )
                
                // Reload user profile
                await authVM.getUserProfile()
                
                await MainActor.run {
                    isSaving = false
                    alertMessage = "Profil başarıyla güncellendi"
                    showAlert = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    alertMessage = "Güncelleme başarısız: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    private func deleteProfilePhoto() {
        isSaving = true
        
        Task {
            do {
                _ = try await APIService.shared.deleteProfilePhoto()
                
                // Reload user profile
                await authVM.getUserProfile()
                
                await MainActor.run {
                    isSaving = false
                    profileImage = nil
                    selectedPhotoData = nil
                    alertMessage = "Fotoğraf başarıyla silindi"
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    alertMessage = "Silme başarısız: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}

// MARK: - Custom TextField Style

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(AppColors.cardBackground)
            .cornerRadius(12)
            .foregroundColor(AppColors.textPrimary)
    }
}

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            EditProfileView(authVM: AuthViewModel())
        }
        .preferredColorScheme(.dark)
    }
}