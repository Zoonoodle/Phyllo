import SwiftUI
import AuthenticationServices
import FirebaseAuth

struct AccountCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firebaseConfig: FirebaseConfig
    @State private var selectedMethod: AccountMethod?
    @State private var email = ""
    @State private var password = ""
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    enum AccountMethod: Identifiable {
        case apple
        case email
        
        var id: String {
            switch self {
            case .apple: return "apple"
            case .email: return "email"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Secure Your Progress")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Create an account to sync across devices and never lose your data")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                // Benefits list
                VStack(alignment: .leading, spacing: 16) {
                    BenefitRow(icon: "icloud", text: "Sync across all your devices")
                    BenefitRow(icon: "shield", text: "Secure data backup")
                    BenefitRow(icon: "arrow.triangle.2.circlepath", text: "Easy account recovery")
                    BenefitRow(icon: "bell", text: "Email notifications (optional)")
                }
                .padding()
                .background(Color.white.opacity(0.03))
                .cornerRadius(16)
                .padding(.horizontal)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    // Apple Sign In
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            handleAppleSignIn(result)
                        }
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .cornerRadius(12)
                    
                    // Email option
                    Button(action: { selectedMethod = .email }) {
                        HStack {
                            Image(systemName: "envelope")
                            Text("Continue with Email")
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(12)
                    }
                    
                    // Skip option
                    Button(action: skipAccountCreation) {
                        Text("Skip for Now")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .background(Color.black)
            .sheet(item: $selectedMethod) { method in
                if method == .email {
                    EmailSignUpView(
                        email: $email,
                        password: $password,
                        onComplete: handleEmailSignUp,
                        onCancel: { selectedMethod = nil }
                    )
                }
            }
            .alert("Account Creation Failed", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isCreating {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    ProgressView("Creating account...")
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                }
            }
        }
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                errorMessage = "Failed to get Apple ID credentials"
                showError = true
                return
            }
            
            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: "",
                fullName: appleIDCredential.fullName
            )
            
            Task {
                await linkAccount(with: credential)
            }
            
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func handleEmailSignUp() {
        guard !email.isEmpty, !password.isEmpty else { 
            errorMessage = "Please enter both email and password"
            showError = true
            return
        }
        
        let credential = EmailAuthProvider.credential(
            withEmail: email,
            password: password
        )
        
        Task {
            await linkAccount(with: credential)
        }
    }
    
    @MainActor
    private func linkAccount(with credential: AuthCredential) async {
        isCreating = true
        
        do {
            guard let user = Auth.auth().currentUser, user.isAnonymous else {
                throw AuthError.notAnonymous
            }
            
            let result = try await user.link(with: credential)
            
            // Update auth state
            firebaseConfig.currentUser = result.user
            firebaseConfig.isAnonymous = false
            firebaseConfig.authState = .authenticated
            
            // Show success
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            dismiss()
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isCreating = false
    }
    
    private func skipAccountCreation() {
        // Track skip event
        UserDefaults.standard.set(true, forKey: "skippedAccountCreation")
        dismiss()
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}

// MARK: - Email Sign Up View
struct EmailSignUpView: View {
    @Binding var email: String
    @Binding var password: String
    let onComplete: () -> Void
    let onCancel: () -> Void
    
    @State private var confirmPassword = ""
    @State private var showPasswordMismatch = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account Information")) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                }
                
                Section {
                    Text("Your password should be at least 6 characters long")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        if password == confirmPassword {
                            onComplete()
                        } else {
                            showPasswordMismatch = true
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty || confirmPassword.isEmpty)
                }
            }
            .alert("Passwords Don't Match", isPresented: $showPasswordMismatch) {
                Button("OK") {}
            } message: {
                Text("Please make sure your passwords match")
            }
        }
    }
}