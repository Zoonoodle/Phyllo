import SwiftUI

struct ChronologicalFoodList: View {
    let foodTimeline: [ScheduleViewModel.TimelineEntry]
    @State private var loadedImages: Set<String> = []
    
    private var groupedByHour: [(hour: String, entries: [ScheduleViewModel.TimelineEntry])] {
        let grouped = Dictionary(grouping: foodTimeline) { entry in
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: entry.timestamp)
        }
        
        return grouped
            .sorted { $0.key < $1.key }
            .map { (hour: $0.key, entries: $0.value) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Meals")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Text("\(foodTimeline.count) items logged")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            if foodTimeline.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "fork.knife")
                        .font(.title)
                        .foregroundStyle(.white.opacity(0.3))
                    
                    Text("No meals logged yet")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                    
                    Text("Start logging meals to see your daily food timeline")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(groupedByHour, id: \.hour) { group in
                            VStack(alignment: .leading, spacing: 12) {
                                // Time header
                                HStack {
                                    Circle()
                                        .fill(Color.phylloAccent)
                                        .frame(width: 8, height: 8)
                                    
                                    Text(group.hour)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white.opacity(0.7))
                                    
                                    Rectangle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 1)
                                }
                                
                                // Food entries for this time
                                VStack(spacing: 8) {
                                    ForEach(group.entries, id: \.id) { entry in
                                        FoodTimelineRow(
                                            entry: entry,
                                            isImageLoaded: loadedImages.contains(entry.id)
                                        ) {
                                            loadedImages.insert(entry.id)
                                        }
                                    }
                                }
                                .padding(.leading, 16)
                            }
                        }
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.nutriSyncBorder, lineWidth: 1)
                )
        )
        .clipped()
    }
}

struct FoodTimelineRow: View {
    let entry: ScheduleViewModel.TimelineEntry
    let isImageLoaded: Bool
    let onImageLoad: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Meal photo or placeholder
            if let imageData = entry.meal.imageData {
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.03))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "fork.knife")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.2))
                        )
                }
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.03))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.2))
                    )
            }
            
            // Meal details
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.meal.name)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Label("\(entry.meal.calories) cal", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                    
                    Text("•")
                        .foregroundStyle(.white.opacity(0.3))
                    
                    Text("\(entry.windowName)")
                        .font(.caption2)
                        .foregroundStyle(entry.windowColor.opacity(0.7))
                }
            }
            
            Spacer()
            
            // Macro summary
            VStack(alignment: .trailing, spacing: 2) {
                MacroIndicator(value: entry.meal.protein, unit: "P", color: .orange)
                MacroIndicator(value: entry.meal.carbs, unit: "C", color: .blue)
                MacroIndicator(value: entry.meal.fat, unit: "F", color: .yellow)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct MacroIndicator: View {
    let value: Int
    let unit: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Text("\(value)")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.6))
            
            Text(unit)
                .font(.caption2)
                .foregroundStyle(color.opacity(0.7))
        }
    }
}

#Preview {
    ZStack {
        Color.phylloBackground.ignoresSafeArea()
        
        ScrollView {
            ChronologicalFoodList(
                foodTimeline: [
                    // Empty for now - would need actual LoggedMeal instances
                ]
            )
            .padding()
        }
    }
}