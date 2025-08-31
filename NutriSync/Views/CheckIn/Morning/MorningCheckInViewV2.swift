//
//  MorningCheckInViewV2.swift
//  NutriSync
//
//  Wrapper view for V2 morning check-in flow using the coordinator pattern
//

import SwiftUI

struct MorningCheckInViewV2: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        MorningCheckInCoordinator()
    }
}

#Preview {
    MorningCheckInViewV2()
        .preferredColorScheme(.dark)
}