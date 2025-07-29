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
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
        .environment(\.isPreview, true)
}
