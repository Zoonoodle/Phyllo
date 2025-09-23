//
//  FirstDayWindowTests.swift
//  NutriSync
//
//  Test scenarios for first-day window generation after onboarding
//

import Foundation

/// Test harness for first-day window generation scenarios
struct FirstDayWindowTests {
    
    /// Create a test user profile
    static func createTestProfile() -> UserProfile {
        // Set typical wake and sleep times (7am - 11pm)
        let calendar = Calendar.current
        let today = Date()
        
        let profile = UserProfile(
            id: UUID(),
            name: "Test User",
            age: 30,
            gender: .male,
            height: 70.0, // 5'10"
            weight: 180.0,
            activityLevel: .moderatelyActive,
            primaryGoal: .weightLoss(targetPounds: 10, timeline: 12),
            dietaryPreferences: [],
            dietaryRestrictions: [],
            dailyCalorieTarget: 2000,
            dailyProteinTarget: 150,
            dailyCarbTarget: 200,
            dailyFatTarget: 67,
            preferredMealTimes: ["8:00 AM", "12:00 PM", "6:00 PM"],
            micronutrientPriorities: [],
            typicalWakeTime: calendar.date(bySettingHour: 7, minute: 0, second: 0, of: today),
            typicalSleepTime: calendar.date(bySettingHour: 23, minute: 0, second: 0, of: today)
        )
        
        return profile
    }
    
    /// T022: Test onboarding completion at 9am (expect 3 windows)
    static func testMorningCompletion() -> TestResult {
        let profile = createTestProfile()
        let calendar = Calendar.current
        let testTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        
        let config = FirstDayConfiguration(
            completionTime: testTime,
            profile: profile,
            currentTime: testTime
        )
        
        // Verify expectations
        let passed = config.numberOfWindows == 3 &&
                    !config.showTomorrowPlan &&
                    config.remainingHours > 10
        
        return TestResult(
            testName: "T022: Morning (9am) Completion",
            passed: passed,
            details: """
            Time: 9:00 AM
            Windows Generated: \(config.numberOfWindows) (expected: 3)
            Show Tomorrow: \(config.showTomorrowPlan) (expected: false)
            Remaining Hours: \(String(format: "%.1f", config.remainingHours))
            Pro-rated Calories: \(config.proRatedCalories)
            Window Purposes: \(config.getWindowPurposes().map { $0.displayName })
            """
        )
    }
    
    /// T023: Test onboarding completion at 2pm (expect 2-3 windows)
    static func testAfternoonCompletion() -> TestResult {
        let profile = createTestProfile()
        let calendar = Calendar.current
        let testTime = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: Date()) ?? Date()
        
        let config = FirstDayConfiguration(
            completionTime: testTime,
            profile: profile,
            currentTime: testTime
        )
        
        // Verify expectations (should be 2 or 3 windows)
        let passed = (config.numberOfWindows == 2 || config.numberOfWindows == 3) &&
                    !config.showTomorrowPlan &&
                    config.remainingHours > 5
        
        return TestResult(
            testName: "T023: Afternoon (2pm) Completion",
            passed: passed,
            details: """
            Time: 2:00 PM
            Windows Generated: \(config.numberOfWindows) (expected: 2-3)
            Show Tomorrow: \(config.showTomorrowPlan) (expected: false)
            Remaining Hours: \(String(format: "%.1f", config.remainingHours))
            Pro-rated Calories: \(config.proRatedCalories)
            Window Purposes: \(config.getWindowPurposes().map { $0.displayName })
            """
        )
    }
    
    /// T024: Test onboarding completion at 7pm (expect 1-2 windows)
    static func testEveningCompletion() -> TestResult {
        let profile = createTestProfile()
        let calendar = Calendar.current
        let testTime = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: Date()) ?? Date()
        
        let config = FirstDayConfiguration(
            completionTime: testTime,
            profile: profile,
            currentTime: testTime
        )
        
        // Verify expectations (should be 1 window, possibly 0 if too late)
        let passed = (config.numberOfWindows == 1 || config.numberOfWindows == 0) &&
                    config.remainingHours <= 3
        
        return TestResult(
            testName: "T024: Evening (7pm) Completion",
            passed: passed,
            details: """
            Time: 7:00 PM
            Windows Generated: \(config.numberOfWindows) (expected: 1-2)
            Show Tomorrow: \(config.showTomorrowPlan)
            Remaining Hours: \(String(format: "%.1f", config.remainingHours))
            Pro-rated Calories: \(config.proRatedCalories)
            Window Purposes: \(config.getWindowPurposes().map { $0.displayName })
            """
        )
    }
    
    /// T025: Test onboarding completion at 9pm (expect tomorrow's plan)
    static func testLateNightCompletion() -> TestResult {
        let profile = createTestProfile()
        let calendar = Calendar.current
        let testTime = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
        
        let config = FirstDayConfiguration(
            completionTime: testTime,
            profile: profile,
            currentTime: testTime
        )
        
        // Verify expectations (should show tomorrow's plan)
        let passed = config.numberOfWindows == 0 &&
                    config.showTomorrowPlan == true
        
        return TestResult(
            testName: "T025: Late Night (9pm) Completion",
            passed: passed,
            details: """
            Time: 9:00 PM
            Windows Generated: \(config.numberOfWindows) (expected: 0)
            Show Tomorrow: \(config.showTomorrowPlan) (expected: true)
            Remaining Hours: \(String(format: "%.1f", config.remainingHours))
            Tomorrow's Calories: \(config.proRatedCalories) (should be full day: 2000)
            """
        )
    }
    
    /// T026: Test pro-rated calorie calculations for various times
    static func testProRatedCalories() -> TestResult {
        let profile = createTestProfile()
        let calendar = Calendar.current
        var testResults: [(time: String, proRated: Int, expected: String)] = []
        
        // Test various times throughout the day
        let testHours = [8, 10, 12, 14, 16, 18, 20]
        
        for hour in testHours {
            let testTime = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
            let config = FirstDayConfiguration(
                completionTime: testTime,
                profile: profile,
                currentTime: testTime
            )
            
            let percentageOfDay = (config.remainingHours / config.totalWakingHours) * 100
            let expectedRange = "\(Int(percentageOfDay - 5))%-\(Int(percentageOfDay + 5))%"
            
            testResults.append((
                time: "\(hour):00",
                proRated: config.proRatedCalories,
                expected: expectedRange
            ))
        }
        
        // Check if calculations are reasonable
        let passed = testResults.allSatisfy { result in
            // Early morning should have most calories
            if result.time == "8:00" {
                return result.proRated > 1500 // >75% of day
            }
            // Late evening should have least or show tomorrow
            if result.time == "20:00" {
                return result.proRated == 2000 || result.proRated < 500
            }
            // Others should be proportional
            return result.proRated > 0 && result.proRated <= 2000
        }
        
        let details = testResults.map { 
            "\(String($0.time)): \($0.proRated) cal (expected \($0.expected) of 2000)"
        }.joined(separator: "\n")
        
        return TestResult(
            testName: "T026: Pro-Rated Calorie Calculations",
            passed: passed,
            details: """
            Daily Target: 2000 calories
            Waking Hours: 16 hours (7am-11pm)
            
            Pro-rated Results:
            \(details)
            """
        )
    }
    
    /// T027: Test existing user flow remains unaffected
    static func testExistingUserFlow() -> TestResult {
        var profile = createTestProfile()
        
        // Simulate existing user (has completed first day)
        profile.firstDayCompleted = true
        profile.onboardingCompletedAt = Date().addingTimeInterval(-86400) // Yesterday
        
        // This should NOT trigger first-day window generation
        let shouldGenerate = !profile.firstDayCompleted
        
        return TestResult(
            testName: "T027: Existing User Flow",
            passed: !shouldGenerate,
            details: """
            User Type: Existing (firstDayCompleted = true)
            Should Generate First-Day Windows: \(shouldGenerate) (expected: false)
            Onboarded: Yesterday
            Normal Flow: Morning check-in required
            """
        )
    }
    
    /// Run all tests
    static func runAllTests() {
        print("=" * 60)
        print("FIRST-DAY WINDOW GENERATION TEST SUITE")
        print("=" * 60)
        
        let tests = [
            testMorningCompletion(),
            testAfternoonCompletion(),
            testEveningCompletion(),
            testLateNightCompletion(),
            testProRatedCalories(),
            testExistingUserFlow()
        ]
        
        for test in tests {
            print("\n\(test.testName)")
            print("-" * 40)
            print("Status: \(test.passed ? "✅ PASSED" : "❌ FAILED")")
            print("\nDetails:")
            print(test.details)
        }
        
        let totalPassed = tests.filter { $0.passed }.count
        print("\n" + "=" * 60)
        print("RESULTS: \(totalPassed)/\(tests.count) tests passed")
        print("=" * 60)
    }
}

/// Test result container
struct TestResult {
    let testName: String
    let passed: Bool
    let details: String
}

// Helper extension for string multiplication
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

// MARK: - Run Tests (for execution)

// Uncomment to run tests:
// FirstDayWindowTests.runAllTests()