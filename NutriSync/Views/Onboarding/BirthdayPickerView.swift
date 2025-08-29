//
//  BirthdayPickerView.swift
//  NutriSync
//
//  Created on 8/17/25.
//

import SwiftUI

struct BirthdayPickerView: View {
    @Binding var currentPage: Int
    @State private var selectedMonth = Calendar.current.component(.month, from: Date()) - 1
    @State private var selectedDay = Calendar.current.component(.day, from: Date()) - 1
    @State private var selectedYear = Calendar.current.component(.year, from: Date()) - 1970
    
    private let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    private let days = Array(1...31)
    private let years = Array(1940...Calendar.current.component(.year, from: Date()))
    
    private let pickerHeight: CGFloat = 200
    private let itemHeight: CGFloat = 50
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicators
                HStack(spacing: 8) {
                    ForEach(0..<10) { index in
                        Capsule()
                            .fill(index <= 2 ? Color.white : Color.white.opacity(0.3))
                            .frame(height: 3)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 40)
                
                // Title
                VStack(spacing: 12) {
                    Text("When were you born?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Select the month, day, and year that you were born.")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Picker Container
                HStack(spacing: 0) {
                    // Month Picker
                    VerticalWheelPicker(
                        items: months,
                        selectedIndex: $selectedMonth,
                        itemHeight: itemHeight,
                        pickerHeight: pickerHeight
                    )
                    .frame(maxWidth: .infinity)
                    
                    // Day Picker
                    VerticalWheelPicker(
                        items: days.map { String($0) },
                        selectedIndex: $selectedDay,
                        itemHeight: itemHeight,
                        pickerHeight: pickerHeight
                    )
                    .frame(maxWidth: .infinity)
                    
                    // Year Picker
                    VerticalWheelPicker(
                        items: years.map { String($0) },
                        selectedIndex: $selectedYear,
                        itemHeight: itemHeight,
                        pickerHeight: pickerHeight
                    )
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Navigation buttons
                HStack {
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            currentPage -= 1
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Save birthday
                        let components = DateComponents(
                            year: years[selectedYear],
                            month: selectedMonth + 1,
                            day: days[selectedDay]
                        )
                        if let birthday = Calendar.current.date(from: components) {
                            UserDefaults.standard.set(birthday, forKey: "userBirthday")
                        }
                        
                        withAnimation(.spring(response: 0.3)) {
                            currentPage += 1
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text("Next")
                                .font(.system(size: 18, weight: .semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(Color.green)
                        .cornerRadius(30)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// Custom vertical wheel picker component
struct VerticalWheelPicker: View {
    let items: [String]
    @Binding var selectedIndex: Int
    let itemHeight: CGFloat
    let pickerHeight: CGFloat
    
    @State private var offset: CGFloat = 0
    @State private var isDragging = false
    
    private var visibleItemCount: Int {
        Int(pickerHeight / itemHeight)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Selection highlight
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: itemHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .position(x: geometry.size.width / 2, y: pickerHeight / 2)
                
                // Items
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Top padding
                        Color.clear
                            .frame(height: (pickerHeight - itemHeight) / 2)
                        
                        // Items
                        ForEach(0..<items.count, id: \.self) { index in
                            Text(items[index])
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(index == selectedIndex ? .white : .white.opacity(0.4))
                                .frame(height: itemHeight)
                                .frame(maxWidth: .infinity)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedIndex = index
                                        offset = -CGFloat(index) * itemHeight
                                    }
                                }
                        }
                        
                        // Bottom padding
                        Color.clear
                            .frame(height: (pickerHeight - itemHeight) / 2)
                    }
                    .offset(y: offset + (pickerHeight - itemHeight) / 2)
                }
                .frame(height: pickerHeight)
                .clipped()
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            let newOffset = offset + value.translation.height
                            let maxOffset: CGFloat = 0
                            let minOffset = -CGFloat(items.count - 1) * itemHeight
                            offset = min(maxOffset, max(minOffset, newOffset))
                        }
                        .onEnded { value in
                            isDragging = false
                            let velocity = value.predictedEndTranslation.height - value.translation.height
                            var finalOffset = offset + velocity * 0.2
                            
                            // Snap to nearest item
                            let itemIndex = Int(round(-finalOffset / itemHeight))
                            let clampedIndex = max(0, min(items.count - 1, itemIndex))
                            
                            withAnimation(.spring(response: 0.3)) {
                                selectedIndex = clampedIndex
                                offset = -CGFloat(clampedIndex) * itemHeight
                            }
                        }
                )
            }
        }
        .frame(height: pickerHeight)
        .onAppear {
            // Set initial offset based on selected index
            offset = -CGFloat(selectedIndex) * itemHeight
        }
    }
}

#Preview {
    BirthdayPickerView(currentPage: .constant(3))
}