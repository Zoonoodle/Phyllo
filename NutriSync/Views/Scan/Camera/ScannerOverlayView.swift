//
//  ScannerOverlayView.swift
//  NutriSync
//
//  Created on 7/29/25.
//

import SwiftUI

struct ScannerOverlayView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Corner brackets
                ForEach(0..<4) { index in
                    CornerBracket(position: CornerPosition(rawValue: index)!)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.8),
                                    Color.white.opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 60, height: 60)
                        .position(cornerPosition(for: CornerPosition(rawValue: index)!, in: geometry.size))
                        .opacity(0.8)
                }
            }
        }
    }
    
    func cornerPosition(for corner: CornerPosition, in size: CGSize) -> CGPoint {
        let inset: CGFloat = 40
        
        switch corner {
        case .topLeft:
            return CGPoint(x: inset, y: inset + 100)
        case .topRight:
            return CGPoint(x: size.width - inset, y: inset + 100)
        case .bottomLeft:
            return CGPoint(x: inset, y: size.height - inset - 200)
        case .bottomRight:
            return CGPoint(x: size.width - inset, y: size.height - inset - 200)
        }
    }
}

enum CornerPosition: Int {
    case topLeft = 0
    case topRight = 1
    case bottomLeft = 2
    case bottomRight = 3
}

struct CornerBracket: Shape {
    let position: CornerPosition
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let length: CGFloat = 20
        
        switch position {
        case .topLeft:
            path.move(to: CGPoint(x: 0, y: length))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: length, y: 0))
            
        case .topRight:
            path.move(to: CGPoint(x: rect.width - length, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: length))
            
        case .bottomLeft:
            path.move(to: CGPoint(x: 0, y: rect.height - length))
            path.addLine(to: CGPoint(x: 0, y: rect.height))
            path.addLine(to: CGPoint(x: length, y: rect.height))
            
        case .bottomRight:
            path.move(to: CGPoint(x: rect.width, y: rect.height - length))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: rect.width - length, y: rect.height))
        }
        
        return path
    }
}

#Preview {
    ZStack {
        Color.black
        ScannerOverlayView()
    }
    .ignoresSafeArea()
}