// Temporary script to reset grace period in UserDefaults for testing
// Run this to clear grace period data and restart the 24-hour trial

import Foundation

// Clear all grace period data
UserDefaults.standard.removeObject(forKey: "gracePeriod_isActive")
UserDefaults.standard.removeObject(forKey: "gracePeriod_scans")
UserDefaults.standard.removeObject(forKey: "gracePeriod_gens")
UserDefaults.standard.removeObject(forKey: "gracePeriod_seenPaywall")
UserDefaults.standard.removeObject(forKey: "gracePeriod_endDate")

print("✅ Grace period reset in UserDefaults")
print("⚠️  You'll also need to delete the user's grace period document in Firestore:")
print("   Path: users/{userId}/subscription/gracePeriod")
