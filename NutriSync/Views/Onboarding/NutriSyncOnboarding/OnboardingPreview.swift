//
//  OnboardingPreview.swift
//  NutriSync
//
//  Preview container for NutriSync onboarding screens
//

import SwiftUI

struct OnboardingPreview: View {
    @State private var selectedScreen = 0
    
    let screens = [
        // Section Intros & Full Flow (at the beginning for easy access)
        ("Full Onboarding", AnyView(NutriSyncOnboardingCoordinator())),
        ("Section Nav", AnyView(SectionIntroView(
            section: NutriSyncOnboardingSection.basics,
            completedSections: [],
            onContinue: {},
            onBack: {}
        )))
    ]
    
    var body: some View {
        ZStack {
            // Background color that extends to all edges
            Color.nutriSyncBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Screen selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<screens.count, id: \.self) { index in
                            Button {
                                withAnimation {
                                    selectedScreen = index
                                }
                            } label: {
                                Text(screens[index].0)
                                    .font(.caption)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedScreen == index ? 
                                        Color.white : 
                                        Color.white.opacity(0.1)
                                    )
                                    .foregroundColor(
                                        selectedScreen == index ? 
                                        Color.nutriSyncBackground : 
                                        .white
                                    )
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 8)
                .background(Color.nutriSyncBackground)
                
                // Screen content
                TabView(selection: $selectedScreen) {
                    ForEach(0..<screens.count, id: \.self) { index in
                        screens[index].1
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .background(Color.nutriSyncBackground)
            }
        }
    }
}

struct OnboardingPreview_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingPreview()
    }
}
