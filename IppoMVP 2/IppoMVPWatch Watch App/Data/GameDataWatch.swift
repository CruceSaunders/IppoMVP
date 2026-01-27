#if os(watchOS)
import Foundation

// Simplified pet definition for Watch
struct GamePetDefinitionWatch {
    let id: String
    let name: String
    let emoji: String
}

@MainActor
final class GameDataWatch {
    static let shared = GameDataWatch()
    
    let allPets: [GamePetDefinitionWatch] = [
        GamePetDefinitionWatch(id: "pet_01", name: "Astravyrn", emoji: "🐉"),
        GamePetDefinitionWatch(id: "pet_02", name: "Solarok", emoji: "🌊"),
        GamePetDefinitionWatch(id: "pet_03", name: "Azyrith", emoji: "🌿"),
        GamePetDefinitionWatch(id: "pet_04", name: "Cosmoose", emoji: "🦌"),
        GamePetDefinitionWatch(id: "pet_05", name: "Nebulyth", emoji: "🌑"),
        GamePetDefinitionWatch(id: "pet_06", name: "Lumirith", emoji: "✨"),
        GamePetDefinitionWatch(id: "pet_07", name: "Flitfoal", emoji: "🦄"),
        GamePetDefinitionWatch(id: "pet_08", name: "Kryonith", emoji: "🦎"),
        GamePetDefinitionWatch(id: "pet_09", name: "Emberhart", emoji: "🔥"),
        GamePetDefinitionWatch(id: "pet_10", name: "Aurivern", emoji: "🦅")
    ]
    
    func pet(byId id: String) -> GamePetDefinitionWatch? {
        allPets.first { $0.id == id }
    }
    
    private init() {}
}
#endif
