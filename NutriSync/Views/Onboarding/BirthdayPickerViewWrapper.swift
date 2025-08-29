//
//  BirthdayPickerViewWrapper.swift
//  NutriSync
//
//  Created on 8/17/25.
//

import SwiftUI

struct BirthdayPickerViewWrapper: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var internalCurrentPage = 0
    
    var body: some View {
        BirthdayPickerView(currentPage: $internalCurrentPage)
            .onChange(of: internalCurrentPage) { newValue in
                if newValue > 0 {
                    viewModel.nextScreen()
                } else if newValue < 0 {
                    viewModel.previousScreen()
                }
            }
    }
}

struct GenderSelectionViewWrapper: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var internalCurrentPage = 0
    
    var body: some View {
        GenderSelectionView(currentPage: $internalCurrentPage)
            .onChange(of: internalCurrentPage) { newValue in
                if newValue > 0 {
                    // Update viewModel with selected gender
                    if let gender = UserDefaults.standard.string(forKey: "userGender") {
                        viewModel.userData.biologicalSex = gender == "Female" ? .female : .male
                    }
                    viewModel.nextScreen()
                } else if newValue < 0 {
                    viewModel.previousScreen()
                }
            }
    }
}

struct HeightPickerViewWrapper: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var internalCurrentPage = 0
    
    var body: some View {
        HeightPickerView(currentPage: $internalCurrentPage)
            .onChange(of: internalCurrentPage) { newValue in
                if newValue > 0 {
                    // Update viewModel with selected height
                    if let heightCm = UserDefaults.standard.object(forKey: "userHeightCm") as? Int {
                        viewModel.userData.height = Double(heightCm)
                    }
                    viewModel.nextScreen()
                } else if newValue < 0 {
                    viewModel.previousScreen()
                }
            }
    }
}