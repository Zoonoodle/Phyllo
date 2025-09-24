//
//  DailySyncCoordinator.swift
//  NutriSync
//
//  Simplified daily sync flow replacing morning check-in
//

import SwiftUI

struct DailySyncCoordinator: View {
    @StateObject private var viewModel = DailySyncViewModel()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataProvider: FirebaseDataProvider
    
    let isMandatory: Bool
    
    init(isMandatory: Bool = false) {
        self.isMandatory = isMandatory
    }
    
    var body: some View {
        ZStack {
            Color.nutriSyncBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with close button (if not mandatory)
                if !isMandatory {
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 10)
                    }
                }
                
                // Dynamic screen based on step
                Group {
                    switch viewModel.currentScreen {
                    case .greeting:
                        GreetingView(viewModel: viewModel)
                    case .alreadyEaten:
                        AlreadyEatenView(viewModel: viewModel)
                    case .schedule:
                        ScheduleView(viewModel: viewModel)
                    case .energy:
                        EnergyView(viewModel: viewModel)
                    case .complete:
                        CompleteView(viewModel: viewModel, dismiss: dismiss)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentScreen)
        .onAppear {
            viewModel.setupFlow()
        }
    }
}

// MARK: - View Model
class DailySyncViewModel: ObservableObject {
    @Published var currentScreen: DailySyncScreen = .greeting
    @Published var syncData = DailySync()
    @Published var alreadyEatenMeals: [QuickMeal] = []
    @Published var workStart: Date = Date()
    @Published var workEnd: Date = Date()
    @Published var hasWorkToday = true
    @Published var workoutTime: Date?
    @Published var energyLevel: SimpleEnergyLevel = .good
    
    private var screenFlow: [DailySyncScreen] = []
    private var currentIndex = 0
    
    // Setup dynamic flow based on context
    func setupFlow() {
        let context = SyncContext.current()
        var screens: [DailySyncScreen] = [.greeting]
        
        // Only ask about eaten meals after 8am
        if context.shouldAskAboutEatenMeals {
            screens.append(.alreadyEaten)
        }
        
        // Always ask about schedule
        screens.append(.schedule)
        
        // Only ask energy if it matters for timing
        if shouldAskEnergy(context) {
            screens.append(.energy)
        }
        
        screens.append(.complete)
        
        self.screenFlow = screens
        self.currentScreen = screens[0]
    }
    
    private func shouldAskEnergy(_ context: SyncContext) -> Bool {
        // Ask about energy if it's midday or later and they haven't eaten much
        switch context {
        case .midday, .afternoon, .evening:
            return alreadyEatenMeals.count < 2
        default:
            return true
        }
    }
    
    func nextScreen() {
        guard currentIndex < screenFlow.count - 1 else { return }
        currentIndex += 1
        currentScreen = screenFlow[currentIndex]
    }
    
    func previousScreen() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        currentScreen = screenFlow[currentIndex]
    }
    
    func saveSyncData() async {
        let workSchedule = hasWorkToday ? TimeRange(start: workStart, end: workEnd) : nil
        
        syncData = DailySync(
            syncContext: SyncContext.current(),
            alreadyConsumed: alreadyEatenMeals,
            workSchedule: workSchedule,
            workoutTime: workoutTime,
            currentEnergy: energyLevel
        )
        
        // Save to Firebase
        // TODO: Implement Firebase save
        DailySyncManager.shared.saveDailySync(syncData)
    }
}

// MARK: - Screen Types
enum DailySyncScreen {
    case greeting
    case alreadyEaten
    case schedule
    case energy
    case complete
}

// MARK: - Greeting View
struct GreetingView: View {
    @ObservedObject var viewModel: DailySyncViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Context-aware greeting
            VStack(spacing: 16) {
                Text(SyncContext.current().greeting)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Let's quickly sync your nutrition plan")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Continue button
            Button(action: { viewModel.nextScreen() }) {
                Text("Get Started")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.nutriSyncAccent)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Energy View
struct EnergyView: View {
    @ObservedObject var viewModel: DailySyncViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(index <= 2 ? Color.nutriSyncAccent : Color.white.opacity(0.2))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 20)
            
            VStack(spacing: 16) {
                Text("How's your energy?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("This helps optimize your meal timing")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Energy options
            VStack(spacing: 12) {
                ForEach(SimpleEnergyLevel.allCases, id: \.self) { level in
                    Button(action: {
                        viewModel.energyLevel = level
                        viewModel.nextScreen()
                    }) {
                        HStack {
                            Text(level.emoji)
                                .font(.system(size: 24))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(level.rawValue)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text(level.nutritionImpact)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            if viewModel.energyLevel == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.nutriSyncAccent)
                                    .font(.system(size: 20))
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(viewModel.energyLevel == level ? 0.1 : 0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(viewModel.energyLevel == level ? Color.nutriSyncAccent : Color.clear, lineWidth: 2)
                                )
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Navigation buttons
            HStack(spacing: 12) {
                Button(action: { viewModel.previousScreen() }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(16)
                }
                
                Button(action: { viewModel.nextScreen() }) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.nutriSyncAccent)
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Complete View
struct CompleteView: View {
    @ObservedObject var viewModel: DailySyncViewModel
    let dismiss: DismissAction
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Success animation
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.nutriSyncAccent)
                .scaleEffect(1.2)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: true)
            
            VStack(spacing: 16) {
                Text("Perfect!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("I'm optimizing your \(viewModel.syncData.remainingMealsCount) remaining meals")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Done button
            Button(action: {
                Task {
                    await viewModel.saveSyncData()
                    dismiss()
                }
            }) {
                Text("View Schedule")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.nutriSyncAccent)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            // Trigger haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
}

#Preview {
    DailySyncCoordinator()
        .preferredColorScheme(.dark)
        .environmentObject(FirebaseDataProvider.shared)
}