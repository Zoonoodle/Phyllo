//
//  MomentumTabView.swift
//  Phyllo
//
//  Created on 7/27/25.
//

import SwiftUI

struct MomentumTabView: View {
    @Binding var showDeveloperDashboard: Bool
    @StateObject private var mockData = MockDataManager.shared
    @State private var selectedCard: MomentumCard? = nil
    
    enum MomentumCard: String, CaseIterable {
        case score = "score."
        case social = "social."
        case metrics = "metrics."
        case momentum = "momentum."
        
        var icon: String {
            switch self {
            case .score: return "chart.line.uptrend.xyaxis"
            case .social: return "person.2.fill"
            case .metrics: return "chart.bar.fill"
            case .momentum: return "waveform.path"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Color.phylloBackground.ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Navigation bar with logo
                        PhylloNavigationBar(
                            title: "Insights", 
                            showSettingsButton: true,
                            onSettingsTap: {
                                showDeveloperDashboard = true
                            }
                        )
                        
                        VStack(spacing: 20) {
                            // Header
                            VStack(alignment: .leading, spacing: 8) {
                                Text("insights.")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Track your nutrition progress and trends")
                                    .font(.system(size: 16))
                                    .foregroundColor(.phylloTextSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 20)
                        
                        // 2x2 Grid that fills remaining space
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            // PhylloScore Card
                            MomentumGridCard(
                                title: "score.",
                                icon: MomentumCard.score.icon,
                                primaryColor: Color.phylloAccent,
                                content: {
                                    VStack(spacing: 8) {
                                        Text("\(calculatePhylloScore())")
                                            .font(.system(size: 48, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        
                                        Text("PhylloScore")
                                            .font(.system(size: 14))
                                            .foregroundColor(.phylloTextSecondary)
                                    }
                                }
                            )
                            .onTapGesture {
                                selectedCard = .score
                            }
                            
                            // Social Card
                            MomentumGridCard(
                                title: "social.",
                                icon: MomentumCard.social.icon,
                                primaryColor: Color.orange,
                                content: {
                                    VStack(spacing: 8) {
                                        Text("#3")
                                            .font(.system(size: 48, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        
                                        Text("Your Rank")
                                            .font(.system(size: 14))
                                            .foregroundColor(.phylloTextSecondary)
                                    }
                                }
                            )
                            .onTapGesture {
                                selectedCard = .social
                            }
                            
                            // Metrics Card
                            MomentumGridCard(
                                title: "metrics.",
                                icon: MomentumCard.metrics.icon,
                                primaryColor: Color.blue,
                                content: {
                                    VStack(spacing: 8) {
                                        Text("73%")
                                            .font(.system(size: 48, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        
                                        Text("Goal Progress")
                                            .font(.system(size: 14))
                                            .foregroundColor(.phylloTextSecondary)
                                    }
                                }
                            )
                            .onTapGesture {
                                selectedCard = .metrics
                            }
                            
                            // Momentum Card
                            MomentumGridCard(
                                title: "momentum.",
                                icon: MomentumCard.momentum.icon,
                                primaryColor: Color.purple,
                                content: {
                                    VStack(spacing: 8) {
                                        Text("↑12%")
                                            .font(.system(size: 48, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        
                                        Text("This Week")
                                            .font(.system(size: 14))
                                            .foregroundColor(.phylloTextSecondary)
                                    }
                                }
                            )
                            .onTapGesture {
                                selectedCard = .momentum
                            }
                        }
                        .padding(.horizontal)
                        .frame(maxHeight: .infinity)
                        }
                    }
                    .padding(.bottom, 10) // Small padding before tab bar
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(item: $selectedCard) { card in
            switch card {
            case .score:
                PhylloScoreDetailView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            case .social:
                SocialLeaderboardDetailView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            case .metrics:
                MetricsDetailView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            case .momentum:
                MomentumWaveDetailView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    private func calculatePhylloScore() -> Int {
        // Simplified score calculation
        let baseScore = 52 // Mock score
        return baseScore
    }
}

// Grid Card Component
struct MomentumGridCard<Content: View>: View {
    let title: String
    let icon: String
    let primaryColor: Color
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title section
            HStack {
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Spacer()
            
            // Content section
            content()
                .frame(maxWidth: .infinity)
                .padding(.bottom, 20)
            
            // Icon decoration
            HStack {
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(primaryColor.opacity(0.3))
                    .offset(x: 10, y: 10)
            }
        }
        .frame(maxHeight: .infinity)
        .background(Color.phylloElevated)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

// Extension to make MomentumCard identifiable for sheet
extension MomentumTabView.MomentumCard: Identifiable {
    var id: String { rawValue }
}

#Preview {
    @Previewable @State var showDeveloperDashboard = false
    MomentumTabView(showDeveloperDashboard: $showDeveloperDashboard)
        .preferredColorScheme(.dark)
}