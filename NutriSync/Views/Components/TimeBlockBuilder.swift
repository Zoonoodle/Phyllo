import SwiftUI

struct TimeBlockBuilder: View {
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
                        .frame(width: 50, alignment: .leading)
                    
                    Button(action: {
                        showingTimePicker = true
                        HapticManager.shared.impact(style: .light)
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
                        .frame(width: 50, alignment: .leading)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach([30, 45, 60, 90, 120], id: \.self) { minutes in
                                Button(action: {
                                    duration = minutes
                                    HapticManager.shared.impact(style: .light)
                                }) {
                                    Text(formatDuration(minutes))
                                        .font(.caption)
                                        .fontWeight(duration == minutes ? .semibold : .regular)
                                        .foregroundColor(duration == minutes ? .black : .white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            duration == minutes ? 
                                            Color.phylloAccent : 
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
                .frame(height: 60)
            }
        }
        .padding()
        .background(Color.phylloCard)
        .cornerRadius(PhylloDesignSystem.cornerRadius)
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
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background timeline
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.03))
                
                // Time block visualization
                HStack(spacing: 0) {
                    // Start time offset
                    Color.clear
                        .frame(width: calculateOffset(in: geometry.size.width))
                    
                    // Activity block
                    RoundedRectangle(cornerRadius: 6)
                        .fill(activity.color.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(activity.color, lineWidth: 2)
                        )
                        .frame(width: calculateWidth(in: geometry.size.width))
                        .overlay(
                            VStack(spacing: 2) {
                                Text(startTime, format: .dateTime.hour().minute())
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Text("→ \(endTime, format: .dateTime.hour().minute())")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.horizontal, 4)
                        )
                    
                    Spacer()
                }
                
                // Hour markers
                HStack(spacing: 0) {
                    ForEach(6..<23, id: \.self) { hour in
                        if hour % 3 == 0 {
                            VStack {
                                Spacer()
                                Text("\(hour):00")
                                    .font(.system(size: 8))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                            .frame(width: geometry.size.width / 17)
                        } else {
                            Color.clear
                                .frame(width: geometry.size.width / 17)
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
}

// MARK: - Compact Time Picker
struct CompactTimePicker: View {
    @Binding var selectedTime: Date
    @Environment(\.dismiss) private var dismiss
    
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
            .background(Color.phylloBackground)
            .navigationTitle("Select Start Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        HapticManager.shared.impact(style: .light)
                        dismiss()
                    }
                    .foregroundColor(.phylloAccent)
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
        .background(Color.phylloBackground)
    }
}