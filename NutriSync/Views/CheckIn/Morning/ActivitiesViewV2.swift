//
//  ActivitiesViewV2.swift
//  NutriSync
//
//  Converted activities view using onboarding template pattern
//

import SwiftUI

// MARK: - PlannedActivityInput
// Moved from deleted EnhancedActivitiesView.swift - still needed by V2
struct PlannedActivityInput: Identifiable {
    let id = UUID()
    var type: ActivityType
    var startTime: String
    var endTime: String
    
    enum ActivityType: String, CaseIterable {
        case workout = "Workout"
        case cardio = "Cardio"
        case weights = "Weight Training"
        case meal = "Meal Event"
        case meeting = "Meeting"
        case social = "Social Event"
        case work = "Work Event"
        case travel = "Travel"
        
        var icon: String {
            switch self {
            case .workout, .cardio, .weights: return "figure.run"
            case .meal: return "fork.knife"
            case .meeting, .work: return "briefcase.fill"
            case .social: return "person.2.fill"
            case .travel: return "car.fill"
            }
        }
    }
}

struct ActivitiesViewV2: View {
    @Bindable var viewModel: MorningCheckInViewModel
    @State private var activityBlocks: [ActivityTimeBlock] = []
    @State private var activities: [PlannedActivityInput] = []
    @State private var showingAddActivity = false
    
    // Initialize blocks from selected activities
    init(viewModel: MorningCheckInViewModel) {
        self.viewModel = viewModel
        // Pre-populate time blocks from selected activities
        let blocks = viewModel.selectedActivities.enumerated().map { index, activity in
            let startHour = 9 + (index * 2) // Start at 9 AM, 2 hours apart
            let startTime = Calendar.current.date(
                bySettingHour: startHour,
                minute: 0,
                second: 0,
                of: Date()
            ) ?? Date()
            
            return ActivityTimeBlock(
                activity: activity,
                startTime: startTime,
                duration: viewModel.activityDurations[activity] ?? activity.defaultDuration
            )
        }
        self._activityBlocks = State(initialValue: blocks)
    }
    
    var body: some View {
        CheckInScreenTemplate(
            title: "Plan your day",
            subtitle: "Add events with times for optimal meal scheduling",
            currentStep: viewModel.currentStep,
            totalSteps: viewModel.totalSteps,
            onBack: viewModel.previousStep,
            onNext: {
                // Save time blocks to view model
                viewModel.plannedActivities = activityBlocks.map { block in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "h:mm a"
                    let startStr = formatter.string(from: block.startTime)
                    let endTime = Calendar.current.date(
                        byAdding: .minute,
                        value: block.duration,
                        to: block.startTime
                    ) ?? block.startTime
                    let endStr = formatter.string(from: endTime)
                    return "\(block.activity.rawValue) \(startStr)-\(endStr)"
                }
                viewModel.nextStep()
            },
            canGoNext: true
        ) {
            ScrollView {
                VStack(spacing: 20) {
                    // Window preference selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Meal windows today")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 12) {
                            WindowPreferenceButtonV2(title: "Auto", isSelected: viewModel.windowPreference == .auto) {
                                viewModel.windowPreference = .auto
                            }
                            
                            WindowPreferenceButtonV2(title: "3-4", isSelected: isRangeSelected(3, 4)) {
                                viewModel.windowPreference = .range(3, 4)
                            }
                            
                            WindowPreferenceButtonV2(title: "4-5", isSelected: isRangeSelected(4, 5)) {
                                viewModel.windowPreference = .range(4, 5)
                            }
                            
                            WindowPreferenceButtonV2(title: "5-6", isSelected: isRangeSelected(5, 6)) {
                                viewModel.windowPreference = .range(5, 6)
                            }
                        }
                    }
                    
                    // Time blocks for selected activities
                    if !viewModel.selectedActivities.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Schedule your activities")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Set start times and durations for each activity")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                            
                            ForEach(activityBlocks.indices, id: \.self) { index in
                                TimeBlockBuilder(
                                    startTime: $activityBlocks[index].startTime,
                                    duration: $activityBlocks[index].duration,
                                    activity: activityBlocks[index].activity
                                )
                            }
                            
                            // Visual timeline showing all blocks
                            if activityBlocks.count > 1 {
                                DayTimeline(blocks: activityBlocks)
                                    .frame(height: 200)
                                    .padding(.top, 8)
                            }
                        }
                    } else if !activities.isEmpty {
                        // Fallback for manual activities
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Planned activities")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            ForEach(activities) { activity in
                                ActivityRowV2(activity: activity) {
                                    activities.removeAll { $0.id == activity.id }
                                }
                            }
                        }
                    }
                    
                    // Add activity button
                    Button {
                        showingAddActivity = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                            Text("Add activity")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.nutriSyncAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.nutriSyncAccent.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.nutriSyncAccent.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    
                    // Dietary restrictions toggle
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $viewModel.hasRestrictions) {
                            Text("Dietary restrictions")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .tint(.nutriSyncAccent)
                        
                        if viewModel.hasRestrictions {
                            RestrictionSelectorV2(restrictions: $viewModel.restrictions)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .sheet(isPresented: $showingAddActivity) {
            AddActivitySheetV2(activities: $activities)
        }
    }
    
    private func isRangeSelected(_ min: Int, _ max: Int) -> Bool {
        if case .range(let rangeMin, let rangeMax) = viewModel.windowPreference {
            return rangeMin == min && rangeMax == max
        }
        return false
    }
}

// MARK: - Supporting Components

struct WindowPreferenceButtonV2: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.nutriSyncAccent : Color.white.opacity(0.1))
                )
        }
    }
}

struct ActivityRowV2: View {
    let activity: PlannedActivityInput
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: activity.type.icon)
                .font(.system(size: 16))
                .foregroundColor(.nutriSyncAccent)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.type.rawValue)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                Text("\(activity.startTime) - \(activity.endTime)")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct RestrictionSelectorV2: View {
    @Binding var restrictions: [String]
    
    let commonRestrictions = ["Vegan", "Vegetarian", "Gluten-free", "Dairy-free", "Nut-free", "Keto", "Paleo"]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
            ForEach(commonRestrictions, id: \.self) { restriction in
                Button {
                    if restrictions.contains(restriction) {
                        restrictions.removeAll { $0 == restriction }
                    } else {
                        restrictions.append(restriction)
                    }
                } label: {
                    Text(restriction)
                        .font(.system(size: 14))
                        .foregroundColor(restrictions.contains(restriction) ? .black : .white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(restrictions.contains(restriction) ? Color.nutriSyncAccent : Color.white.opacity(0.1))
                        )
                }
            }
        }
    }
}

// Simplified add activity sheet
struct AddActivitySheetV2: View {
    @Binding var activities: [PlannedActivityInput]
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedType: PlannedActivityInput.ActivityType = .workout
    @State private var startTime = "12:00 PM"
    @State private var endTime = "1:00 PM"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Activity type picker
                Picker("Activity Type", selection: $selectedType) {
                    ForEach(PlannedActivityInput.ActivityType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                
                // Time inputs
                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Start Time")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        TextField("Start", text: $startTime)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading) {
                        Text("End Time")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        TextField("End", text: $endTime)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let activity = PlannedActivityInput(
                            type: selectedType,
                            startTime: startTime,
                            endTime: endTime
                        )
                        activities.append(activity)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Activity Time Block
struct ActivityTimeBlock: Identifiable {
    let id = UUID()
    let activity: MorningActivity
    var startTime: Date
    var duration: Int // minutes
    
    var endTime: Date {
        Calendar.current.date(byAdding: .minute, value: duration, to: startTime) ?? startTime
    }
}

// MARK: - Day Timeline Visualization
struct DayTimeline: View {
    let blocks: [ActivityTimeBlock]
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Activity legend above timeline
            VStack(alignment: .leading, spacing: 6) {
                ForEach(blocks) { block in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(block.activity.color)
                            .frame(width: 8, height: 8)
                        
                        Text(block.activity.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text("(\(timeFormatter.string(from: block.startTime)) - \(timeFormatter.string(from: block.endTime)))")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 8)
            
            // Timeline visualization
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    // Background with vertical grid lines
                    HStack(spacing: 0) {
                        ForEach(0..<9, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.white.opacity(0.02))
                                .overlay(
                                    Rectangle()
                                        .fill(Color.white.opacity(0.05))
                                        .frame(width: 1),
                                    alignment: .leading
                                )
                        }
                    }
                    .cornerRadius(8)
                    
                    // Activity blocks - stacked vertically
                    VStack(spacing: 4) {
                        ForEach(Array(blocks.enumerated()), id: \.element.id) { index, block in
                            TimelineBlock(
                                block: block,
                                totalWidth: geometry.size.width,
                                verticalOffset: CGFloat(index * 20)
                            )
                        }
                    }
                    .padding(.top, 12)
                    
                    // Hour labels at bottom
                    VStack {
                        Spacer()
                        HStack(spacing: 0) {
                            ForEach([6, 9, 12, 15, 18, 21], id: \.self) { hour in
                                Text(hour == 12 ? "12pm" : hour < 12 ? "\(hour)am" : "\(hour-12)pm")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.4))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
        }
    }
}

struct TimelineBlock: View {
    let block: ActivityTimeBlock
    let totalWidth: CGFloat
    let verticalOffset: CGFloat
    
    private var offset: CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: block.startTime)
        let minute = calendar.component(.minute, from: block.startTime)
        let minutesSince6AM = max(0, (hour - 6) * 60 + minute)
        let totalMinutes = 17 * 60 // 6 AM to 11 PM
        return (CGFloat(minutesSince6AM) / CGFloat(totalMinutes)) * totalWidth
    }
    
    private var width: CGFloat {
        let totalMinutes = 17 * 60
        return min(totalWidth - offset, (CGFloat(block.duration) / CGFloat(totalMinutes)) * totalWidth)
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(
                LinearGradient(
                    colors: [
                        block.activity.color.opacity(0.4),
                        block.activity.color.opacity(0.6)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(block.activity.color, lineWidth: 1.5)
            )
            .frame(width: width, height: 16)
            .offset(x: offset, y: verticalOffset)
    }
}

// Use typealias to reference the existing PlannedActivityInput from EnhancedActivitiesView
// This avoids duplication while we transition