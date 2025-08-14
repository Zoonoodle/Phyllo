//
//  SpotlightOverlay.swift
//  NutriSync
//
//  Created on 7/29/25.
//

import SwiftUI

struct SpotlightOverlay: View {
    let spotlightFrame: CGRect
    let cornerRadius: CGFloat
    let dimOpacity: Double
    @Binding var isShowing: Bool
    let onDismiss: () -> Void
    
    @State private var animateIn = false
    
    init(
        spotlightFrame: CGRect,
        cornerRadius: CGFloat = 20,
        dimOpacity: Double = 0.85,
        isShowing: Binding<Bool>,
        onDismiss: @escaping () -> Void = {}
    ) {
        self.spotlightFrame = spotlightFrame
        self.cornerRadius = cornerRadius
        self.dimOpacity = dimOpacity
        self._isShowing = isShowing
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        if isShowing {
            ZStack {
                // Dimmed background with cutout
                GeometryReader { geometry in
                    Path { path in
                        // Add full screen rect
                        path.addRect(CGRect(origin: .zero, size: geometry.size))
                        
                        // Subtract spotlight area
                        let spotlightPath = Path(
                            roundedRect: spotlightFrame,
                            cornerRadius: cornerRadius
                        )
                        path.addPath(spotlightPath)
                    }
                    .fill(
                        Color.black.opacity(animateIn ? dimOpacity : 0),
                        style: FillStyle(eoFill: true)
                    )
                    .animation(.easeOut(duration: 0.3), value: animateIn)
                    .allowsHitTesting(false)
                }
                .ignoresSafeArea()
                
                // Tap outside to dismiss
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismissOverlay()
                    }
                    .allowsHitTesting(true)
                
                // Cutout area should not be tappable for dismissal
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: spotlightFrame.width, height: spotlightFrame.height)
                    .position(
                        x: spotlightFrame.midX,
                        y: spotlightFrame.midY
                    )
                    .allowsHitTesting(false)
            }
            .onAppear {
                withAnimation {
                    animateIn = true
                }
            }
        }
    }
    
    private func dismissOverlay() {
        withAnimation(.easeOut(duration: 0.2)) {
            animateIn = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isShowing = false
            onDismiss()
        }
    }
}

// Helper view for getting frame coordinates
struct FrameGetter: View {
    @Binding var frame: CGRect
    let coordinateSpace: CoordinateSpace
    
    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(
                    key: FramePreferenceKey.self,
                    value: geometry.frame(in: coordinateSpace)
                )
        }
        .onPreferenceChange(FramePreferenceKey.self) { value in
            frame = value
        }
    }
}

struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// Preview helper
struct SpotlightOverlay_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State private var showSpotlight = true
        @State private var buttonFrame: CGRect = .zero
        
        var body: some View {
            ZStack {
                Color.nutriSyncBackground.ignoresSafeArea()
                
                VStack {
                    Text("Tap outside the spotlight to dismiss")
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.top, 100)
                    
                    Spacer()
                    
                    Button {
                        print("Button tapped")
                    } label: {
                        Text("Spotlight Target")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.nutriSyncBackground)
                            .frame(width: 200, height: 50)
                            .background(Color.nutriSyncAccent)
                            .cornerRadius(25)
                    }
                    .background(
                        FrameGetter(
                            frame: $buttonFrame,
                            coordinateSpace: .global
                        )
                    )
                    
                    Spacer()
                }
                
                SpotlightOverlay(
                    spotlightFrame: buttonFrame,
                    cornerRadius: 25,
                    dimOpacity: 0.85,
                    isShowing: $showSpotlight
                ) {
                    print("Spotlight dismissed")
                }
            }
        }
    }
    
    static var previews: some View {
        PreviewWrapper()
    }
}