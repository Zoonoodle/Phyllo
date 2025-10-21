import SwiftUI
import FirebaseAuth

struct AccountSettingsView: View {
    @EnvironmentObject var firebaseConfig: FirebaseConfig
    @State private var showAccountCreation = false
    @State private var showDeleteConfirmation = false
    @State private var showSignOutConfirmation = false
    @State private var isDeleting = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        List {
            Section("Account Status") {
                HStack {
                    Text("Status")
                    Spacer()
                    Text(firebaseConfig.isAnonymous ? "Guest" : "Registered")
                        .foregroundColor(.secondary)
                }
                
                if !firebaseConfig.isAnonymous,
                   let email = firebaseConfig.currentUser?.email {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(email)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                if let uid = firebaseConfig.currentUser?.uid {
                    HStack {
                        Text("User ID")
                        Spacer()
                        Text(String(uid.prefix(8)) + "...")
                            .foregroundColor(.secondary)
                            .font(.caption)
                            .monospaced()
                    }
                }
            }
            
            if firebaseConfig.isAnonymous {
                Section {
                    Button(action: { showAccountCreation = true }) {
                        Label("Create Account", systemImage: "person.badge.plus")
                            .foregroundColor(.green)
                    }
                } footer: {
                    Text("Secure your data and enable sync across devices")
                }
            } else {
                Section("Account Management") {
                    Button(action: { showSignOutConfirmation = true }) {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.primary)
                    }
                }
            }
            
            Section {
                Button(action: { showDeleteConfirmation = true }) {
                    Label("Delete Account & Data", systemImage: "trash")
                        .foregroundColor(.red)
                }
            } footer: {
                Text("This will permanently delete all your data including profile, meal logs, and settings.")
            }
            
            Section("Data & Privacy") {
                Link(destination: URL(string: "https://nutrisync.app/privacy")!) {
                    HStack {
                        Label("Privacy Policy", systemImage: "lock.shield")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Link(destination: URL(string: "https://nutrisync.app/terms")!) {
                    HStack {
                        Label("Terms of Service", systemImage: "doc.text")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAccountCreation) {
            AccountCreationView()
                .environmentObject(firebaseConfig)
        }
        .alert("Delete Account?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await deleteAccount()
                }
            }
        } message: {
            Text("This will permanently delete all your data. This action cannot be undone.")
        }
        .alert("Sign Out?", isPresented: $showSignOutConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                Task {
                    await signOut()
                }
            }
        } message: {
            Text("You'll need to sign in again to access your data.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .overlay {
            if isDeleting {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                ProgressView("Deleting account...")
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
            }
        }
    }
    
    @MainActor
    private func deleteAccount() async {
        isDeleting = true

        do {
            // Delete user data from Firestore first
            if let userId = Auth.auth().currentUser?.uid {
                try await FirebaseDataProvider.shared.deleteAllUserData(userId: userId)
            }

            // Then delete the auth account
            try await Auth.auth().currentUser?.delete()

            // CRITICAL: Clear Firestore offline cache to prevent old data from appearing
            // when a new anonymous user is created. Without this, cached profile data
            // would make the app think the new user has completed onboarding.
            try await FirebaseDataProvider.shared.clearLocalCache()

            // Clear ALL UserDefaults to ensure complete reset
            clearAllUserDefaults()

            // The auth state listener will handle navigation back to onboarding

        } catch {
            errorMessage = "Failed to delete account: \(error.localizedDescription)"
            showError = true
        }

        isDeleting = false
    }
    
    private func clearAllUserDefaults() {
        // Clear all known keys
        let keysToRemove = [
            "skippedAccountCreation",
            "hasCompletedOnboarding",
            "notificationPreferences",
            "hasShownVoiceInputTips",
            "lastMorningNudgeDate",
            "hasSeenGetStarted",
            "onboardingResetFlag",
            "hasSeenNotificationOnboarding",
            "lastNotificationPromptDate",
            "lastBackgroundTimestamp"
        ]
        
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        // Also clear any date-specific keys for missed meals
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        
        // Remove any keys that match our patterns
        for key in dictionary.keys {
            if key.starts(with: "hasShownMissedMeals_") || 
               key.starts(with: "nudgeShown_") {
                defaults.removeObject(forKey: key)
            }
        }
        
        // Force synchronize to persist changes immediately
        UserDefaults.standard.synchronize()
    }
    
    @MainActor
    private func signOut() async {
        do {
            try Auth.auth().signOut()
            
            // Clear all user-specific local storage
            clearAllUserDefaults()
            
            // The auth state listener will handle navigation
            
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
            showError = true
        }
    }
}

struct AccountSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AccountSettingsView()
                .environmentObject(FirebaseConfig.shared)
        }
    }
}