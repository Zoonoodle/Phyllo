//
//  LoginView.swift
//  NutriSync
//
//  Login screen for existing users
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @EnvironmentObject private var firebaseConfig: FirebaseConfig
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.nutriSyncBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Logo/Title
                    VStack(spacing: 8) {
                        Image(systemName: "leaf.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.nutriSyncAccent)
                        
                        Text("Welcome Back")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Log in to your NutriSync account")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 40)
                    
                    // Form fields
                    VStack(spacing: 16) {
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(NutriSyncTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .textContentType(.emailAddress)
                        }
                        
                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(NutriSyncTextFieldStyle())
                                .textContentType(.password)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Login button
                    Button {
                        login()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .nutriSyncBackground))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Log In")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .foregroundColor(.nutriSyncBackground)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .cornerRadius(28)
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    .padding(.horizontal, 20)
                    
                    // Forgot password link
                    Button {
                        // TODO: Implement password reset
                    } label: {
                        Text("Forgot Password?")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .underline()
                    }
                    .padding(.bottom, 34)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .alert("Login Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func login() {
        guard !email.isEmpty, !password.isEmpty else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                _ = try await Auth.auth().signIn(withEmail: email, password: password)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                isLoading = false
            }
        }
    }
}

// MARK: - Custom TextField Style
struct NutriSyncTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 16))
            .foregroundColor(.white)
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
    }
}

// MARK: - Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(FirebaseConfig.shared)
    }
}