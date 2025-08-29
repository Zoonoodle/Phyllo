//
//  EnhancedActivitiesView.swift
//  NutriSync
//
//  Enhanced activity planning with time inputs
//

import SwiftUI

struct EnhancedActivitiesView: View {
    @Binding var plannedActivities: [String]
    @State private var activities: [PlannedActivityInput] = []
    @State private var showingAddActivity = false
    @State private var windowPreference: MorningCheckIn.WindowPreference = .auto
    @State private var hasRestrictions = false
    @State private var restrictions: [String] = []
    
    let onContinue: ([String], MorningCheckIn.WindowPreference, Bool, [String]) -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Text("Plan your day")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Add events with times for optimal meal scheduling")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            ScrollView {
                VStack(spacing: 20) {
                    // Window preference selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Meal windows today")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 12) {
                            WindowPreferenceButton(title: "Auto", isSelected: windowPreference == .auto) {
                                windowPreference = .auto
                            }
                            
                            WindowPreferenceButton(title: "3-4", isSelected: isRangeSelected(3, 4)) {
                                windowPreference = .range(3, 4)
                            }
                            
                            WindowPreferenceButton(title: "4-5", isSelected: isRangeSelected(4, 5)) {
                                windowPreference = .range(4, 5)
                            }
                            
                            WindowPreferenceButton(title: "5-6", isSelected: isRangeSelected(5, 6)) {
                                windowPreference = .range(5, 6)
                            }
                        }
                    }
                    
                    // Planned activities list
                    if !activities.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Planned activities")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            ForEach(activities) { activity in
                                ActivityRow(activity: activity) {
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
                        Toggle(isOn: $hasRestrictions) {
                            Text("Dietary restrictions")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .tint(.nutriSyncAccent)
                        
                        if hasRestrictions {
                            RestrictionSelector(restrictions: $restrictions)
                        }
                    }
                }
            }
            
            Spacer(minLength: 0)
            
            // Continue button
            Button {
                // Convert activities to string format
                let activityStrings = activities.map { activity in
                    "\(activity.type.rawValue) \(activity.startTime)-\(activity.endTime)"
                }
                onContinue(activityStrings, windowPreference, hasRestrictions, restrictions)
            } label: {
                Text("Generate meal plan")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.nutriSyncAccent)
                    )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
        .sheet(isPresented: $showingAddActivity) {
            AddActivitySheet(activities: $activities)
        }
    }
    
    private func isRangeSelected(_ min: Int, _ max: Int) -> Bool {
        if case .range(let rangeMin, let rangeMax) = windowPreference {
            return rangeMin == min && rangeMax == max
        }
        return false
    }
}

// MARK: - Supporting Views

struct WindowPreferenceButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .black : .white.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.nutriSyncAccent : Color.white.opacity(0.05))
                )
        }
    }
}

struct ActivityRow: View {
    let activity: PlannedActivityInput
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.type.icon)
                .font(.system(size: 16))
                .foregroundColor(.nutriSyncAccent)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.type.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Text("\(activity.startTime) - \(activity.endTime)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
        )
    }
}

struct RestrictionSelector: View {
    @Binding var restrictions: [String]
    
    let commonRestrictions = [
        "Vegan", "Vegetarian", "Gluten-free", 
        "Dairy-free", "Nut-free", "Keto", "Paleo"
    ]
    
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(commonRestrictions, id: \.self) { restriction in
                RestrictionChip(
                    title: restriction,
                    isSelected: restrictions.contains(restriction)
                ) {
                    if restrictions.contains(restriction) {
                        restrictions.removeAll { $0 == restriction }
                    } else {
                        restrictions.append(restriction)
                    }
                }
            }
        }
    }
}

struct RestrictionChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? .black : .white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.nutriSyncAccent : Color.white.opacity(0.05))
                )
        }
    }
}

// MARK: - Add Activity Sheet

struct AddActivitySheet: View {
    @Binding var activities: [PlannedActivityInput]
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedType: PlannedActivityInput.ActivityType = .workout
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600)
    @State private var isWorkout = false
    @State private var workoutType: WorkoutType = .both
    
    enum WorkoutType: String, CaseIterable {
        case cardio = "Cardio"
        case weights = "Weights"
        case both = "Both"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Activity type selector
                VStack(alignment: .leading, spacing: 12) {
                    Text("Activity type")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(PlannedActivityInput.ActivityType.allCases, id: \.self) { type in
                                ActivityTypeButton(
                                    type: type,
                                    isSelected: selectedType == type
                                ) {
                                    selectedType = type
                                    isWorkout = (type == .workout || type == .cardio || type == .weights)
                                }
                            }
                        }
                    }
                }
                
                // Workout type selector (if workout selected)
                if isWorkout {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Workout type")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 12) {
                            ForEach(WorkoutType.allCases, id: \.self) { type in
                                WorkoutTypeButton(
                                    type: type,
                                    isSelected: workoutType == type
                                ) {
                                    workoutType = type
                                }
                            }
                        }
                    }
                }
                
                // Time pickers
                VStack(spacing: 16) {
                    DatePicker(
                        "Start time",
                        selection: $startTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.compact)
                    .tint(.nutriSyncAccent)
                    
                    DatePicker(
                        "End time",
                        selection: $endTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.compact)
                    .tint(.nutriSyncAccent)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.03))
                )
                
                Spacer()
                
                // Add button
                Button {
                    let formatter = DateFormatter()
                    formatter.timeStyle = .short
                    
                    let activity = PlannedActivityInput(
                        type: isWorkout && workoutType == .cardio ? .cardio :
                              isWorkout && workoutType == .weights ? .weights :
                              selectedType,
                        startTime: formatter.string(from: startTime),
                        endTime: formatter.string(from: endTime)
                    )
                    
                    activities.append(activity)
                    dismiss()
                } label: {
                    Text("Add activity")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.nutriSyncAccent)
                        )
                }
            }
            .padding(24)
            .background(Color.nutriSyncBackground)
            .navigationTitle("Add activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
}

struct ActivityTypeButton: View {
    let type: PlannedActivityInput.ActivityType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 20))
                Text(type.rawValue)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isSelected ? .black : .white.opacity(0.7))
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.nutriSyncAccent : Color.white.opacity(0.05))
            )
        }
    }
}

struct WorkoutTypeButton: View {
    let type: AddActivitySheet.WorkoutType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(type.rawValue)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .black : .white.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.nutriSyncAccent : Color.white.opacity(0.05))
                )
        }
    }
}

// MARK: - Supporting Types

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

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return CGSize(width: proposal.replacingUnspecifiedDimensions().width, height: result.height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        
        for (index, row) in result.rows.enumerated() {
            var x = bounds.minX
            let y = bounds.minY + result.rowHeights[0..<index].reduce(0, +) + CGFloat(index) * spacing
            
            for subviewIndex in row {
                let subview = subviews[subviewIndex]
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
        }
    }
    
    struct FlowResult {
        var rows: [[Int]] = [[]]
        var rowHeights: [CGFloat] = [0]
        
        var height: CGFloat {
            rowHeights.reduce(0, +) + CGFloat(rows.count - 1) * 8
        }
        
        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentRow = 0
            var remainingWidth = width
            
            for (index, subview) in subviews.enumerated() {
                let size = subview.sizeThatFits(.unspecified)
                
                if size.width > remainingWidth && !rows[currentRow].isEmpty {
                    rows.append([])
                    rowHeights.append(0)
                    currentRow += 1
                    remainingWidth = width
                }
                
                rows[currentRow].append(index)
                rowHeights[currentRow] = max(rowHeights[currentRow], size.height)
                remainingWidth -= size.width + spacing
            }
        }
    }
}