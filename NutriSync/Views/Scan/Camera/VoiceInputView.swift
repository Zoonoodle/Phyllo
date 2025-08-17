//
//  VoiceInputView.swift
//  NutriSync
//
//  Created on 7/29/25.
//

import SwiftUI

struct VoiceInputView: View {
    // Captured image from camera
    let capturedImage: UIImage?
    
    // Completion handler
    var onComplete: ((String) -> Void)?
    
    var body: some View {
        RealVoiceInputView(
            capturedImage: capturedImage,
            onComplete: onComplete
        )
    }
}

#Preview {
    VoiceInputView(capturedImage: nil) { transcript in
        print("Transcript: \(transcript)")
    }
    .preferredColorScheme(.dark)
}