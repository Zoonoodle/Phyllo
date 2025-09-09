//
//  AuthErrorView.swift
//  NutriSync
//
//  Authentication error state view
//

import SwiftUI

struct AuthErrorView: View {
    let error: Error
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            VStack(spacing: 12) {
                Text("Authentication Error")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundColor(.nutriSyncTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if let authError = error as? AuthError,
                   let recovery = authError.recoverySuggestion {
                    Text(recovery)
                        .font(.caption)
                        .foregroundColor(.nutriSyncTextTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            Button(action: retry) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.phylloAccent)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.phylloBackground)
    }
}

#Preview {
    AuthErrorView(error: AuthError.networkUnavailable) {
        print("Retry tapped")
    }
    .preferredColorScheme(.dark)
}