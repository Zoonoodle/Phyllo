import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseAppCheck
import FirebaseAI

class FirebaseConfig {
    static let shared = FirebaseConfig()
    
    private init() {}
    
    func configure() {
        // Check if GoogleService-Info.plist exists
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              FileManager.default.fileExists(atPath: path) else {
            Task { @MainActor in
                DebugLogger.shared.warning("Firebase not configured - GoogleService-Info.plist not found")
                DebugLogger.shared.warning("Using mock VertexAI service. See FIREBASE_SETUP_GUIDE.md for setup instructions")
            }
            print("⚠️ Firebase not configured - GoogleService-Info.plist not found")
            print("⚠️ Using mock VertexAI service. See FIREBASE_SETUP_GUIDE.md for setup instructions")
            return
        }
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Set up App Check for security (optional but recommended)
        // This helps protect your Vertex AI quota from abuse
        #if DEBUG
        // Use debug provider for simulator/testing
        let providerFactory = AppCheckDebugProviderFactory()
        #else
        // Use App Attest for production
        let providerFactory = CustomAppCheckProviderFactory()
        #endif
        
        AppCheck.setAppCheckProviderFactory(providerFactory)
        
        // Configure Firestore settings
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: NSNumber(value: 100 * 1024 * 1024)) // 100MB cache
        Firestore.firestore().settings = settings
        
        // Enable offline persistence
        Firestore.firestore().settings.isPersistenceEnabled = true
        
        // Sign in anonymously to enable Storage access
        Task {
            do {
                if Auth.auth().currentUser == nil {
                    let result = try await Auth.auth().signInAnonymously()
                    await MainActor.run {
                        DebugLogger.shared.firebase("Signed in anonymously with uid: \(result.user.uid)")
                    }
                    print("✅ Anonymous auth successful: \(result.user.uid)")
                }
            } catch {
                await MainActor.run {
                    DebugLogger.shared.error("Anonymous auth failed: \(error)")
                }
                print("❌ Anonymous auth failed: \(error)")
            }
        }
        
        Task { @MainActor in
            DebugLogger.shared.firebase("Firebase configured successfully")
            DebugLogger.shared.info("App Check: \(AppCheck.appCheck().isTokenAutoRefreshEnabled ? "Enabled" : "Disabled")")
            DebugLogger.shared.info("Firestore offline persistence: Enabled")
        }
        print("✅ Firebase configured successfully")
    }
}

// Custom App Check provider for production
class CustomAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        if #available(iOS 14.0, *) {
            return AppAttestProvider(app: app)
        } else {
            // Fallback for older iOS versions
            return DeviceCheckProvider(app: app)
        }
    }
}
