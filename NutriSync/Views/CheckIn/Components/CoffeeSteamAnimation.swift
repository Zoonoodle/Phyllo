//
//  CoffeeSteamAnimation.swift
//  NutriSync
//
//  Created on 7/28/25.
//

import SwiftUI

struct CoffeeSteamAnimation: View {
    @State private var animateSteam = false
    
    var body: some View {
        ZStack {
            // Coffee cup - enlarged
            CoffeeCupShape()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 140, height: 110)
                .offset(y: 40)
            
            // Steam layers
            ForEach(0..<3, id: \.self) { index in
                SteamPath(index: index)
                    .trim(from: 0, to: animateSteam ? 1.0 : 0.0)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        ),
                        lineWidth: 1.5  // Ultra thin
                    )
                    .frame(width: 180, height: 200)
                    .offset(y: -20)
                    .opacity(animateSteam ? 1.0 : 0.0)
                    .animation(
                        .easeOut(duration: 4.0 + Double(index) * 0.5)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.4),
                        value: animateSteam
                    )
            }
        }
        .frame(width: 280, height: 280)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateSteam = true
            }
        }
    }
}

// MARK: - Coffee Cup Shape
struct CoffeeCupShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Cup body
        path.move(to: CGPoint(x: rect.width * 0.2, y: rect.height * 0.3))
        path.addLine(to: CGPoint(x: rect.width * 0.25, y: rect.height * 0.9))
        path.addQuadCurve(
            to: CGPoint(x: rect.width * 0.75, y: rect.height * 0.9),
            control: CGPoint(x: rect.width * 0.5, y: rect.height * 0.95)
        )
        path.addLine(to: CGPoint(x: rect.width * 0.8, y: rect.height * 0.3))
        
        // Cup rim
        path.move(to: CGPoint(x: rect.width * 0.15, y: rect.height * 0.3))
        path.addQuadCurve(
            to: CGPoint(x: rect.width * 0.85, y: rect.height * 0.3),
            control: CGPoint(x: rect.width * 0.5, y: rect.height * 0.25)
        )
        
        // Handle
        path.move(to: CGPoint(x: rect.width * 0.8, y: rect.height * 0.5))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.8, y: rect.height * 0.7),
            control1: CGPoint(x: rect.width * 0.95, y: rect.height * 0.5),
            control2: CGPoint(x: rect.width * 0.95, y: rect.height * 0.7)
        )
        
        // Saucer
        path.move(to: CGPoint(x: rect.width * 0.1, y: rect.height * 0.9))
        path.addQuadCurve(
            to: CGPoint(x: rect.width * 0.9, y: rect.height * 0.9),
            control: CGPoint(x: rect.width * 0.5, y: rect.height * 0.85)
        )
        
        return path
    }
}

// MARK: - Steam Path
struct SteamPath: Shape {
    let index: Int
    
    var animatableData: Double = 0
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Start positions at the top rim of the cup
        let cupTopY = rect.height * 0.65  // Top of the cup
        let cupWidth: CGFloat = 70  // Half width of cup opening
        
        // Different starting positions across the cup's top
        let startOffset = CGFloat(index - 1) * 20
        let startX = rect.width * 0.5 + startOffset
        let startY = cupTopY
        
        path.move(to: CGPoint(x: startX, y: startY))
        
        // Create smooth wavy steam path
        let controlPoints = 20
        for i in 1...controlPoints {
            let progress = CGFloat(i) / CGFloat(controlPoints)
            
            // Steam rises and dissipates
            let y = startY - (progress * rect.height * 0.5)
            
            // Wave parameters
            let waveAmplitude = (8 + CGFloat(index) * 4) * progress
            let waveFrequency = 2.5 + Double(index) * 0.3
            let phase = Double(index) * .pi * 0.5
            
            // Smooth sine wave motion
            let x = startX + sin(progress * .pi * waveFrequency + phase) * waveAmplitude
            
            // Use quadratic curves for smoother lines
            if i == 1 {
                path.addLine(to: CGPoint(x: x, y: y))
            } else {
                let prevProgress = CGFloat(i - 1) / CGFloat(controlPoints)
                let prevY = startY - (prevProgress * rect.height * 0.5)
                let prevX = startX + sin(prevProgress * .pi * waveFrequency + phase) * (8 + CGFloat(index) * 4) * prevProgress
                
                let controlX = (prevX + x) / 2
                let controlY = (prevY + y) / 2
                
                path.addQuadCurve(
                    to: CGPoint(x: x, y: y),
                    control: CGPoint(x: controlX, y: controlY)
                )
            }
        }
        
        return path
    }
}


#Preview {
    ZStack {
        Color.nutriSyncBackground.ignoresSafeArea()
        
        CoffeeSteamAnimation()
    }
}