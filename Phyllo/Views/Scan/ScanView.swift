//
//  ScanView.swift
//  Phyllo
//
//  Created on 7/29/25.
//

import SwiftUI

struct ScanView: View {
    @Binding var showDeveloperDashboard: Bool
    
    var body: some View {
        ScanTabView(showDeveloperDashboard: $showDeveloperDashboard)
    }
}

#Preview {
    ScanView(showDeveloperDashboard: .constant(false))
}