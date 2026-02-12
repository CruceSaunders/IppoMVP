import Foundation
import Combine

// MARK: - Firebase Service (Stubbed for now - enable when Firebase products linked)
// TODO: Add FirebaseCore, FirebaseAuth, FirebaseFirestore imports when linked to target

/// Firebase service for persistent cloud data storage
/// Currently uses local fallback - will use Firestore when Firebase products are linked
@MainActor
final class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    @Published var currentUserId: String?
    @Published var isAuthenticated = false
    
    // Use UserDefaults as fallback until Firebase is properly configured
    private let defaults = UserDefaults.standard
    private let userDataKey = "firebase_user_data_backup"
    private let dailyRewardKey = "firebase_daily_reward_backup"
    
    private init() {
        // Generate a pseudo-user ID for local storage
        if let existingId = defaults.string(forKey: "local_user_id") {
            currentUserId = existingId
        } else {
            let newId = UUID().uuidString
            defaults.set(newId, forKey: "local_user_id")
            currentUserId = newId
        }
        isAuthenticated = true
    }
    
    // MARK: - Authentication (Stubbed)
    
    func ensureAuthenticated() async throws {
        // Already "authenticated" with local fallback
        isAuthenticated = true
    }
    
    func getUserId() async throws -> String {
        guard let userId = currentUserId else {
            throw FirebaseError.notAuthenticated
        }
        return userId
    }
    
    // MARK: - User Data Operations (Local Fallback)
    
    func saveUserData(_ userData: UserData) async throws {
        let data = SaveableUserData(
            profile: userData.profile,
            ownedPets: userData.ownedPets,
            abilities: userData.abilities,
            inventory: userData.inventory,
            coins: userData.coins,
            gems: userData.gems,
            runHistory: Array(userData.runHistory.prefix(100))
        )
        
        let encoded = try JSONEncoder().encode(data)
        defaults.set(encoded, forKey: userDataKey)
        print("✅ User data saved (local fallback)")
    }
    
    func loadUserData() async throws -> SaveableUserData? {
        guard let data = defaults.data(forKey: userDataKey) else {
            print("📝 No existing user data")
            return nil
        }
        
        let userData = try JSONDecoder().decode(SaveableUserData.self, from: data)
        print("✅ User data loaded (local fallback)")
        return userData
    }
    
    func clearUserData() async throws {
        defaults.removeObject(forKey: userDataKey)
        print("🗑️ User data cleared")
    }
    
    // MARK: - Daily Rewards (Local Fallback)
    
    func saveDailyRewardState(_ state: DailyRewardState) async throws {
        let encoded = try JSONEncoder().encode(state)
        defaults.set(encoded, forKey: dailyRewardKey)
    }
    
    func loadDailyRewardState() async throws -> DailyRewardState? {
        guard let data = defaults.data(forKey: dailyRewardKey) else {
            return nil
        }
        return try JSONDecoder().decode(DailyRewardState.self, from: data)
    }
    
    // MARK: - Debounced Save
    
    private var saveTask: Task<Void, Never>?
    
    func debouncedSave(_ userData: UserData) {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            try? await saveUserData(userData)
        }
    }
}

// MARK: - Error Types

enum FirebaseError: LocalizedError {
    case notAuthenticated
    case encodingFailed
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .encodingFailed:
            return "Failed to encode user data"
        case .decodingFailed:
            return "Failed to decode user data"
        }
    }
}
