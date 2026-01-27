import Foundation

@MainActor
final class DataPersistence {
    static let shared = DataPersistence()
    
    private let userDataKey = "com.cruce.IppoMVP.userData"
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Save
    func saveUserData(_ userData: UserData) {
        let saveable = SaveableUserData(
            profile: userData.profile,
            ownedPets: userData.ownedPets,
            abilities: userData.abilities,
            inventory: userData.inventory,
            coins: userData.coins,
            gems: userData.gems,
            runHistory: userData.runHistory
        )
        
        do {
            let data = try JSONEncoder().encode(saveable)
            defaults.set(data, forKey: userDataKey)
        } catch {
            print("❌ Failed to save user data: \(error)")
        }
    }
    
    // MARK: - Load
    func loadUserData() -> SaveableUserData? {
        guard let data = defaults.data(forKey: userDataKey) else { return nil }
        
        do {
            return try JSONDecoder().decode(SaveableUserData.self, from: data)
        } catch {
            print("❌ Failed to load user data: \(error)")
            return nil
        }
    }
    
    // MARK: - Clear
    func clearUserData() {
        defaults.removeObject(forKey: userDataKey)
    }
    
    // MARK: - Export/Import (for debugging)
    func exportUserData() -> Data? {
        return defaults.data(forKey: userDataKey)
    }
    
    func importUserData(_ data: Data) -> Bool {
        do {
            _ = try JSONDecoder().decode(SaveableUserData.self, from: data)
            defaults.set(data, forKey: userDataKey)
            return true
        } catch {
            print("❌ Failed to import user data: \(error)")
            return false
        }
    }
}
