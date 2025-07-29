//
//  SocialLeaderboardCard.swift
//  Phyllo
//
//  Created on 7/27/25.
//

import SwiftUI

struct SocialLeaderboardCard: View {
    @StateObject private var mockData = MockDataManager.shared
    @State private var animateRanks = false
    @State private var showAllFriends = false
    
    // Mock friend data with different goals
    private let mockFriends: [LeaderboardEntry] = [
        LeaderboardEntry(name: "Sarah M.", score: 94, goal: .weightLoss(targetPounds: 10, timeline: 8), profileImage: "person.crop.circle.fill", rankChange: 0),
        LeaderboardEntry(name: "Mike R.", score: 92, goal: .muscleGain(targetPounds: 5, timeline: 12), profileImage: "person.crop.circle.fill", rankChange: 1),
        LeaderboardEntry(name: "You", score: 87, goal: .performanceFocus, profileImage: "person.crop.circle.fill", rankChange: 2, isCurrentUser: true),
        LeaderboardEntry(name: "Alex T.", score: 85, goal: .overallWellbeing, profileImage: "person.crop.circle.fill", rankChange: -1),
        LeaderboardEntry(name: "Jamie L.", score: 82, goal: .muscleGain(targetPounds: 8, timeline: 16), profileImage: "person.crop.circle.fill", rankChange: -1),
        LeaderboardEntry(name: "Sam K.", score: 78, goal: .weightLoss(targetPounds: 15, timeline: 12), profileImage: "person.crop.circle.fill", rankChange: 0),
        LeaderboardEntry(name: "Taylor P.", score: 75, goal: .performanceFocus, profileImage: "person.crop.circle.fill", rankChange: 3)
    ]
    
    private var displayedFriends: [LeaderboardEntry] {
        showAllFriends ? mockFriends : Array(mockFriends.prefix(5))
    }
    
    var body: some View {
        SimplePhylloCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Squad")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("This week • \(mockFriends.count) friends")
                            .font(.system(size: 14))
                            .foregroundColor(.phylloTextTertiary)
                    }
                    
                    Spacer()
                    
                    Button {
                        // Invite friends action
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 14))
                            Text("Invite")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.phylloAccent)
                    }
                }
                
                // Leaderboard
                VStack(spacing: 8) {
                    ForEach(Array(displayedFriends.enumerated()), id: \.element.id) { index, entry in
                        LeaderboardRow(
                            entry: entry,
                            rank: index + 1,
                            animateIn: animateRanks
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .animation(.spring(response: 0.4).delay(Double(index) * 0.1), value: animateRanks)
                    }
                }
                
                // View All Button
                if mockFriends.count > 5 {
                    Button {
                        withAnimation(.spring()) {
                            showAllFriends.toggle()
                        }
                    } label: {
                        HStack {
                            Text(showAllFriends ? "Show Less" : "View All")
                                .font(.system(size: 14, weight: .medium))
                            
                            Image(systemName: showAllFriends ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.phylloTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .onAppear {
            withAnimation {
                animateRanks = true
            }
        }
    }
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let rank: Int
    let animateIn: Bool
    
    @State private var showGoalTooltip = false
    
    private var rankColor: Color {
        switch rank {
        case 1: return Color(hex: "FFD700") // Gold
        case 2: return Color(hex: "C0C0C0") // Silver
        case 3: return Color(hex: "CD7F32") // Bronze
        default: return .phylloTextSecondary
        }
    }
    
    private var rankEmoji: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return ""
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            ZStack {
                if rank <= 3 {
                    Text(rankEmoji)
                        .font(.system(size: 24))
                } else {
                    Text("\(rank)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(rankColor)
                        .frame(width: 24)
                }
            }
            .frame(width: 32)
            
            // Profile Picture
            Image(systemName: entry.profileImage)
                .font(.system(size: 24))
                .foregroundColor(entry.isCurrentUser ? .phylloAccent : .phylloTextSecondary)
                .frame(width: 40, height: 40)
                .background(entry.isCurrentUser ? Color.phylloAccent.opacity(0.2) : Color.white.opacity(0.1))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(entry.isCurrentUser ? Color.phylloAccent : Color.clear, lineWidth: 2)
                )
            
            // Name and Goal
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.system(size: 16, weight: entry.isCurrentUser ? .semibold : .medium))
                    .foregroundColor(entry.isCurrentUser ? .phylloAccent : .white)
                
                // Goal indicator
                HStack(spacing: 4) {
                    Image(systemName: entry.goal.icon)
                        .font(.system(size: 10))
                    Text(entry.goal.shortName)
                        .font(.system(size: 12))
                }
                .foregroundColor(.phylloTextTertiary)
                .onTapGesture {
                    showGoalTooltip.toggle()
                }
            }
            
            Spacer()
            
            // Score and Change
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.score)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                // Rank change
                if entry.rankChange != 0 {
                    HStack(spacing: 2) {
                        Image(systemName: entry.rankChange > 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 10, weight: .bold))
                        Text("\(abs(entry.rankChange))")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(entry.rankChange > 0 ? .phylloAccent : .red)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(entry.isCurrentUser ? Color.phylloAccent.opacity(0.1) : Color.white.opacity(0.03))
        .cornerRadius(12)
        .scaleEffect(animateIn ? 1 : 0.8)
        .opacity(animateIn ? 1 : 0)
    }
}

struct LeaderboardEntry: Identifiable {
    let id = UUID()
    let name: String
    let score: Int
    let goal: NutritionGoal
    let profileImage: String
    let rankChange: Int
    var isCurrentUser: Bool = false
}

// Extension for goal display
extension NutritionGoal {
    var shortName: String {
        switch self {
        case .weightLoss: return "Weight Loss"
        case .muscleGain: return "Muscle"
        case .maintainWeight: return "Maintain"
        case .performanceFocus: return "Performance"
        case .betterSleep: return "Sleep"
        case .overallWellbeing: return "Wellbeing"
        case .athleticPerformance: return "Athletic"
        }
    }
}

#Preview {
    VStack {
        SocialLeaderboardCard()
            .padding()
        
        Spacer()
    }
    .background(Color.phylloBackground)
    .preferredColorScheme(.dark)
}