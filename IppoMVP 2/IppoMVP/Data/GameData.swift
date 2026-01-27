import Foundation

@MainActor
final class GameData {
    static let shared = GameData()
    
    // MARK: - The 10 Pets
    let allPets: [GamePetDefinition] = [
        GamePetDefinition(
            id: "pet_01",
            name: "Astravyrn",
            description: "A celestial dragon that burns brightest in short bursts",
            abilityName: "Ignite",
            abilityDescription: "+15% RP on sprints under 35 seconds",
            abilityBaseValue: 0.15,
            evolutionImageNames: Array(repeating: "astravyrn", count: 10)
        ),
        GamePetDefinition(
            id: "pet_02",
            name: "Solarok",
            description: "An aquatic titan that rewards steady effort",
            abilityName: "Flow",
            abilityDescription: "+10% passive XP during runs",
            abilityBaseValue: 0.10,
            evolutionImageNames: Array(repeating: "solarok", count: 10)
        ),
        GamePetDefinition(
            id: "pet_03",
            name: "Azyrith",
            description: "A verdant spirit that helps all pets grow faster",
            abilityName: "Growth",
            abilityDescription: "+20% evolution XP gains",
            abilityBaseValue: 0.20,
            evolutionImageNames: Array(repeating: "azyrith", count: 10)
        ),
        GamePetDefinition(
            id: "pet_04",
            name: "Cosmoose",
            description: "A celestial moose that attracts more sprint opportunities",
            abilityName: "Tailwind",
            abilityDescription: "+10% encounter chance",
            abilityBaseValue: 0.10,
            evolutionImageNames: Array(repeating: "cosmoose", count: 10)
        ),
        GamePetDefinition(
            id: "pet_05",
            name: "Nebulyth",
            description: "An abyssal creature that stays content longer",
            abilityName: "Fortitude",
            abilityDescription: "-15% mood decay when inactive",
            abilityBaseValue: 0.15,
            evolutionImageNames: Array(repeating: "nebulyth", count: 10)
        ),
        GamePetDefinition(
            id: "pet_06",
            name: "Lumirith",
            description: "A radiant being that amplifies rewards",
            abilityName: "Energize",
            abilityDescription: "+25% coins from loot boxes",
            abilityBaseValue: 0.25,
            evolutionImageNames: Array(repeating: "lumirith", count: 10)
        ),
        GamePetDefinition(
            id: "pet_07",
            name: "Flitfoal",
            description: "An abyssal creature that helps find others",
            abilityName: "Stealth",
            abilityDescription: "+5% catch rate for new pets",
            abilityBaseValue: 0.05,
            evolutionImageNames: Array(repeating: "flitfoal", count: 10)
        ),
        GamePetDefinition(
            id: "pet_08",
            name: "Kryonith",
            description: "A verdant beast that maximizes care rewards",
            abilityName: "Preserve",
            abilityDescription: "Feeding gives +50% XP",
            abilityBaseValue: 0.50,
            evolutionImageNames: Array(repeating: "kryonith", count: 10)
        ),
        GamePetDefinition(
            id: "pet_09",
            name: "Emberhart",
            description: "An infernal stag that rewards sustained effort",
            abilityName: "Intensity",
            abilityDescription: "+30% RP on sprints over 40 seconds",
            abilityBaseValue: 0.30,
            evolutionImageNames: Array(repeating: "emberhart", count: 10)
        ),
        GamePetDefinition(
            id: "pet_10",
            name: "Aurivern",
            description: "A radiant phoenix that enhances everything",
            abilityName: "Blessing",
            abilityDescription: "+5% to ALL other pet bonuses",
            abilityBaseValue: 0.05,
            evolutionImageNames: Array(repeating: "aurivern", count: 10)
        )
    ]
    
    // MARK: - Lookup
    func pet(byId id: String) -> GamePetDefinition? {
        allPets.first { $0.id == id }
    }
    
    func pet(byName name: String) -> GamePetDefinition? {
        allPets.first { $0.name.lowercased() == name.lowercased() }
    }
    
    // MARK: - Random Pet Selection
    func randomUnownedPet(ownedPetIds: Set<String>) -> GamePetDefinition? {
        let unowned = allPets.filter { !ownedPetIds.contains($0.id) }
        return unowned.randomElement()
    }
    
    // MARK: - Private Init
    private init() {}
}

// MARK: - Ability Tree Data
struct AbilityTreeData {
    // MARK: - Player Ability Nodes
    // Layout: XP branch (left), RP branch (center), Coin branch (right)
    // Tiers flow from top (0.10) to bottom (0.85)
    static let playerNodes: [AbilityNode] = [
        // TIER 1 - Starting branches (Y: 0.10)
        AbilityNode(
            id: "xp_1",
            name: "XP Boost I",
            description: "+5% XP from all sources",
            tier: 1,
            cost: 1,
            effect: .xpBonus(0.05),
            prerequisites: [],
            iconName: "arrow.up.circle.fill",
            treeX: 0.20,
            treeY: 0.10
        ),
        AbilityNode(
            id: "rp_1",
            name: "RP Boost I",
            description: "+5% RP from all sources",
            tier: 1,
            cost: 1,
            effect: .rpBonus(0.05),
            prerequisites: [],
            iconName: "star.fill",
            treeX: 0.50,
            treeY: 0.10
        ),
        AbilityNode(
            id: "coin_1",
            name: "Coin Boost I",
            description: "+5% coins from all sources",
            tier: 1,
            cost: 1,
            effect: .coinBonus(0.05),
            prerequisites: [],
            iconName: "bitcoinsign.circle.fill",
            treeX: 0.80,
            treeY: 0.10
        ),
        
        // TIER 2 - Improved versions (Y: 0.25)
        AbilityNode(
            id: "xp_2",
            name: "XP Boost II",
            description: "+10% XP from all sources",
            tier: 2,
            cost: 2,
            effect: .xpBonus(0.10),
            prerequisites: ["xp_1"],
            iconName: "arrow.up.circle.fill",
            treeX: 0.20,
            treeY: 0.25
        ),
        AbilityNode(
            id: "rp_2",
            name: "RP Boost II",
            description: "+10% RP from all sources",
            tier: 2,
            cost: 2,
            effect: .rpBonus(0.10),
            prerequisites: ["rp_1"],
            iconName: "star.fill",
            treeX: 0.50,
            treeY: 0.25
        ),
        AbilityNode(
            id: "coin_2",
            name: "Coin Boost II",
            description: "+10% coins from all sources",
            tier: 2,
            cost: 2,
            effect: .coinBonus(0.10),
            prerequisites: ["coin_1"],
            iconName: "bitcoinsign.circle.fill",
            treeX: 0.80,
            treeY: 0.25
        ),
        
        // TIER 3 - Specialized (Y: 0.45)
        // Pet Lover: requires XP II, positioned under XP branch
        AbilityNode(
            id: "pet_lover",
            name: "Pet Lover",
            description: "+25% pet evolution XP",
            tier: 3,
            cost: 3,
            effect: .petXpBonus(0.25),
            prerequisites: ["xp_2"],
            iconName: "heart.fill",
            treeX: 0.15,
            treeY: 0.45
        ),
        // Lucky Runner: requires RP II, positioned under RP branch (left side)
        AbilityNode(
            id: "lucky_runner",
            name: "Lucky Runner",
            description: "+2% pet catch rate",
            tier: 3,
            cost: 3,
            effect: .catchRateBonus(0.02),
            prerequisites: ["rp_2"],
            iconName: "leaf.fill",
            treeX: 0.38,
            treeY: 0.45
        ),
        // Sprint Master: requires all 3 boosts, positioned center-right
        AbilityNode(
            id: "sprint_master",
            name: "Sprint Master",
            description: "+15% to all sprint rewards",
            tier: 3,
            cost: 3,
            effect: .sprintBonus(0.15),
            prerequisites: ["rp_2", "xp_2", "coin_2"],
            iconName: "bolt.fill",
            treeX: 0.62,
            treeY: 0.45
        ),
        // Loot Luck: requires Coin II, positioned under Coin branch
        AbilityNode(
            id: "loot_luck",
            name: "Loot Luck",
            description: "+15% chance of rare loot boxes",
            tier: 3,
            cost: 3,
            effect: .lootLuckBonus(0.15),
            prerequisites: ["coin_2"],
            iconName: "gift.fill",
            treeX: 0.85,
            treeY: 0.45
        ),
        
        // TIER 4 - Powerful (Y: 0.65)
        AbilityNode(
            id: "evolution_accelerator",
            name: "Evolution Accelerator",
            description: "-20% XP needed for pet evolution",
            tier: 4,
            cost: 4,
            effect: .evolutionDiscount(0.20),
            prerequisites: ["pet_lover"],
            iconName: "sparkles",
            treeX: 0.15,
            treeY: 0.65
        ),
        AbilityNode(
            id: "passive_income",
            name: "Passive Income",
            description: "+50% passive rewards while running",
            tier: 4,
            cost: 4,
            effect: .passiveBonus(0.50),
            prerequisites: ["sprint_master"],
            iconName: "hourglass",
            treeX: 0.50,
            treeY: 0.65
        ),
        AbilityNode(
            id: "treasure_hunter",
            name: "Treasure Hunter",
            description: "+25% coins and +10% rare loot",
            tier: 4,
            cost: 4,
            effect: .coinBonus(0.25),
            prerequisites: ["loot_luck"],
            iconName: "star.circle.fill",
            treeX: 0.85,
            treeY: 0.65
        ),
        
        // TIER 5 - Ultimate (Y: 0.85)
        AbilityNode(
            id: "champion",
            name: "Champion",
            description: "+25% RP, +25% XP, +25% Coins",
            tier: 5,
            cost: 5,
            effect: .allBonus(0.25),
            prerequisites: ["passive_income", "evolution_accelerator"],
            iconName: "crown.fill",
            treeX: 0.33,
            treeY: 0.85
        )
    ]
    
    // MARK: - Node Lookup
    static func node(byId id: String) -> AbilityNode? {
        playerNodes.first { $0.id == id }
    }
    
    static func nodesByTier(_ tier: Int) -> [AbilityNode] {
        playerNodes.filter { $0.tier == tier }
    }
    
    // MARK: - Tree Edges (for visualization)
    static var edges: [AbilityEdge] {
        var result: [AbilityEdge] = []
        for node in playerNodes {
            for prereq in node.prerequisites {
                result.append(AbilityEdge(from: prereq, to: node.id))
            }
        }
        return result
    }
}
