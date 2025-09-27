//
//  DailySyncCoordinator.swift
//  NutriSync
//
//  Simplified daily sync flow with onboarding-style navigation
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
                // Progress dots at top (matching onboarding)
                if viewModel.currentScreen != .greeting {
                    DailySyncProgressDots(
                        totalSteps: viewModel.screenFlow.count - 2, // Exclude greeting and complete
                        currentStep: viewModel.currentIndex
                    )
                    .padding(.top, 60)
                    .padding(.bottom, 40)
                }
                
                // Dynamic screen content
                Group {
                    switch viewModel.currentScreen {
                    case .greeting:
                        GreetingView(viewModel: viewModel)
                    case .alreadyEaten:
                        AlreadyEatenViewStyled(viewModel: viewModel)
                    case .schedule:
                        ScheduleViewStyled(viewModel: viewModel)
                    case .energy:
                        EnergyViewStyled(viewModel: viewModel)
                    case .complete:
                        CompleteViewStyled(viewModel: viewModel, dismiss: dismiss)
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
@MainActor
class DailySyncViewModel: ObservableObject {
    @Published var currentScreen: DailySyncScreen = .greeting
    @Published var syncData = DailySync()
    @Published var alreadyEatenMeals: [QuickMeal] = []
    @Published var workStart: Date = Date()
    @Published var workEnd: Date = Date()
    @Published var hasWorkToday = true
    @Published var workoutTime: Date?
    @Published var energyLevel: SimpleEnergyLevel = .good
    
    var screenFlow: [DailySyncScreen] = []
    var currentIndex = 0
    
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
        
        // Save to Firebase and trigger window generation
        await DailySyncManager.shared.saveDailySync(syncData)
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

// MARK: - Greeting View (Onboarding Style)
struct GreetingView: View {
    @ObservedObject var viewModel: DailySyncViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Icon matching context
            Image(systemName: SyncContext.current().icon)
                .font(.system(size: 60, weight: .medium))
                .foregroundColor(.nutriSyncAccent)
                .padding(.bottom, 32)
            
            DailySyncHeader(
                title: SyncContext.current().greeting,
                subtitle: "Let's quickly sync your nutrition plan"
            )
            
            Spacer()
            
            // Single Continue button (no back on first screen)
            DailySyncBottomNav(
                onBack: nil,
                onNext: { viewModel.nextScreen() },
                nextButtonTitle: "Get Started",
                showBack: false
            )
        }
    }
}

// MARK: - Already Eaten View (Styled)
struct AlreadyEatenViewStyled: View {
    @ObservedObject var viewModel: DailySyncViewModel
    @State private var showAddMeal = false
    @State private var mealName = ""
    @State private var mealTime = Date()
    @State private var estimatedCalories = ""
    
    var body: some View {
        VStack(spacing: 0) {
            DailySyncHeader(
                title: "Have you eaten today?",
                subtitle: "I'll adjust your remaining meals accordingly"
            )
            .padding(.top, 40)
            
            Spacer()
            
            // Meal list or empty state
            if viewModel.alreadyEatenMeals.isEmpty {
                VStack(spacing: 24) {
                    Image(systemName: "fork.knife.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("No meals logged yet")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Button(action: { showAddMeal = true }) {
                        Label("Add a meal", systemImage: "plus.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.nutriSyncAccent)
                    }
                }
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.alreadyEatenMeals) { meal in
                            QuickMealRow(meal: meal) {
                                viewModel.alreadyEatenMeals.removeAll { $0.id == meal.id }
                            }
                        }
                        
                        Button(action: { showAddMeal = true }) {
                            Label("Add another meal", systemImage: "plus.circle")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.nutriSyncAccent)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            Spacer()
            
            // Navigation
            DailySyncBottomNav(
                onBack: { viewModel.previousScreen() },
                onNext: { viewModel.nextScreen() }
            )
        }
        .sheet(isPresented: $showAddMeal) {
            EnhancedMealEntry(
                mealName: $mealName,
                mealTime: $mealTime,
                estimatedCalories: $estimatedCalories,
                onSave: {
                    let meal = QuickMeal(
                        name: mealName.isEmpty ? "Unnamed meal" : mealName,
                        time: mealTime,
                        estimatedCalories: Int(estimatedCalories)
                    )
                    viewModel.alreadyEatenMeals.append(meal)
                    // Reset fields for next entry
                    mealName = ""
                    estimatedCalories = ""
                    mealTime = Date()
                }
            )
        }
    }
}

// MARK: - Schedule View (Styled)
struct ScheduleViewStyled: View {
    @ObservedObject var viewModel: DailySyncViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            DailySyncHeader(
                title: "What's your schedule?",
                subtitle: "I'll time your meals perfectly around your day"
            )
            .padding(.top, 40)
            
            Spacer()
            
            VStack(spacing: 20) {
                // Work toggle
                Toggle(isOn: $viewModel.hasWorkToday) {
                    HStack(spacing: 12) {
                        Image(systemName: "briefcase.fill")
                            .foregroundColor(.white.opacity(0.7))
                        Text("Working today")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .tint(.nutriSyncAccent)
                .padding(.horizontal, 24)
                
                // Work hours (if working)
                if viewModel.hasWorkToday {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Work hours")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                        }
                        
                        HStack(spacing: 12) {
                            TimePickerCompact(
                                label: "Start",
                                time: $viewModel.workStart
                            )
                            
                            Image(systemName: "arrow.right")
                                .foregroundColor(.white.opacity(0.3))
                            
                            TimePickerCompact(
                                label: "End",
                                time: $viewModel.workEnd
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // Workout toggle
                VStack(spacing: 16) {
                    Toggle(isOn: Binding(
                        get: { viewModel.workoutTime != nil },
                        set: { hasWorkout in
                            if hasWorkout {
                                viewModel.workoutTime = Date()
                            } else {
                                viewModel.workoutTime = nil
                            }
                        }
                    )) {
                        HStack(spacing: 12) {
                            Image(systemName: "figure.run")
                                .foregroundColor(.white.opacity(0.7))
                            Text("Planning to workout")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .tint(.nutriSyncAccent)
                    
                    if viewModel.workoutTime != nil {
                        TimePickerCompact(
                            label: "Workout time",
                            time: Binding(
                                get: { viewModel.workoutTime ?? Date() },
                                set: { viewModel.workoutTime = $0 }
                            )
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Navigation
            DailySyncBottomNav(
                onBack: { viewModel.previousScreen() },
                onNext: { viewModel.nextScreen() }
            )
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.hasWorkToday)
        .animation(.easeInOut(duration: 0.3), value: viewModel.workoutTime != nil)
    }
}

// MARK: - Energy View (Styled)
struct EnergyViewStyled: View {
    @ObservedObject var viewModel: DailySyncViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            DailySyncHeader(
                title: "How's your energy?",
                subtitle: "This helps optimize your meal timing"
            )
            .padding(.top, 40)
            
            Spacer()
            
            // Energy options using DailySyncOptionButton
            VStack(spacing: 12) {
                ForEach(SimpleEnergyLevel.allCases, id: \.self) { level in
                    DailySyncOptionButton(
                        icon: level.emoji,
                        title: level.rawValue,
                        subtitle: level.nutritionImpact,
                        isSelected: viewModel.energyLevel == level
                    ) {
                        viewModel.energyLevel = level
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Navigation
            DailySyncBottomNav(
                onBack: { viewModel.previousScreen() },
                onNext: { viewModel.nextScreen() },
                canGoNext: true // Always can continue, has default selection
            )
        }
    }
}

// MARK: - Complete View (Styled)
struct CompleteViewStyled: View {
    @ObservedObject var viewModel: DailySyncViewModel
    let dismiss: DismissAction
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Success animation
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.nutriSyncAccent)
                .scaleEffect(1.2)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: true)
                .padding(.bottom, 32)
            
            DailySyncHeader(
                title: "Perfect!",
                subtitle: "I'm optimizing your \(viewModel.syncData.remainingMealsCount) remaining meals"
            )
            
            Spacer()
            
            // Single button to complete (no back on final screen)
            DailySyncBottomNav(
                onBack: nil,
                onNext: {
                    Task {
                        await viewModel.saveSyncData()
                        dismiss()
                    }
                },
                nextButtonTitle: "View Schedule",
                showBack: false
            )
        }
        .onAppear {
            // Trigger haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
}

// MARK: - Helper Components
struct TimePickerCompact: View {
    let label: String
    @Binding var time: Date
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
            
            DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                .datePickerStyle(.compact)
                .labelsHidden()
                .colorScheme(.dark)
                .accentColor(.nutriSyncAccent)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

#Preview {
    DailySyncCoordinator()
        .preferredColorScheme(.dark)
        .environmentObject(FirebaseDataProvider.shared)
}