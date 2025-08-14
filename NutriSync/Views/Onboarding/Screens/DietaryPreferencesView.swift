//
//  DietaryPreferencesView.swift
//  NutriSync
//
//  Dietary restrictions and allergies setup
//

import SwiftUI

struct DietaryPreferencesView: View {
    @Binding var data: OnboardingData
    @State private var showAllergies = false
    @State private var showRestrictions = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dietary preferences")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("We'll personalize meals to fit your needs")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                VStack(spacing: 24) {
                    // Eating Style
                    VStack(alignment: .leading, spacing: 16) {
                        Label {
                            Text("Eating Style")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        } icon: {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.green)
                        }
                        
                        VStack(spacing: 12) {
                            ForEach(EatingStyle.allCases, id: \.self) { style in
                                EatingStyleOption(
                                    style: style,
                                    isSelected: data.eatingStyle == style
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        data.eatingStyle = style
                                    }
                                }
                            }
                        }
                    }
                    
                    // Food Allergies
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label {
                                Text("Food Allergies")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            } icon: {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.orange)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showAllergies.toggle()
                                }
                            }) {
                                Image(systemName: showAllergies ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        
                        if !data.allergies.isEmpty {
                            Text("\(data.allergies.count) selected")
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                        }
                        
                        if showAllergies {
                            FlowLayout(spacing: 8) {
                                ForEach(FoodAllergy.allCases, id: \.self) { allergy in
                                    AllergyTag(
                                        allergy: allergy,
                                        isSelected: data.allergies.contains(allergy)
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            if data.allergies.contains(allergy) {
                                                data.allergies.remove(allergy)
                                            } else {
                                                data.allergies.insert(allergy)
                                            }
                                        }
                                    }
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .opacity
                            ))
                        }
                    }
                    
                    // Dietary Restrictions
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label {
                                Text("Additional Restrictions")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            } icon: {
                                Image(systemName: "nosign")
                                    .font(.system(size: 18))
                                    .foregroundColor(.red)
                            }
                            
                            Spacer()
                            
                            Text("Optional")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showRestrictions.toggle()
                                }
                            }) {
                                Image(systemName: showRestrictions ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        
                        if !data.dietaryRestrictions.isEmpty {
                            Text("\(data.dietaryRestrictions.count) selected")
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                        }
                        
                        if showRestrictions {
                            FlowLayout(spacing: 8) {
                                ForEach(DietaryRestriction.allCases, id: \.self) { restriction in
                                    RestrictionTag(
                                        restriction: restriction,
                                        isSelected: data.dietaryRestrictions.contains(restriction)
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            if data.dietaryRestrictions.contains(restriction) {
                                                data.dietaryRestrictions.remove(restriction)
                                            } else {
                                                data.dietaryRestrictions.insert(restriction)
                                            }
                                        }
                                    }
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .opacity
                            ))
                        }
                    }
                    
                    // Info Card
                    InfoCard(
                        icon: "info.circle.fill",
                        text: "Your dietary preferences help us suggest meals you'll love and avoid foods that don't work for you.",
                        color: .nutriSyncAccent
                    )
                }
                .padding(.horizontal)
                
                // Spacer for bottom padding
                Color.clear.frame(height: 100)
            }
        }
    }
}

// MARK: - Eating Style Option

struct EatingStyleOption: View {
    let style: EatingStyle
    let isSelected: Bool
    let action: () -> Void
    
    var icon: String {
        switch style {
        case .noRestrictions: return "checkmark.circle"
        case .vegetarian: return "leaf"
        case .vegan: return "leaf.fill"
        case .pescatarian: return "fish"
        case .keto: return "drop.fill"
        case .paleo: return "carrot"
        case .mediterranean: return "sun.max"
        case .other: return "ellipsis.circle"
        }
    }
    
    var color: Color {
        switch style {
        case .noRestrictions: return .gray
        case .vegetarian, .vegan: return .green
        case .pescatarian: return .blue
        case .keto: return .purple
        case .paleo: return .orange
        case .mediterranean: return .teal
        case .other: return .gray
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? color.opacity(0.2) : Color.white.opacity(0.05))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? color : .white.opacity(0.5))
                }
                
                // Text
                Text(style.rawValue)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                
                Spacer()
                
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? color : Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    
                    if isSelected {
                        Circle()
                            .fill(color)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isSelected ? 0.05 : 0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? color.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Allergy Tag

struct AllergyTag: View {
    let allergy: FoodAllergy
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                }
                
                Text(allergy.rawValue)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isSelected ? .black : .white.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.orange : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? Color.clear : Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Restriction Tag

struct RestrictionTag: View {
    let restriction: DietaryRestriction
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text(restriction.rawValue)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.red.opacity(0.8) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? Color.clear : Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
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
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: result.frames[index].minX + bounds.minX,
                                    y: result.frames[index].minY + bounds.minY),
                         proposal: ProposedViewSize(result.frames[index].size))
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: size))
                
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
                
                self.size.width = max(self.size.width, currentX - spacing)
            }
            
            self.size.height = currentY + lineHeight
        }
    }
}

// MARK: - Info Card

struct InfoCard: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var data = OnboardingData()
        
        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                DietaryPreferencesView(data: $data)
            }
        }
    }
    
    return PreviewWrapper()
}