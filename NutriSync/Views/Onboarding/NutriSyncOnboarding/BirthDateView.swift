//
//  BirthDateView.swift
//  NutriSync
//
//  Birth date selection screen for onboarding
//

import SwiftUI

struct BirthDateView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var selectedDate = Date(timeIntervalSince1970: 788918400) // Jan 1, 1995
    @State private var isInitialized = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("When were you born?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 80)
                
                // Date Picker
                DatePicker("", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .colorScheme(.dark)
                    .scaleEffect(1.2)
                    .padding(.horizontal, 20)
                    .onChange(of: selectedDate) { _ in
                        saveDataToCoordinator()
                    }
                
                Spacer(minLength: 80) // Space for navigation buttons
            }
        }
        .onAppear {
            loadDataFromCoordinator()
        }
    }
    
    private func loadDataFromCoordinator() {
        guard !isInitialized else { return }
        isInitialized = true
        
        // Calculate date from age if it exists
        if coordinator.age > 0 {
            let calendar = Calendar.current
            if let birthDate = calendar.date(byAdding: .year, value: -coordinator.age, to: Date()) {
                selectedDate = birthDate
            }
        }
    }
    
    private func saveDataToCoordinator() {
        // Calculate age from selected date
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: selectedDate, to: Date())
        coordinator.age = ageComponents.year ?? 30
    }
}

struct BirthDateView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.nutriSyncBackground
                .ignoresSafeArea()
            BirthDateView()
        }
    }
}
