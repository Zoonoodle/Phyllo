//
//  SocialLeaderboardDetailView.swift
//  Phyllo
//
//  Created on 7/27/25.
//

import SwiftUI

struct SocialLeaderboardDetailView: View {
    @StateObject private var mockData = MockDataManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var animateRanks = false
    @State private var selectedTimeRange = TimeRange.week
    
    enum TimeRange: String, CaseIterable {
        case week = "This Week"
        case month = "This Month"
        case allTime = "All Time"
    }
    
    // Mock friend data
    private let mockFriends: [LeaderboardEntry] = [
        LeaderboardEntry(name: "Sarah M.", score: 94, goal: .weightLoss(targetPounds: 10, timeline: 8), profileImage: "person.crop.circle.fill", rankChange: 0),
        LeaderboardEntry(name: "Mike R.", score: 92, goal: .muscleGain(targetPounds: 5, timeline: 12), profileImage: "person.crop.circle.fill", rankChange: 1),
        LeaderboardEntry(name: "You", score: 87, goal: .performanceFocus, profileImage: "person.crop.circle.fill", rankChange: 2, isCurrentUser: true),
        LeaderboardEntry(name: "Alex T.", score: 85, goal: .overallWellbeing, profileImage: "person.crop.circle.fill", rankChange: -1),
        LeaderboardEntry(name: "Jamie L.", score: 82, goal: .muscleGain(targetPounds: 8, timeline: 16), profileImage: "person.crop.circle.fill", rankChange: -1),
        LeaderboardEntry(name: "Sam K.", score: 78, goal: .weightLoss(targetPounds: 15, timeline: 12), profileImage: "person.crop.circle.fill", rankChange: 0),
        LeaderboardEntry(name: "Taylor P.", score: 75, goal: .performanceFocus, profileImage: "person.crop.circle.fill", rankChange: 3),
        LeaderboardEntry(name: "Chris W.", score: 73, goal: .betterSleep, profileImage: "person.crop.circle.fill", rankChange: -2),
        LeaderboardEntry(name: "Jordan K.", score: 71, goal: .maintainWeight, profileImage: "person.crop.circle.fill", rankChange: 1),
        LeaderboardEntry(name: "Riley S.", score: 68, goal: .athleticPerformance(sport: "Running"), profileImage: "person.crop.circle.fill", rankChange: 0)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.phylloBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Time Range Selector
                        Picker("Time Range", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        // Leaderboard Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Your Squad")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("\(mockFriends.count) friends competing")
                                    .font(.system(size: 14))
                                    .foregroundColor(.phylloTextTertiary)
                            }
                            
                            Spacer()
                            
                            Button {
                                // Invite friends
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 14))
                                    Text("Invite")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.phylloAccent)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.phylloAccent.opacity(0.2))
                                .cornerRadius(20)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Leaderboard List
                        VStack(spacing: 8) {
                            ForEach(Array(mockFriends.enumerated()), id: \.element.id) { index, entry in
                                LeaderboardRow(
                                    entry: entry,
                                    rank: index + 1,
                                    animateIn: animateRanks
                                )
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                                .animation(.spring(response: 0.4).delay(Double(index) * 0.05), value: animateRanks)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.phylloAccent)
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

#Preview {
    SocialLeaderboardDetailView()
        .preferredColorScheme(.dark)
}