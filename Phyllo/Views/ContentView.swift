///exitafter  
//  ContentView.swift
//  Phyllo
//
//  Created by Brennen Price on 7/27/25.
//


import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        MainTabView()
            .withNudges()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
            .environment(\.isPreview, true)
            .onAppear {
                // Initialize singletons for preview
                _ = MockDataManager.shared
                _ = NudgeManager.shared
                _ = TimeProvider.shared
                _ = ClarificationManager.shared
            }
    }
}



