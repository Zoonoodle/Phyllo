//
//  DayProgressCard.swift
//  NutriSync
//
//  Individual day progress card for historical timeline
//

import SwiftUI

struct DayProgressCard: View {
    let date: Date
    let mealsLogged: Int
    let targetMeals: Int
    let timingScore: Double
    let nutrientScore: Double
    let adherenceScore: Double
    let isToday: Bool
    
    private var overallScore: Double {
        (timingScore + nutrientScore + adherenceScore) / 3
    }
    
    private var dayLabel: String {
        if isToday {
            return "TODAY"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date).uppercased()
    }
    
    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(dayLabel)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isToday ? Color.nutriSyncAccent : .white.opacity(0.5))
            
            Text(dateLabel)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.white.opacity(0.3))
            
            MiniProgressRing(score: overallScore)
                .frame(width: 60, height: 60)
            
            Text("\(Int(overallScore * 100))%")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text("\(mealsLogged)/\(targetMeals)")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(width: 100, height: 140)
        .background(Color.nutriSyncElevated)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isToday ? Color.nutriSyncAccent : Color.clear, lineWidth: 2)
        )
    }
}

struct MiniProgressRing: View {
    let score: Double
    @State private var animatedScore: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: animatedScore)
                .stroke(
                    LinearGradient(
                        colors: [
                            ringColor,
                            ringColor.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(
                        lineWidth: 4,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animatedScore = score
            }
        }
    }
    
    private var ringColor: Color {
        switch score {
        case 0.8...1.0:
            return Color(hex: "04DE71")
        case 0.5..<0.8:
            return Color.orange
        default:
            return Color(hex: "FF3B30")
        }
    }
}

struct ProgressTimelineSection: View {
    @ObservedObject var viewModel: ProgressTimelineViewModel
    @State private var scrollViewProxy: ScrollViewProxy? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("WEEKLY PROGRESS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(0.5)
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.5)))
                }
            }
            .padding(.horizontal, 20)
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.dailyAnalytics) { analytics in
                            DayProgressCard(
                                date: analytics.date,
                                mealsLogged: analytics.mealsLogged,
                                targetMeals: analytics.targetMeals,
                                timingScore: analytics.timingScore,
                                nutrientScore: analytics.nutrientScore,
                                adherenceScore: analytics.adherenceScore,
                                isToday: Calendar.current.isDateInToday(analytics.date)
                            )
                            .id(analytics.id)
                            .onTapGesture {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .onAppear {
                    scrollViewProxy = proxy
                    if let todayCard = viewModel.dailyAnalytics.first(where: { Calendar.current.isDateInToday($0.date) }) {
                        proxy.scrollTo(todayCard.id, anchor: .trailing)
                    }
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.nutriSyncBackground.ignoresSafeArea()
        
        VStack(spacing: 20) {
            DayProgressCard(
                date: Date(),
                mealsLogged: 2,
                targetMeals: 5,
                timingScore: 1.0,
                nutrientScore: 0.19,
                adherenceScore: 0.34,
                isToday: true
            )
            
            DayProgressCard(
                date: Date().addingTimeInterval(-86400),
                mealsLogged: 4,
                targetMeals: 5,
                timingScore: 0.8,
                nutrientScore: 0.75,
                adherenceScore: 0.9,
                isToday: false
            )
        }
    }
}