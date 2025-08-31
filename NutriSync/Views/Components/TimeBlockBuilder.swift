import SwiftUI

struct TimeBlockBuilder: View {
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)
    
    @Binding var startTime: Date
    @Binding var duration: Int // minutes
    let activity: MorningActivity
    
    @State private var showingTimePicker = false
    
    var endTime: Date {
        Calendar.current.date(byAdding: .minute, value: duration, to: startTime) ?? startTime
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Activity Header
            HStack {
                Image(systemName: activity.icon)
                    .font(.title2)
                    .foregroundColor(activity.color)
                    .frame(width: 30)
                
                Text(activity.rawValue)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Time Selection
            VStack(spacing: 12) {
                // Start Time Selector
                HStack {
                    Text("Start")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 70, alignment: .leading)
                    
                    Button(action: {
                        showingTimePicker = true
                        hapticGenerator.impactOccurred()
                    }) {
                        HStack {
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text(startTime, format: .dateTime.hour().minute())
                                .font(.body)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.3))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
                
                // Duration Quick Select
                HStack {
                    Text("Duration")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 70, alignment: .leading)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach([30, 45, 60, 90, 120], id: \.self) { minutes in
                                Button(action: {
                                    duration = minutes
                                    hapticGenerator.impactOccurred()
                                }) {
                                    Text(formatDuration(minutes))
                                        .font(.caption)
                                        .fontWeight(duration == minutes ? .semibold : .regular)
                                        .foregroundColor(duration == minutes ? .black : .white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            duration == minutes ? 
                                            Color.nutriSyncAccent : 
                                            Color.white.opacity(0.1)
                                        )
                                        .cornerRadius(16)
                                }
                            }
                        }
                    }
                }
                
                // Visual Timeline Preview
                TimelinePreview(
                    startTime: startTime,
                    duration: duration,
                    activity: activity
                )
                .frame(height: 80)
            }
        }
        .padding()
        .background(Color.nutriSyncElevated.opacity(0.5))
        .cornerRadius(16)
        .sheet(isPresented: $showingTimePicker) {
            CompactTimePicker(selectedTime: $startTime)
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
        }
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        } else if minutes % 60 == 0 {
            return "\(minutes/60)h"
        } else {
            return "\(minutes/60)h \(minutes%60)m"
        }
    }
}

// MARK: - Timeline Preview
struct TimelinePreview: View {
    let startTime: Date
    let duration: Int
    let activity: MorningActivity
    
    var endTime: Date {
        Calendar.current.date(byAdding: .minute, value: duration, to: startTime) ?? startTime
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Time display above timeline
            HStack {
                Text(timeFormatter.string(from: startTime))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
                
                Text(timeFormatter.string(from: endTime))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(formatDuration(duration))")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Simplified timeline bar
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    // Background with grid lines
                    HStack(spacing: 0) {
                        ForEach(0..<9, id: \.self) { index in
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
                    
                    // Activity bar
                    HStack(spacing: 0) {
                        // Offset spacer
                        Color.clear
                            .frame(width: calculateOffset(in: geometry.size.width))
                        
                        // Activity block - simple and clean
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        activity.color.opacity(0.4),
                                        activity.color.opacity(0.6)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: calculateWidth(in: geometry.size.width), height: 24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(activity.color, lineWidth: 1.5)
                            )
                        
                        Spacer()
                    }
                    .padding(.vertical, 6)
                    
                    // Hour labels below
                    VStack {
                        Spacer()
                        HStack(spacing: 0) {
                            ForEach([6, 9, 12, 15, 18, 21], id: \.self) { hour in
                                Text(hour == 12 ? "12pm" : hour < 12 ? "\(hour)am" : "\(hour-12)pm")
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.3))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func calculateOffset(in totalWidth: CGFloat) -> CGFloat {
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: startTime)
        let startMinute = calendar.component(.minute, from: startTime)
        let startTimeInMinutes = (startHour - 6) * 60 + startMinute // Day starts at 6 AM
        let totalMinutesInDay = 17 * 60 // 6 AM to 11 PM = 17 hours
        
        return max(0, (CGFloat(startTimeInMinutes) / CGFloat(totalMinutesInDay)) * totalWidth)
    }
    
    private func calculateWidth(in totalWidth: CGFloat) -> CGFloat {
        let totalMinutesInDay = 17 * 60 // 6 AM to 11 PM
        return min(totalWidth, (CGFloat(duration) / CGFloat(totalMinutesInDay)) * totalWidth)
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        } else if minutes % 60 == 0 {
            return "\(minutes/60)h"
        } else {
            return "\(minutes/60)h \(minutes%60)m"
        }
    }
}

// MARK: - Compact Time Picker
struct CompactTimePicker: View {
    @Binding var selectedTime: Date
    @Environment(\.dismiss) private var dismiss
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Select Time",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .preferredColorScheme(.dark)
                
                Spacer()
            }
            .padding()
            .background(Color.nutriSyncBackground)
            .navigationTitle("Select Start Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        hapticGenerator.impactOccurred()
                        dismiss()
                    }
                    .foregroundColor(.nutriSyncAccent)
                }
            }
        }
    }
}

// MARK: - Preview
struct TimeBlockBuilder_Previews: PreviewProvider {
    static var previews: some View {
        TimeBlockBuilder(
            startTime: .constant(Date()),
            duration: .constant(60),
            activity: .workout
        )
        .padding()
        .background(Color.nutriSyncBackground)
    }
}