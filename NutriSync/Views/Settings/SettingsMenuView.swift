import SwiftUI
import FirebaseAuth

struct SettingsMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firebaseConfig: FirebaseConfig
    @EnvironmentObject var dataProvider: FirebaseDataProvider
    @State private var showingDeleteConfirmation = false
    @State private var showingLogoutConfirmation = false
    
    var body: some View {
        NavigationStack {
            List {
                yourNutritionJourneySection
                supportSection
                yourAccountSection
                #if DEBUG
                developerSection
                #endif
            }
            .listStyle(InsetGroupedListStyle())
            .scrollContentBackground(.hidden)
            .background(Color.nutriSyncBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Back")
                                .font(.system(size: 17))
                        }
                        .foregroundColor(.white)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                versionInfoView
            }
        }
        .preferredColorScheme(.dark)
        .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteAccount()
                }
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
        .alert("Log Out", isPresented: $showingLogoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                Task {
                    await logout()
                }
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }
    
    private var yourNutritionJourneySection: some View {
        Section {
            NavigationLink(destination: ScheduleSettingsView()) {
                Label {
                    Text("Schedule Settings")
                        .foregroundColor(.white)
                } icon: {
                    Image(systemName: "calendar")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            NavigationLink(destination: NotificationSettingsView()) {
                Label {
                    Text("Notification Settings")
                        .foregroundColor(.white)
                } icon: {
                    Image(systemName: "bell")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        } header: {
            Text("Your nutrition journey")
                .textCase(nil)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .listRowBackground(Color.white.opacity(0.03))
    }
    
    private var supportSection: some View {
        Section {
            Button(action: reportBug) {
                Label {
                    HStack {
                        Text("Report a bug")
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.3))
                    }
                } icon: {
                    Image(systemName: "ladybug")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Button(action: askQuestion) {
                Label {
                    HStack {
                        Text("Ask a question")
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.3))
                    }
                } icon: {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Button(action: submitFeatureRequest) {
                Label {
                    HStack {
                        Text("Submit a feature request")
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.3))
                    }
                } icon: {
                    Image(systemName: "lightbulb")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Link(destination: URL(string: "https://nutrisync.app/privacy")!) {
                Label {
                    HStack {
                        Text("Privacy policy")
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.3))
                    }
                } icon: {
                    Image(systemName: "lock.shield")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        } header: {
            Text("Support")
                .textCase(nil)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .listRowBackground(Color.white.opacity(0.03))
    }
    
    private var yourAccountSection: some View {
        Section {
            NavigationLink(destination: AccountSettingsView()) {
                Label {
                    Text("Account Settings")
                        .foregroundColor(.white)
                } icon: {
                    Image(systemName: "person.circle")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Link(destination: URL(string: "https://nutrisync.app/terms")!) {
                Label {
                    HStack {
                        Text("Terms of Service")
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.3))
                    }
                } icon: {
                    Image(systemName: "doc.text")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Button(action: { showingDeleteConfirmation = true }) {
                Label {
                    Text("Delete account")
                        .foregroundColor(.red.opacity(0.9))
                } icon: {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(0.9))
                }
            }
            
            Button(action: { showingLogoutConfirmation = true }) {
                Label {
                    Text("Log out")
                        .foregroundColor(.white)
                } icon: {
                    Image(systemName: "rectangle.portrait.and.arrow.forward")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        } header: {
            Text("Your account")
                .textCase(nil)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .listRowBackground(Color.white.opacity(0.03))
    }
    
    #if DEBUG
    private var developerSection: some View {
        Section {
            NavigationLink(destination: DeveloperDashboardView()) {
                Label {
                    Text("Developer Dashboard")
                        .foregroundColor(.white)
                } icon: {
                    Image(systemName: "hammer")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        } header: {
            Text("Developer")
                .textCase(nil)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .listRowBackground(Color.white.opacity(0.03))
    }
    #endif
    
    private var versionInfoView: some View {
        VStack(spacing: 4) {
            if let email = firebaseConfig.currentUser?.email {
                Text(email)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            HStack(spacing: 4) {
                Text("NutriSync")
                Text("•")
                Text("version \(appVersion)")
            }
            .font(.system(size: 13))
            .foregroundColor(.white.opacity(0.3))
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color.nutriSyncBackground)
    }
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    private func reportBug() {
        if let url = URL(string: "mailto:support@nutrisync.app?subject=Bug%20Report") {
            UIApplication.shared.open(url)
        }
    }
    
    private func askQuestion() {
        if let url = URL(string: "mailto:support@nutrisync.app?subject=Question") {
            UIApplication.shared.open(url)
        }
    }
    
    private func submitFeatureRequest() {
        if let url = URL(string: "mailto:support@nutrisync.app?subject=Feature%20Request") {
            UIApplication.shared.open(url)
        }
    }
    
    private func deleteAccount() async {
        do {
            try await firebaseConfig.currentUser?.delete()
            dismiss()
        } catch {
            print("Failed to delete account: \(error)")
        }
    }
    
    private func logout() async {
        do {
            try Auth.auth().signOut()
            dismiss()
        } catch {
            print("Failed to log out: \(error)")
        }
    }
}