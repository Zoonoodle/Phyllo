import Foundation

// MARK: - Window Calculation Service
/// Service for generating meal windows based on user profile and goals
struct WindowCalculationService {
    
    /// Generate daily meal windows based on user profile and morning check-in
    static func generateWindows(
        for date: Date,
        profile: UserProfile,
        morningCheckIn: MorningCheckInData?
    ) -> [MealWindow] {
        
        let calendar = Calendar.current
        let dayDate = calendar.startOfDay(for: date)
        
        // Use morning check-in wake time or typical wake time
        let wakeTime = morningCheckIn?.wakeTime ?? Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: date) ?? date(for: date)
        let sleepTime = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: date) ?? date(for: date)
        
        // Calculate eating window (stop eating 3 hours before sleep)
        let lastMealTime = sleepTime.addingTimeInterval(-3 * 3600) // 3 hours before sleep
        let totalEatingWindow = lastMealTime.timeIntervalSince(wakeTime)
        
        switch profile.primaryGoal {
        case .weightLoss:
            return generateWeightLossWindows(
                dayDate: dayDate,
                wakeTime: wakeTime,
                lastMealTime: lastMealTime,
                profile: profile
            )
            
        case .muscleBuild:
            return generateMuscleGainWindows(
                dayDate: dayDate,
                wakeTime: wakeTime,
                lastMealTime: lastMealTime,
                profile: profile
            )
            
        case .improveEnergy:
            return generatePerformanceWindows(
                dayDate: dayDate,
                wakeTime: wakeTime,
                lastMealTime: lastMealTime,
                profile: profile
            )
            
        case .maintainWeight:
            return generateBalancedWindows(
                dayDate: dayDate,
                wakeTime: wakeTime,
                lastMealTime: lastMealTime,
                profile: profile
            )
        }
    }
    
    // MARK: - Weight Loss Windows (16:8 Intermittent Fasting)
    
    private static func generateWeightLossWindows(
        dayDate: Date,
        wakeTime: Date,
        lastMealTime: Date,
        profile: UserProfile
    ) -> [MealWindow] {
        
        // 16:8 fasting - first meal 5 hours after waking
        let firstMealTime = wakeTime.addingTimeInterval(5 * 3600)
        let dailyCalories = profile.calculateDailyCalories()
        
        return [
            // Window 1: Lunch (40% of calories)
            MealWindow(
                startTime: firstMealTime,
                endTime: firstMealTime.addingTimeInterval(2 * 3600),
                targetCalories: Int(Double(dailyCalories) * 0.40),
                targetMacros: MacroTargets(
                    protein: Int(Double(profile.calculateDailyProtein()) * 0.40),
                    carbs: Int(Double(profile.calculateDailyCarbs()) * 0.35),
                    fat: Int(Double(profile.calculateDailyFat()) * 0.40)
                ),
                purpose: .metabolicBoost,
                flexibility: .moderate,
                dayDate: dayDate
            ),
            
            // Window 2: Afternoon Snack (20% of calories)
            MealWindow(
                startTime: firstMealTime.addingTimeInterval(4 * 3600),
                endTime: firstMealTime.addingTimeInterval(5 * 3600),
                targetCalories: Int(Double(dailyCalories) * 0.20),
                targetMacros: MacroTargets(
                    protein: Int(Double(profile.calculateDailyProtein()) * 0.20),
                    carbs: Int(Double(profile.calculateDailyCarbs()) * 0.20),
                    fat: Int(Double(profile.calculateDailyFat()) * 0.20)
                ),
                purpose: .sustainedEnergy,
                flexibility: .flexible,
                dayDate: dayDate
            ),
            
            // Window 3: Dinner (40% of calories)
            MealWindow(
                startTime: lastMealTime.addingTimeInterval(-2 * 3600),
                endTime: lastMealTime,
                targetCalories: Int(Double(dailyCalories) * 0.40),
                targetMacros: MacroTargets(
                    protein: Int(Double(profile.calculateDailyProtein()) * 0.40),
                    carbs: Int(Double(profile.calculateDailyCarbs()) * 0.45),
                    fat: Int(Double(profile.calculateDailyFat()) * 0.40)
                ),
                purpose: .recovery,
                flexibility: .moderate,
                dayDate: dayDate
            )
        ]
    }
    
    // MARK: - Muscle Gain Windows (5-6 meals)
    
    private static func generateMuscleGainWindows(
        dayDate: Date,
        wakeTime: Date,
        lastMealTime: Date,
        profile: UserProfile
    ) -> [MealWindow] {
        
        let mealCount = 4
        let dailyCalories = profile.calculateDailyCalories()
        let caloriesPerMeal = dailyCalories / mealCount
        
        var windows: [MealWindow] = []
        let mealInterval = lastMealTime.timeIntervalSince(wakeTime) / Double(mealCount - 1)
        
        for i in 0..<mealCount {
            let startTime = wakeTime.addingTimeInterval(Double(i) * mealInterval)
            let endTime = startTime.addingTimeInterval(1.5 * 3600) // 1.5 hour windows
            
            let purpose: WindowPurpose = {
                switch i {
                case 0: return .metabolicBoost
                case 1: return .preworkout
                case 2: return .postworkout
                case mealCount - 1: return .recovery
                default: return .sustainedEnergy
                }
            }()
            
            windows.append(MealWindow(
                startTime: startTime,
                endTime: endTime,
                targetCalories: caloriesPerMeal,
                targetMacros: MacroTargets(
                    protein: profile.calculateDailyProtein() / mealCount,
                    carbs: profile.calculateDailyCarbs() / mealCount,
                    fat: profile.calculateDailyFat() / mealCount
                ),
                purpose: purpose,
                flexibility: .moderate,
                dayDate: dayDate
            ))
        }
        
        return windows
    }
    
    // MARK: - Performance Windows (4 strategic meals)
    
    private static func generatePerformanceWindows(
        dayDate: Date,
        wakeTime: Date,
        lastMealTime: Date,
        profile: UserProfile
    ) -> [MealWindow] {
        
        let dailyCalories = profile.calculateDailyCalories()
        
        return [
            // Morning fuel
            MealWindow(
                startTime: wakeTime.addingTimeInterval(1 * 3600),
                endTime: wakeTime.addingTimeInterval(2.5 * 3600),
                targetCalories: Int(Double(dailyCalories) * 0.25),
                targetMacros: MacroTargets(
                    protein: Int(Double(profile.calculateDailyProtein()) * 0.20),
                    carbs: Int(Double(profile.calculateDailyCarbs()) * 0.30),
                    fat: Int(Double(profile.calculateDailyFat()) * 0.20)
                ),
                purpose: .sustainedEnergy,
                flexibility: .moderate,
                dayDate: dayDate
            ),
            
            // Pre-workout
            MealWindow(
                startTime: wakeTime.addingTimeInterval(4 * 3600),
                endTime: wakeTime.addingTimeInterval(5 * 3600),
                targetCalories: Int(Double(dailyCalories) * 0.20),
                targetMacros: MacroTargets(
                    protein: Int(Double(profile.calculateDailyProtein()) * 0.15),
                    carbs: Int(Double(profile.calculateDailyCarbs()) * 0.25),
                    fat: Int(Double(profile.calculateDailyFat()) * 0.15)
                ),
                purpose: .preworkout,
                flexibility: .strict,
                dayDate: dayDate
            ),
            
            // Post-workout
            MealWindow(
                startTime: wakeTime.addingTimeInterval(7 * 3600),
                endTime: wakeTime.addingTimeInterval(8.5 * 3600),
                targetCalories: Int(Double(dailyCalories) * 0.30),
                targetMacros: MacroTargets(
                    protein: Int(Double(profile.calculateDailyProtein()) * 0.35),
                    carbs: Int(Double(profile.calculateDailyCarbs()) * 0.30),
                    fat: Int(Double(profile.calculateDailyFat()) * 0.25)
                ),
                purpose: .postworkout,
                flexibility: .strict,
                dayDate: dayDate
            ),
            
            // Recovery dinner
            MealWindow(
                startTime: lastMealTime.addingTimeInterval(-2 * 3600),
                endTime: lastMealTime,
                targetCalories: Int(Double(dailyCalories) * 0.25),
                targetMacros: MacroTargets(
                    protein: Int(Double(profile.calculateDailyProtein()) * 0.30),
                    carbs: Int(Double(profile.calculateDailyCarbs()) * 0.15),
                    fat: Int(Double(profile.calculateDailyFat()) * 0.40)
                ),
                purpose: .recovery,
                flexibility: .moderate,
                dayDate: dayDate
            )
        ]
    }
    
    // MARK: - Sleep Optimized Windows
    
    private static func generateSleepOptimizedWindows(
        dayDate: Date,
        wakeTime: Date,
        lastMealTime: Date,
        profile: UserProfile
    ) -> [MealWindow] {
        
        let dailyCalories = profile.calculateDailyCalories()
        // Earlier last meal for better sleep (4 hours before bed)
        let adjustedLastMeal = lastMealTime.addingTimeInterval(-1 * 3600)
        
        return [
            // Breakfast
            MealWindow(
                startTime: wakeTime.addingTimeInterval(1 * 3600),
                endTime: wakeTime.addingTimeInterval(2 * 3600),
                targetCalories: Int(Double(dailyCalories) * 0.30),
                targetMacros: MacroTargets(
                    protein: Int(Double(profile.calculateDailyProtein()) * 0.25),
                    carbs: Int(Double(profile.calculateDailyCarbs()) * 0.35),
                    fat: Int(Double(profile.calculateDailyFat()) * 0.25)
                ),
                purpose: .metabolicBoost,
                flexibility: .moderate,
                dayDate: dayDate
            ),
            
            // Lunch
            MealWindow(
                startTime: wakeTime.addingTimeInterval(5 * 3600),
                endTime: wakeTime.addingTimeInterval(6.5 * 3600),
                targetCalories: Int(Double(dailyCalories) * 0.35),
                targetMacros: MacroTargets(
                    protein: Int(Double(profile.calculateDailyProtein()) * 0.35),
                    carbs: Int(Double(profile.calculateDailyCarbs()) * 0.35),
                    fat: Int(Double(profile.calculateDailyFat()) * 0.35)
                ),
                purpose: .sustainedEnergy,
                flexibility: .moderate,
                dayDate: dayDate
            ),
            
            // Light afternoon snack
            MealWindow(
                startTime: wakeTime.addingTimeInterval(8 * 3600),
                endTime: wakeTime.addingTimeInterval(9 * 3600),
                targetCalories: Int(Double(dailyCalories) * 0.15),
                targetMacros: MacroTargets(
                    protein: Int(Double(profile.calculateDailyProtein()) * 0.15),
                    carbs: Int(Double(profile.calculateDailyCarbs()) * 0.10),
                    fat: Int(Double(profile.calculateDailyFat()) * 0.15)
                ),
                purpose: .focusBoost,
                flexibility: .flexible,
                dayDate: dayDate
            ),
            
            // Early, light dinner
            MealWindow(
                startTime: adjustedLastMeal.addingTimeInterval(-1.5 * 3600),
                endTime: adjustedLastMeal,
                targetCalories: Int(Double(dailyCalories) * 0.20),
                targetMacros: MacroTargets(
                    protein: Int(Double(profile.calculateDailyProtein()) * 0.25),
                    carbs: Int(Double(profile.calculateDailyCarbs()) * 0.20),
                    fat: Int(Double(profile.calculateDailyFat()) * 0.25)
                ),
                purpose: .sleepOptimization,
                flexibility: .strict,
                dayDate: dayDate
            )
        ]
    }
    
    // MARK: - Balanced Windows (Default)
    
    private static func generateBalancedWindows(
        dayDate: Date,
        wakeTime: Date,
        lastMealTime: Date,
        profile: UserProfile
    ) -> [MealWindow] {
        
        let mealCount = 4
        let dailyCalories = profile.calculateDailyCalories()
        
        if mealCount == 3 {
            // Traditional 3 meals
            return [
                // Breakfast
                MealWindow(
                        startTime: wakeTime.addingTimeInterval(1 * 3600),
                    endTime: wakeTime.addingTimeInterval(2.5 * 3600),
                    targetCalories: Int(Double(dailyCalories) * 0.30),
                    targetMacros: MacroTargets(
                        protein: Int(Double(profile.calculateDailyProtein()) * 0.25),
                        carbs: Int(Double(profile.calculateDailyCarbs()) * 0.35),
                        fat: Int(Double(profile.calculateDailyFat()) * 0.25)
                    ),
                    purpose: .metabolicBoost,
                    flexibility: .moderate,
                    dayDate: dayDate
                ),
                
                // Lunch
                MealWindow(
                        startTime: wakeTime.addingTimeInterval(5 * 3600),
                    endTime: wakeTime.addingTimeInterval(6.5 * 3600),
                    targetCalories: Int(Double(dailyCalories) * 0.35),
                    targetMacros: MacroTargets(
                        protein: Int(Double(profile.calculateDailyProtein()) * 0.35),
                        carbs: Int(Double(profile.calculateDailyCarbs()) * 0.35),
                        fat: Int(Double(profile.calculateDailyFat()) * 0.35)
                    ),
                    purpose: .sustainedEnergy,
                    flexibility: .moderate,
                    dayDate: dayDate
                ),
                
                // Dinner
                MealWindow(
                        startTime: lastMealTime.addingTimeInterval(-2 * 3600),
                    endTime: lastMealTime,
                    targetCalories: Int(Double(dailyCalories) * 0.35),
                    targetMacros: MacroTargets(
                        protein: Int(Double(profile.calculateDailyProtein()) * 0.40),
                        carbs: Int(Double(profile.calculateDailyCarbs()) * 0.30),
                        fat: Int(Double(profile.calculateDailyFat()) * 0.40)
                    ),
                    purpose: .recovery,
                    flexibility: .moderate,
                    dayDate: dayDate
                )
            ]
        } else {
            // 4+ meals - distribute evenly
            return generateMuscleGainWindows(
                dayDate: dayDate,
                wakeTime: wakeTime,
                lastMealTime: lastMealTime,
                profile: profile
            )
        }
    }
}

// MARK: - Helper Extensions

extension UserProfile {
    // MARK: - Daily Macro Calculations
    
    func calculateDailyCalories() -> Int {
        // Use the existing computed property from UserProfile
        return dailyCalorieTarget
    }
    
    func calculateDailyProtein() -> Int {
        // Use the existing computed property from UserProfile
        return dailyProteinTarget
    }
    
    func calculateDailyCarbs() -> Int {
        let dailyCalories = calculateDailyCalories()
        let proteinCalories = calculateDailyProtein() * 4
        let fatCalories = calculateDailyFat() * 9
        let remainingCalories = dailyCalories - proteinCalories - fatCalories
        
        return max(100, remainingCalories / 4) // Minimum 100g carbs
    }
    
    func calculateDailyFat() -> Int {
        // Use the existing computed property from UserProfile
        return dailyFatTarget
    }
    
    func typicalWakeTime(for date: Date) -> Date {
        // typicalWakeTime is already a Date, just adjust to the given date
        let calendar = Calendar.current
        let wakeComponents = calendar.dateComponents([.hour, .minute], from: typicalWakeTime)
        
        return calendar.date(bySettingHour: wakeComponents.hour ?? 7, 
                           minute: wakeComponents.minute ?? 0, 
                           second: 0, 
                           of: date) ?? date
    }
    
    func typicalSleepTime(for date: Date) -> Date {
        // typicalSleepTime is already a Date, just adjust to the given date
        let calendar = Calendar.current
        let sleepComponents = calendar.dateComponents([.hour, .minute], from: typicalSleepTime)
        
        var sleepDate = calendar.date(bySettingHour: sleepComponents.hour ?? 23, 
                                    minute: sleepComponents.minute ?? 0, 
                                    second: 0, 
                                    of: date) ?? date
        
        // If sleep time is before wake time (e.g., past midnight), add a day
        let wakeTime = typicalWakeTime(for: date)
        if sleepDate < wakeTime {
            sleepDate = calendar.date(byAdding: .day, value: 1, to: sleepDate) ?? sleepDate
        }
        
        return sleepDate
    }
}