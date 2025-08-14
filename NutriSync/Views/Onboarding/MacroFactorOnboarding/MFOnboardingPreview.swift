//
//  MFOnboardingPreview.swift
//  NutriSync
//
//  Preview container for all MacroFactor screens
//

import SwiftUI

struct MFOnboardingPreview: View {
    @State private var selectedScreen = 0
    
    let screens = [
        ("Body Fat", AnyView(MFBodyFatLevelView())),
        ("Weight", AnyView(MFWeightView())),
        ("Exercise", AnyView(MFExerciseFrequencyView())),
        ("Activity", AnyView(MFActivityLevelView())),
        ("Expenditure", AnyView(MFExpenditureView())),
        ("Not to Worry", AnyView(MFNotToWorryView())),
        ("Health Disclaimer", AnyView(MFHealthDisclaimerView()))
    ]
    
    var body: some View {
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
                                    Color.black : 
                                    Color(UIColor.systemGray6)
                                )
                                .foregroundColor(
                                    selectedScreen == index ? 
                                    .white : 
                                    .black
                                )
                                .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 8)
            .background(Color.white)
            
            // Screen content
            TabView(selection: $selectedScreen) {
                ForEach(0..<screens.count, id: \.self) { index in
                    screens[index].1
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
}

struct MFOnboardingPreview_Previews: PreviewProvider {
    static var previews: some View {
        MFOnboardingPreview()
    }
}