//
//  ProfileView.swift
//  Z-Tix
//
//  Created by Harnish Patel on 14/10/2025.
//

// Need to add in functionality for uploading profile picture and the profile pic getting saved to core data so that it doeesn't have to keep getting synced from Firebase and so on.

import PhotosUI
import SwiftData
import SwiftUI

// MARK: - Profile View

/// User profile and account management screen
/// Features:
/// - Profile picture upload with crop editor
/// - User information display (name, email)
/// - App version information
/// - Sign out functionality
/// - Account deletion with cascade
/// - Attributions/credits page
struct ProfileView: View {

    // MARK: - Environment Objects

    /// Authentication view model for user data and account operations
    @EnvironmentObject var authViewModel: AuthViewModel

    /// Profile picture view model for image operations
    @StateObject private var profilePictureVM = ProfilePictureViewModel()

    /// SwiftData context for profile picture persistence
    @Environment(\.modelContext) private var modelContext

    // MARK: - State Properties

    /// Controls account deletion confirmation dialog
    @State private var showDeleteConfirmation = false

    /// Controls profile picture removal confirmation dialog
    @State private var showDeletePhotoConfirmation = false

    // MARK: - Body

    var body: some View {
        // Only show profile if user is authenticated
        if let organiserUser = authViewModel.currentUser {
            NavigationStack {
                List {

                    // MARK: User Info Section
                    Section {
                        HStack {

                            // MARK: Profile Picture / Initials
                            /// Shows profile picture if available, otherwise initials
                            ZStack(alignment: .bottomTrailing) {

                                if let profileImage = profilePictureVM
                                    .profileImage
                                {
                                    // Display uploaded profile picture
                                    Image(uiImage: profileImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 72, height: 72)
                                        .clipShape(Circle())
                                } else {
                                    // Display initials as fallback
                                    Text(organiserUser.initials)
                                        .font(.title)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(width: 72, height: 72)
                                        .background(Color(.systemGray3))
                                        .clipShape(Circle())
                                }

                                // MARK: Camera Button Overlay
                                /// PhotosPicker for selecting new profile picture
                                PhotosPicker(
                                    selection: $profilePictureVM
                                        .photoPickerItem,
                                    matching: .images  // Only allow image selection
                                ) {
                                    Image(systemName: "camera.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.cyan)
                                        .background(
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 20, height: 20)
                                        )
                                }
                                .onChange(of: profilePictureVM.photoPickerItem)
                                { _, _ in
                                    // Trigger photo loading when selection changes
                                    profilePictureVM.handlePhotoSelection()
                                }
                            }

                            // MARK: User Name and Email
                            VStack {
                                Text(
                                    organiserUser.firstName + " "
                                        + organiserUser.lastName
                                )
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.top, 4)

                                Text(organiserUser.email)
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                        }

                        // MARK: Remove Picture Button
                        /// Only shown when profile picture exists
                        if profilePictureVM.profileImage != nil {
                            Button {
                                showDeletePhotoConfirmation = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                    Text("Remove Profile Picture")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }

                    // MARK: General Section
                    Section("General") {
                        HStack {
                            SettingsRowView(
                                imageName: "gear",
                                title: "Version",
                                tintColour: Color(.label)
                            )
                            Spacer()

                            Text("1.0.0")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }

                    // MARK: Account Section
                    Section("Account") {

                        // MARK: Sign Out Button
                        Button {
                            authViewModel.signOut()
                            Logger.debug(
                                "User sign out button clicked",
                                code: 0
                            )
                        } label: {
                            SettingsRowView(
                                imageName: "arrow.left.circle.fill",
                                title: "Sign Out",
                                tintColour: .red
                            )
                        }

                        // MARK: Delete Account Button
                        Button {
                            showDeleteConfirmation = true
                            Logger.debug("User delete button clicked", code: 0)
                        } label: {
                            SettingsRowView(
                                imageName: "xmark.circle.fill",
                                title: "Delete Account",
                                tintColour: .red
                            )
                        }
                    }

                    // MARK: About Section
                    Section("About Us") {
                        NavigationLink {
                            AttributionsView()
                        } label: {
                            SettingsRowView(
                                imageName: "doc.text.fill",
                                title: "Attributions",
                                tintColour: .cyan
                            )
                        }
                    }
                }
                .navigationTitle("Your Profile")
                .navigationBarBackButtonHidden(true)

                // MARK: Authentication Alerts
                /// Displays errors from auth operations (sign out, delete account)
                .alert(item: $authViewModel.alertItem) { alertItem in
                    Alert(
                        title: Text(alertItem.title),
                        message: Text(alertItem.message),
                        dismissButton: alertItem.dismissButton
                    )
                }

                // MARK: Delete Account Confirmation
                /// Warns user about permanent data loss
                .confirmationDialog(
                    "Delete Account?",
                    isPresented: $showDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Delete Acount", role: .destructive) {
                        Task {
                            await authViewModel.deleteAccount()
                        }
                    }
                    Button("Cancel", role: .cancel) {
                        showDeleteConfirmation = false
                    }
                } message: {
                    Text(
                        "Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted."
                    )
                }

                // MARK: Delete Photo Confirmation
                /// Confirms profile picture removal
                .confirmationDialog(
                    "Remove Profile Picture?",
                    isPresented: $showDeletePhotoConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Remove", role: .destructive) {
                        profilePictureVM.deleteProfilePicture(
                            userId: organiserUser.id
                        )
                    }
                    Button("Cancel", role: .cancel) {
                        showDeletePhotoConfirmation = false
                    }
                } message: {
                    Text("Your profile picture will be removed.")
                }

                // MARK: Image Cropper Modal
                /// Full-screen modal for cropping selected photo
                .fullScreenCover(isPresented: $profilePictureVM.showCropper) {
                    if let selectedImage = profilePictureVM.selectedImage {
                        ImageCropperView(
                            image: selectedImage,
                            onCrop: { croppedImage in
                                // Save cropped image
                                profilePictureVM.saveProfilePicture(
                                    image: croppedImage,
                                    userId: organiserUser.id
                                )
                                // Clean up state
                                profilePictureVM.showCropper = false
                                profilePictureVM.selectedImage = nil
                                profilePictureVM.photoPickerItem = nil
                            },
                            onCancel: {
                                // Discard selection
                                profilePictureVM.showCropper = false
                                profilePictureVM.selectedImage = nil
                                profilePictureVM.photoPickerItem = nil
                            }
                        )
                    }
                }

                // MARK: View Lifecycle
                /// Initialise profile picture on view appear
                .onAppear {
                    // Inject SwiftData context
                    profilePictureVM.setModelContext(modelContext)

                    // Load existing profile picture if present
                    profilePictureVM.loadProfilePicture(
                        userId: organiserUser.id
                    )
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
}
