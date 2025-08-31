import SwiftUI

struct TimeScrollSelector: View {
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
                .foregroundColor(.phylloText)
            
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
                                HapticManager.shared.impact(style: .light)
                            }
                            .id(time)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 300)
                .background(
                    RoundedRectangle(cornerRadius: PhylloDesignSystem.cornerRadius)
                        .fill(Color.phylloCard)
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
        
        let totalIntervals = (hoursBack * 60) / interval
        for i in 0..<totalIntervals {
            if let time = calendar.date(byAdding: .minute, value: -interval * i, to: now) {
                options.append(time)
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
        
        return timeOptions.min { time1, time2 in
            let comp1 = calendar.dateComponents([.hour, .minute], from: time1)
            let comp2 = calendar.dateComponents([.hour, .minute], from: time2)
            
            let diff1 = abs((comp1.hour ?? 0) * 60 + (comp1.minute ?? 0) - ((targetComponents.hour ?? 0) * 60 + (targetComponents.minute ?? 0)))
            let diff2 = abs((comp2.hour ?? 0) * 60 + (comp2.minute ?? 0) - ((targetComponents.hour ?? 0) * 60 + (targetComponents.minute ?? 0)))
            
            return diff1 < diff2
        }
    }
    
    private func relativeTimeString(for date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
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
                        .foregroundColor(isSelected ? .phylloAccent : .phylloText)
                    
                    Text(relativeTime)
                        .font(.caption)
                        .foregroundColor(.phylloTextSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.phylloAccent)
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.phylloAccent.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}