12.1.0 - [FirebaseCore][I-COR000008] The project's Bundle ID is inconsistent with either the Bundle ID in 'GoogleService-Info.plist', or the Bundle ID in the options if you are using a customized options. To ensure that everything can be configured correctly, you may need to make the Bundle IDs consistent. To continue with this plist file, you may change your app's bundle identifier to 'com.NutriSync.NutriSync'. Or you can download a new configuration file that matches your bundle identifier from https://console.firebase.google.com/ and replace the current one.
12.1.0 - [GoogleUtilities/AppDelegateSwizzler][I-SWZ001014] App Delegate does not conform to UIApplicationDelegate protocol.
✅ Firebase configured successfully
🔥 Using Firebase Data Provider
📱 Notification categories configured
load_eligibility_plist: Failed to open /Users/brennenprice/Library/Developer/CoreSimulator/Devices/FD0451A9-AC08-4E59-AD0A-977B8E9D6E56/data/Containers/Data/Application/892CD969-601C-4E54-96DD-CDB3DF79D3A1/private/var/db/eligibilityd/eligibility.plist: No such file or directory(2)

🟧 [06:49:50.297] 🔥 FIREBASE
📍 FirebaseConfig.configure():51
💬 Firebase configured successfully
─────────────────────────────────────────

⚪ [06:49:50.298] ℹ️ INFO
📍 FirebaseConfig.configure():52
💬 App Check: Enabled
─────────────────────────────────────────

⚪ [06:49:50.298] ℹ️ INFO
📍 FirebaseConfig.configure():53
💬 Firestore offline persistence: Enabled
─────────────────────────────────────────

🟩 [06:49:50.298] 💾 DATA
📍 DataProviderProtocol.configure(with:):388
💬 DataSourceProvider configured with: FirebaseDataProvider
─────────────────────────────────────────

🟩 [06:49:50.298] 💾 DATA
📍 DataProviderProtocol.cleanupStaleData():401
💬 Starting stale data cleanup
─────────────────────────────────────────
❌ Failed to register for remote notifications: Error Domain=NSCocoaErrorDomain Code=3000 "no valid “aps-environment” entitlement string found for application" UserInfo={NSLocalizedDescription=no valid “aps-environment” entitlement string found for application}

🟩 [06:49:50.324] 💾 DATA
📍 FirebaseDataProvider.getUserProfile():495
💬 Fetching user profile from Firebase
─────────────────────────────────────────

⬜ [06:49:50.325] 🔔 NOTIF
📍 NotificationManager.checkAuthorizationStatus():62
💬 Current notification status: 3
─────────────────────────────────────────

⚪ [06:49:50.325] ℹ️ INFO
📍 DataProviderProtocol.fromFirestore(_:):292
💬 Firestore window start timestamp: seconds=1756158300, date=2025-08-25 21:45:00 +0000
─────────────────────────────────────────

⚪ [06:49:50.325] ℹ️ INFO
📍 DataProviderProtocol.fromFirestore(_:):292
💬 Firestore window start timestamp: seconds=1756136700, date=2025-08-25 15:45:00 +0000
─────────────────────────────────────────

⚪ [06:49:50.326] ℹ️ INFO
📍 DataProviderProtocol.fromFirestore(_:):292
💬 Firestore window start timestamp: seconds=1756122300, date=2025-08-25 11:45:00 +0000
─────────────────────────────────────────

⚪ [06:49:50.326] ℹ️ INFO
📍 DataProviderProtocol.fromFirestore(_:):292
💬 Firestore window start timestamp: seconds=1756168200, date=2025-08-26 00:30:00 +0000
─────────────────────────────────────────

⚪ [06:49:50.326] ℹ️ INFO
📍 DataProviderProtocol.fromFirestore(_:):292
💬 Firestore window start timestamp: seconds=1756147500, date=2025-08-25 18:45:00 +0000
─────────────────────────────────────────

⬜ [06:49:50.335] 🔔 NOTIF
📍 NotificationManager.cancelWindowNotifications():327
💬 Cancelled 6 window notifications
─────────────────────────────────────────
12.1.0 - [FirebaseFirestore][I-FST000001] AppCheck failed: 'The operation couldn’t be completed. The attestation provider DeviceCheckProvider is not supported on current platform and OS version.'
12.1.0 - [FirebaseFirestore][I-FST000001] AppCheck failed: 'The operation couldn’t be completed. The attestation provider DeviceCheckProvider is not supported on current platform and OS version.'

⬜ [06:49:50.350] 🔔 NOTIF
📍 NotificationManager.scheduleNotification(id:title:body:date:category:userInfo:):284
💬 Scheduled: Active Meal Window at 2025-08-25 12:15:00 +0000
─────────────────────────────────────────

⬜ [06:49:50.378] 🔔 NOTIF
📍 NotificationManager.scheduleNotification(id:title:body:date:category:userInfo:):284
💬 Scheduled: Breakfast Window Ending Soon at 2025-08-25 13:00:00 +0000
─────────────────────────────────────────

⬜ [06:49:50.386] 🔔 NOTIF
📍 NotificationManager.scheduleNotification(id:title:body:date:category:userInfo:):284
💬 Scheduled: Breakfast Window Starting Soon at 2025-08-25 15:30:00 +0000
─────────────────────────────────────────

⬜ [06:49:50.393] 🔔 NOTIF
📍 NotificationManager.scheduleNotification(id:title:body:date:category:userInfo:):284
💬 Scheduled: Lunch Window Starting Soon at 2025-08-25 18:30:00 +0000
─────────────────────────────────────────

⬜ [06:49:50.401] 🔔 NOTIF
📍 NotificationManager.scheduleNotification(id:title:body:date:category:userInfo:):284
💬 Scheduled: Snack Window Starting Soon at 2025-08-25 21:30:00 +0000
─────────────────────────────────────────

⬜ [06:49:50.412] 🔔 NOTIF
📍 NotificationManager.scheduleNotification(id:title:body:date:category:userInfo:):284
💬 Scheduled: Dinner Window Starting Soon at 2025-08-26 00:15:00 +0000
─────────────────────────────────────────

🟢 [06:49:50.412] ✅ SUCCESS
📍 NotificationManager.scheduleWindowNotifications(for:):151
💬 Scheduled notifications for 5 windows
─────────────────────────────────────────

🟢 [06:49:50.568] ✅ SUCCESS
📍 FirebaseDataProvider.getUserProfile():502
💬 User profile found in Firebase
─────────────────────────────────────────

🟩 [06:49:50.568] 💾 DATA
📍 FirebaseDataProvider.getAnalyzingMeals():100
💬 Loaded 0 analyzing meals
─────────────────────────────────────────

🟢 [06:49:50.568] ✅ SUCCESS
📍 DataProviderProtocol.cleanupStaleData():406
💬 Stale data cleanup completed. Found 0 analyzing meals
─────────────────────────────────────────

🟩 [06:49:50.574] 💾 DATA
📍 FirebaseDataProvider.getMeals(for:):50
💬 FirebaseDataProvider.getMeals for date: 2025-08-25
─────────────────────────────────────────

🟧 [06:49:50.574] 🔥 FIREBASE
📍 FirebaseDataProvider.getMeals(for:):67
💬 Retrieved 0 meals from Firebase
─────────────────────────────────────────

🟩 [06:49:50.575] 💾 DATA
📍 ScheduleViewModel.loadInitialData():232
💬 Loaded 0 meals for today
─────────────────────────────────────────

🟧 [06:49:50.575] 🔥 FIREBASE
📍 FirebaseDataProvider.getWindows(for:):218
💬 Querying windows for dayDate: 2025-08-25 05:00:00 +0000
─────────────────────────────────────────

🟧 [06:49:50.576] 🔥 FIREBASE
📍 FirebaseDataProvider.getWindows(for:):230
💬 Found 5 documents in windows collection
─────────────────────────────────────────

🟧 [06:49:50.576] 🔥 FIREBASE
📍 FirebaseDataProvider.getWindows(for:):232
💬 First document data: ["type": snack, "targetProtein": 20, "id": 11B308FD-1ACF-4365-9836-B95A5A7FCC0B, "startTime": <FIRTimestamp: seconds=1756158300 nanoseconds=0>, "targetCarbs": 30, "purpose": Sustained Energy, "name": Afternoon Optimizer, "endTime": <FIRTimestamp: seconds=1756161900 nanoseconds=0>, "tips": <__NSArrayM 0x600000c78c30>(
Choose snacks that are high in protein and fiber to promote satiety.,
Avoid processed snacks that are high in sugar and unhealthy fats.,
Drink plenty of water to stay hydrated and reduce hunger.
)
, "micronutrientFocus": <__NSArrayM 0x600000c78c90>(
Selenium,
Copper,
Vitamin E
)
, "isMarkedAsFasted": 0, "targetCalories": 300, "rationale": Prevents cravings and provides a sustained energy boost to power through the afternoon, enhancing focus and productivity., "targetFat": 10, "flexibility": Moderate, "foodSuggestions": <__NSArrayM 0x600000c78a20>(
Cottage cheese with pineapple,
Trail mix with nuts, seeds, and dried fruit,
Hard-boiled eggs with whole-wheat crackers
)
, "dayDate": <FIRTimestamp: seconds=1756098000 nanoseconds=0>]
─────────────────────────────────────────

⚪ [06:49:50.576] ℹ️ INFO
📍 DataProviderProtocol.fromFirestore(_:):292
💬 Firestore window start timestamp: seconds=1756158300, date=2025-08-25 21:45:00 +0000
─────────────────────────────────────────

⚪ [06:49:50.576] ℹ️ INFO
📍 DataProviderProtocol.fromFirestore(_:):292
💬 Firestore window start timestamp: seconds=1756136700, date=2025-08-25 15:45:00 +0000
─────────────────────────────────────────

⚪ [06:49:50.576] ℹ️ INFO
📍 DataProviderProtocol.fromFirestore(_:):292
💬 Firestore window start timestamp: seconds=1756122300, date=2025-08-25 11:45:00 +0000
─────────────────────────────────────────

⚪ [06:49:50.576] ℹ️ INFO
📍 DataProviderProtocol.fromFirestore(_:):292
💬 Firestore window start timestamp: seconds=1756168200, date=2025-08-26 00:30:00 +0000
─────────────────────────────────────────

⚪ [06:49:50.576] ℹ️ INFO
📍 DataProviderProtocol.fromFirestore(_:):292
💬 Firestore window start timestamp: seconds=1756147500, date=2025-08-25 18:45:00 +0000
─────────────────────────────────────────

🟧 [06:49:50.576] 🔥 FIREBASE
📍 FirebaseDataProvider.getWindows(for:):251
💬 Successfully parsed 5 windows from Firebase for date: 2025-08-25 11:49:50 +0000
─────────────────────────────────────────

🟩 [06:49:50.576] 💾 DATA
📍 ScheduleViewModel.loadInitialData():242
💬 Loaded 5 windows for today
─────────────────────────────────────────

🟩 [06:49:50.577] 💾 DATA
📍 FirebaseDataProvider.getAnalyzingMeals():100
💬 Loaded 0 analyzing meals
─────────────────────────────────────────

🟡 [06:49:50.879] ⚠️ WARN
📍 TimelineView.buildTimeline(proxy:):241
💬 TimelineView.onAppear called
─────────────────────────────────────────

⚪ [06:49:50.879] ℹ️ INFO
📍 TimelineView.buildTimeline(proxy:):242
💬 Current time: 2025-08-25 11:49:50 +0000
─────────────────────────────────────────

⚪ [06:49:50.880] ℹ️ INFO
📍 TimelineView.buildTimeline(proxy:):243
💬 Hours array: [4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22]
─────────────────────────────────────────

⚪ [06:49:50.880] ℹ️ INFO
📍 TimelineView.buildTimeline(proxy:):244
💬 Calculated hour layouts count: 19
─────────────────────────────────────────

⚪ [06:49:50.880] ℹ️ INFO
📍 TimelineView.buildTimeline(proxy:):245
💬 Windows count: 5
─────────────────────────────────────────

🟡 [06:49:50.880] ⚠️ WARN
📍 ScheduleViewModel.timelineHours:54
💬 Window 'Sunrise Refuel' hour extraction:
─────────────────────────────────────────

🟡 [06:49:50.880] ⚠️ WARN
📍 ScheduleViewModel.timelineHours:55
💬   startTime Date: 2025-08-25 11:45:00 +0000
─────────────────────────────────────────

🟡 [06:49:50.881] ⚠️ WARN
📍 ScheduleViewModel.timelineHours:56
💬   formattedTimeRange: 6:45 AM - 8:15 AM
─────────────────────────────────────────

🟡 [06:49:50.881] ⚠️ WARN
📍 ScheduleViewModel.timelineHours:57
💬   extracted startHour: 6
─────────────────────────────────────────

🟡 [06:49:50.881] ⚠️ WARN
📍 ScheduleViewModel.timelineHours:58
💬   extracted endHour: 8
─────────────────────────────────────────

🟡 [06:49:50.881] ⚠️ WARN
📍 ScheduleViewModel.timelineHours:59
💬   calendar timezone: America/Chicago
─────────────────────────────────────────

🟡 [06:49:50.881] ⚠️ WARN
📍 ScheduleViewModel.timelineHours:54
💬 Window 'Mid-Morning Power Up' hour extraction:
─────────────────────────────────────────

🟡 [06:49:50.881] ⚠️ WARN
📍 ScheduleViewModel.timelineHours:55
💬   startTime Date: 2025-08-25 15:45:00 +0000
─────────────────────────────────────────

🟡 [06:49:50.881] ⚠️ WARN
📍 ScheduleViewModel.timelineHours:56
💬   formattedTimeRange: 10:45 AM - 11:45 AM
─────────────────────────────────────────

🟡 [06:49:50.881] ⚠️ WARN
📍 ScheduleViewModel.timelineHours:57
💬   extracted startHour: 10
─────────────────────────────────────────

🟡 [06:49:50.881] ⚠️ WARN
📍 ScheduleViewModel.timelineHours:58
💬   extracted endHour: 11
─────────────────────────────────────────

🟡 [06:49:50.881] ⚠️ WARN
📍 ScheduleViewModel.timelineHours:59
💬   calendar timezone: America/Chicago
─────────────────────────────────────────

🟡 [06:49:50.881] ⚠️ WARN
📍 ScheduleViewModel.timelineHours:54
💬 Window 'Lunchtime Recharge' hour extraction:
─────────────────────────────────────────

🟡 [06:49:50.881] ⚠️ WARN
📍 ScheduleViewModel.timelineHours:55
💬   startTime Date: 2025-08-25 18:45:00 +0000
─────────────────────────────────────────

🟡 [06:49:50.881] ⚠️ WARN
📍 ScheduleViewModel.timelineHours:56
💬   formattedTimeRange: 1:45 PM - 2:45 PM
─────────────────────────────────────────

🟡 [06:49:50.882] ⚠️ WARN
📍 ScheduleViewModel.timelineHours:57
💬   extracted startHour: 13
─────────────────────────────────────────

🟡 [06:49:50.882] ⚠️ WARN
📍 ScheduleViewModel.timelineHours:58
💬   extracted endHour: 14
─────────────────────────────────────────

🟡 [06:49:50.882] ⚠️ WARN
📍 ScheduleViewModel.timelineHours:59
💬   calendar timezone: America/Chicago
─────────────────────────────────────────

🟡 [06:49:50.882] ⚠️ WARN
📍 ScheduleViewModel.timelineHours:54
💬 Window 'Afternoon Optimizer' hour extraction:
─────────────────────────────────────────

🟡 [06:49:50.882] ⚠️ WARN
📍 ScheduleViewModel.timelineHours:55
💬   startTime Date: 2025-08-25 21:45:00 +0000
─────────────────────────────────────────

🟡 [06:49:50.883] ⚠️ WARN
📍 ScheduleViewModel.timelineHours:56
💬   formattedTimeRange: 4:45 PM - 5:45 PM
─────────────────────────────────────────

🟡 [06:49:50.883] ⚠️ WARN
📍 ScheduleViewModel.timelineHours:57
💬   extracted startHour: 16
─────────────────────────────────────────

🟡 [06:49:50.883] ⚠️ WARN
📍 ScheduleViewModel.timelineHours:58
💬   extracted endHour: 17
─────────────────────────────────────────

🟡 [06:49:50.883] ⚠️ WARN
📍 ScheduleViewModel.timelineHours:59
💬   calendar timezone: America/Chicago
─────────────────────────────────────────

🟡 [06:49:50.883] ⚠️ WARN
📍 ScheduleViewModel.timelineHours:54
💬 Window 'Evening Recovery Fuel' hour extraction:
─────────────────────────────────────────

🟡 [06:49:50.883] ⚠️ WARN
📍 ScheduleViewModel.timelineHours:55
💬   startTime Date: 2025-08-26 00:30:00 +0000
─────────────────────────────────────────

🟡 [06:49:50.883] ⚠️ WARN
📍 ScheduleViewModel.timelineHours:56
💬   formattedTimeRange: 7:30 PM - 8:30 PM
─────────────────────────────────────────

🟡 [06:49:50.883] ⚠️ WARN
📍 ScheduleViewModel.timelineHours:57
💬   extracted startHour: 19
─────────────────────────────────────────

🟡 [06:49:50.884] ⚠️ WARN
📍 ScheduleViewModel.timelineHours:58
💬   extracted endHour: 20
─────────────────────────────────────────

🟡 [06:49:50.884] ⚠️ WARN
📍 ScheduleViewModel.timelineHours:59
💬   calendar timezone: America/Chicago
─────────────────────────────────────────

⚪ [06:49:50.884] ℹ️ INFO
📍 ScheduleViewModel.timelineHours:153
💬 Timeline hours: 4 to 22
─────────────────────────────────────────

⚪ [06:49:50.884] ℹ️ INFO
📍 ScheduleViewModel.timelineHours:154
💬 Windows: 5, Meals: 0
─────────────────────────────────────────

⚪ [06:49:50.884] ℹ️ INFO
📍 ScheduleViewModel.timelineHours:157
💬 First window starts at: 6:45 AM - 8:15 AM
─────────────────────────────────────────

⚪ [06:49:50.884] ℹ️ INFO
📍 TimelineLayoutManager.calculateWindowLayout(window:hourLayouts:viewModel:):245
💬 Window 'Sunrise Refuel' times:
─────────────────────────────────────────

⚪ [06:49:50.884] ℹ️ INFO
📍 TimelineLayoutManager.calculateWindowLayout(window:hourLayouts:viewModel:):246
💬   Start UTC: 2025-08-25 11:45:00 +0000
─────────────────────────────────────────

⚪ [06:49:50.884] ℹ️ INFO
📍 TimelineLayoutManager.calculateWindowLayout(window:hourLayouts:viewModel:):247
💬   Start Local Hour: 6:45
─────────────────────────────────────────

⚪ [06:49:50.885] ℹ️ INFO
📍 TimelineLayoutManager.calculateWindowLayout(window:hourLayouts:viewModel:):248
💬   End UTC: 2025-08-25 13:15:00 +0000
─────────────────────────────────────────

⚪ [06:49:50.885] ℹ️ INFO
📍 TimelineLayoutManager.calculateWindowLayout(window:hourLayouts:viewModel:):249
💬   End Local Hour: 8:15
─────────────────────────────────────────

⚪ [06:49:50.885] ℹ️ INFO
📍 TimelineLayoutManager.calculateWindowLayout(window:hourLayouts:viewModel:):250
💬   FormattedRange: 6:45 AM - 8:15 AM
─────────────────────────────────────────

⚪ [06:49:50.885] ℹ️ INFO
📍 TimelineLayoutManager.calculateWindowLayout(window:hourLayouts:viewModel:):269
💬 Hour 6 layout found:
─────────────────────────────────────────

⚪ [06:49:50.886] ℹ️ INFO
📍 TimelineLayoutManager.calculateWindowLayout(window:hourLayouts:viewModel:):270
💬   - Index in hours: 2
─────────────────────────────────────────

⚪ [06:49:50.886] ℹ️ INFO
📍 TimelineLayoutManager.calculateWindowLayout(window:hourLayouts:viewModel:):271
💬   - yOffset: 120.0
─────────────────────────────────────────

⚪ [06:49:50.886] ℹ️ INFO
📍 TimelineLayoutManager.calculateWindowLayout(window:hourLayouts:viewModel:):272
💬   - height: 120.0
─────────────────────────────────────────

⚪ [06:49:50.886] ℹ️ INFO
📍 TimelineLayoutManager.calculateWindowLayout(window:hourLayouts:viewModel:):245
💬 Window 'Mid-Morning Power Up' times:
─────────────────────────────────────────

⚪ [06:49:50.886] ℹ️ INFO
📍 TimelineLayoutManager.calculateWindowLayout(window:hourLayouts:viewModel:):246
💬   Start UTC: 2025-08-25 15:45:00 +0000
─────────────────────────────────────────

⚪ [06:49:50.886] ℹ️ INFO
📍 TimelineLayoutManager.calculateWindowLayout(window:hourLayouts:viewModel:):247
💬   Start Local Hour: 10:45
─────────────────────────────────────────

⚪ [06:49:50.886] ℹ️ INFO
📍 TimelineLayoutManager.calculateWindowLayout(window:hourLayouts:viewModel:):248
💬   End UTC: 2025-08-25 16:45:00 +0000
─────────────────────────────────────────

⚪ [06:49:50.886] ℹ️ INFO
📍 TimelineLayoutManager.calculateWindowLayout(window:hourLayouts:viewModel:):249
💬   End Local Hour: 11:45
─────────────────────────────────────────

⚪ [06:49:50.887] ℹ️ INFO
📍 TimelineLayoutManager.calculateWindowLayout(window:hourLayouts:viewModel:):250
💬   FormattedRange: 10:45 AM - 11:45 AM
─────────────────────────────────────────

⚪ [06:49:50.887] ℹ️ INFO
📍 TimelineLayoutManager.calculateWindowLayout(window:hourLayouts:viewModel:):269
💬 Hour 10 layout found:
─────────────────────────────────────────

⚪ [06:49:50.887] ℹ️ INFO
📍 TimelineLayoutManager.calculateWindowLayout(window:hourLayouts:viewModel:):270
💬   - Index in hours: 6
─────────────────────────────────────────

⚪ [06:49:50.887] ℹ️ INFO
📍 TimelineLayoutManager.calculateWindowLayout(window:hourLayouts:viewModel:):271
💬   - yOffset: 540.0
─────────────────────────────────────────

⚪ [06:49:50.887] ℹ️ INFO
📍 TimelineLayoutManager.calculateWindowLayout(window:hourLayouts:viewModel:):272
💬   - height: 64.0
─────────────────────────────────────────

⚪ [06:49:50.887] ℹ️ INFO
📍 TimelineLayoutManager.calculateWindowLayout(window:hourLayouts:viewModel:):245
💬 Window 'Lunchtime Recharge' times:
─────────────────────────────────────────

⚪ [06:49:50.887] ℹ️ INFO
📍 TimelineLayoutManager.calculateWindowLayout(window:hourLayouts:viewModel:):246
💬   Start UTC: 2025-08-25 18:45:00 +0000
─────────────────────────────────────────

⚪ [06:49:50.888] ℹ️ INFO
📍 TimelineLayoutManager.calculateWindowLayout(window:hourLayouts:viewModel:):247
💬   Start Local Hour: 13:45
─────────────────────────────────────────

⚪ [06:49:50.888] ℹ️ INFO
📍 TimelineLayoutManager.calculateWindowLayout(window:hourLayouts:viewModel:):248
💬   End UTC: 2025-08-25 19:45:00 +0000
─────────────────────────────────────────

⚪ [06:49:50.888] ℹ️ INFO
📍 TimelineLayoutManager.calculateWindowLayout(window:hourLayouts:viewModel:):249
💬   End Local Hour: 14:45
─────────────────────────────────────────

⚪ [06:49:50.888] ℹ️ INFO
📍 TimelineLayoutManager.calculateWindowLayout(window:hourLayouts:viewModel:):250
💬   FormattedRange: 1:45 PM - 2:45 PM
─────────────────────────────────────────

⚪ [06:49:50.888] ℹ️ INFO
📍 TimelineLayoutManager.calculateWindowLayout(window:hourLayouts:viewModel:):269
💬 Hour 13 layout found:
─────────────────────────────────────────
