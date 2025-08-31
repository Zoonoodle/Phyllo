import SwiftUI

struct TimeScrollSelector: View {
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)
    
    @Binding var selectedTime: Date
    let hoursBack: Int
    let interval: Int
    let autoScrollTarget: Date?
    
    @State private var timeOptions: [Date] = []
    @Namespace private var scrollSpace
    
    init(selectedTime: Binding<Date>, hoursBack: Int = 6, interval: Int = 15, autoScrollTarget: Date? = nil) {
        self._selectedTime = selectedTime
        self.hoursBack = hoursBack
        self.interval = interval
        self.autoScrollTarget = autoScrollTarget
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Select Time")
                .font(.headline)
                .foregroundColor(.nutriSyncTextPrimary)
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(timeOptions, id: \.self) { time in
                            TimeOptionRow(
                                time: time,
                                isSelected: isSameTime(time, selectedTime),
                                relativeTime: relativeTimeString(for: time)
                            ) {
                                selectedTime = time
                                hapticGenerator.impactOccurred()
                            }
                            .id(time)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 400)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.nutriSyncElevated.opacity(0.5))
                )
                .onAppear {
                    generateTimeOptions()
                    if let target = autoScrollTarget ?? findClosestTime(to: selectedTime) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                proxy.scrollTo(target, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func generateTimeOptions() {
        let now = Date()
        let calendar = Calendar.current
        var options: [Date] = []
        
        // Add "Now" as the first option
        options.append(now)
        
        // Get current time components
        let currentComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
        let currentMinute = currentComponents.minute ?? 0
        
        // Calculate the most recent time divisible by 5
        let roundedMinute: Int
        if currentMinute % 5 == 0 {
            // If already divisible by 5, start from 15 minutes ago
            roundedMinute = currentMinute - 15
        } else {
            // Round down to nearest 5
            roundedMinute = (currentMinute / 5) * 5
        }
        
        // Create the starting point
        var startComponents = currentComponents
        startComponents.minute = roundedMinute
        
        guard let startTime = calendar.date(from: startComponents) else {
            timeOptions = options
            return
        }
        
        // Generate times going backwards in 15-minute intervals
        let totalIntervals = (hoursBack * 60) / interval
        for i in 0..<totalIntervals {
            if let time = calendar.date(byAdding: .minute, value: -interval * i, to: startTime) {
                // Don't add times that are in the future (except "Now")
                if time <= now {
                    options.append(time)
                }
            }
        }
        
        timeOptions = options
    }
    
    private func isSameTime(_ time1: Date, _ time2: Date) -> Bool {
        let calendar = Calendar.current
        let comp1 = calendar.dateComponents([.hour, .minute], from: time1)
        let comp2 = calendar.dateComponents([.hour, .minute], from: time2)
        return comp1.hour == comp2.hour && comp1.minute == comp2.minute
    }
    
    private func findClosestTime(to target: Date) -> Date? {
        let calendar = Calendar.current
        let targetComponents = calendar.dateComponents([.hour, .minute], from: target)
        let targetMinutes = (targetComponents.hour ?? 0) * 60 + (targetComponents.minute ?? 0)
        
        return timeOptions.min { time1, time2 in
            let comp1 = calendar.dateComponents([.hour, .minute], from: time1)
            let comp2 = calendar.dateComponents([.hour, .minute], from: time2)
            
            let minutes1 = (comp1.hour ?? 0) * 60 + (comp1.minute ?? 0)
            let minutes2 = (comp2.hour ?? 0) * 60 + (comp2.minute ?? 0)
            
            let diff1 = abs(minutes1 - targetMinutes)
            let diff2 = abs(minutes2 - targetMinutes)
            
            return diff1 < diff2
        }
    }
    
    private func relativeTimeString(for date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        // Check if this is the "Now" option (within 1 minute)
        if interval < 60 {
            return "Now"
        } else if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m ago"
            } else {
                return "\(hours) hour\(hours == 1 ? "" : "s") ago"
            }
        } else if minutes > 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else {
            return "Just now"
        }
    }
}

struct TimeOptionRow: View {
    let time: Date
    let isSelected: Bool
    let relativeTime: String
    let onTap: () -> Void
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(timeFormatter.string(from: time))
                        .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .nutriSyncAccent : .nutriSyncTextPrimary)
                    
                    Text(relativeTime)
                        .font(.caption)
                        .foregroundColor(.nutriSyncTextSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.nutriSyncAccent)
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.nutriSyncAccent.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}