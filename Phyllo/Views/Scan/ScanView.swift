//
//  ScanView.swift
//  Phyllo
//
//  Created on 7/29/25.
//

import SwiftUI

struct ScanView: View {
    @Binding var showDeveloperDashboard: Bool
    @Binding var selectedTab: Int
    @Binding var scrollToAnalyzingMeal: AnalyzingMeal?
    
    var body: some View {
        ScanTabView(
            showDeveloperDashboard: $showDeveloperDashboard,
            selectedTab: $selectedTab,
            scrollToAnalyzingMeal: $scrollToAnalyzingMeal
        )
    }
}

#Preview {
    ScanView(
        showDeveloperDashboard: .constant(false),
        selectedTab: .constant(2),
        scrollToAnalyzingMeal: .constant(nil)
    )
}