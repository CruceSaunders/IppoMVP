import Foundation

// MARK: - Ability Effect
enum AbilityEffect: Codable, Equatable {
    case rpBonus(Double)
    case xpBonus(Double)
    case coinBonus(Double)
    case sprintBonus(Double)
    case petXpBonus(Double)
    case catchRateBonus(Double)
    case passiveBonus(Double)
    case evolutionDiscount(Double)
    case allBonus(Double)
    case lootLuckBonus(Double)
    
    var description: String {
        switch self {
        case .rpBonus(let value): return "+\(Int(value * 100))% RP"
        case .xpBonus(let value): return "+\(Int(value * 100))% XP"
        case .coinBonus(let value): return "+\(Int(value * 100))% Coins"
        case .sprintBonus(let value): return "+\(Int(value * 100))% Sprint Rewards"
        case .petXpBonus(let value): return "+\(Int(value * 100))% Pet XP"
        case .catchRateBonus(let value): return "+\(Int(value * 100))% Catch Rate"
        case .passiveBonus(let value): return "+\(Int(value * 100))% Passive Rewards"
        case .evolutionDiscount(let value): return "-\(Int(value * 100))% Evolution XP"
        case .allBonus(let value): return "+\(Int(value * 100))% All Rewards"
        case .lootLuckBonus(let value): return "+\(Int(value * 100))% Rare Loot"
        }
    }
    
    var value: Double {
        switch self {
        case .rpBonus(let v), .xpBonus(let v), .coinBonus(let v),
             .sprintBonus(let v), .petXpBonus(let v), .catchRateBonus(let v),
             .passiveBonus(let v), .evolutionDiscount(let v), .allBonus(let v),
             .lootLuckBonus(let v):
            return v
        }
    }
}

// MARK: - Ability Node
struct AbilityNode: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let tier: Int
    let cost: Int
    let effect: AbilityEffect
    let prerequisites: [String]
    let iconName: String
    let treeX: Double
    let treeY: Double
    
    static func == (lhs: AbilityNode, rhs: AbilityNode) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - User Abilities
struct UserAbilities: Codable, Equatable {
    var abilityPoints: Int
    var petPoints: Int
    var unlockedPlayerAbilities: Set<String>
    var petAbilityLevels: [String: Int]
    
    init(
        abilityPoints: Int = 0,
        petPoints: Int = 0,
        unlockedPlayerAbilities: Set<String> = [],
        petAbilityLevels: [String: Int] = [:]
    ) {
        self.abilityPoints = abilityPoints
        self.petPoints = petPoints
        self.unlockedPlayerAbilities = unlockedPlayerAbilities
        self.petAbilityLevels = petAbilityLevels
    }
    
    func canUnlock(_ node: AbilityNode) -> Bool {
        guard abilityPoints >= node.cost else { return false }
        guard !unlockedPlayerAbilities.contains(node.id) else { return false }
        return node.prerequisites.allSatisfy { unlockedPlayerAbilities.contains($0) }
    }
    
    mutating func unlock(_ node: AbilityNode) -> Bool {
        guard canUnlock(node) else { return false }
        abilityPoints -= node.cost
        unlockedPlayerAbilities.insert(node.id)
        return true
    }
    
    func getPetAbilityLevel(for petId: String) -> Int {
        petAbilityLevels[petId] ?? 1
    }
    
    func canUpgradePetAbility(petId: String) -> Bool {
        let currentLevel = getPetAbilityLevel(for: petId)
        guard currentLevel < 5 else { return false }
        let cost = currentLevel + 1
        return petPoints >= cost
    }
    
    mutating func upgradePetAbility(petId: String) -> Bool {
        let currentLevel = getPetAbilityLevel(for: petId)
        guard currentLevel < 5 else { return false }
        let cost = currentLevel + 1
        guard petPoints >= cost else { return false }
        petPoints -= cost
        petAbilityLevels[petId] = currentLevel + 1
        return true
    }
}

// MARK: - Computed Bonuses
extension UserAbilities {
    var rpBonusTotal: Double {
        var bonus = 0.0
        for abilityId in unlockedPlayerAbilities {
            if let node = AbilityTreeData.playerNodes.first(where: { $0.id == abilityId }) {
                switch node.effect {
                case .rpBonus(let value): bonus += value
                case .allBonus(let value): bonus += value
                case .sprintBonus(let value): bonus += value
                default: break
                }
            }
        }
        return bonus
    }
    
    var xpBonusTotal: Double {
        var bonus = 0.0
        for abilityId in unlockedPlayerAbilities {
            if let node = AbilityTreeData.playerNodes.first(where: { $0.id == abilityId }) {
                switch node.effect {
                case .xpBonus(let value): bonus += value
                case .allBonus(let value): bonus += value
                case .sprintBonus(let value): bonus += value
                default: break
                }
            }
        }
        return bonus
    }
    
    var coinBonusTotal: Double {
        var bonus = 0.0
        for abilityId in unlockedPlayerAbilities {
            if let node = AbilityTreeData.playerNodes.first(where: { $0.id == abilityId }) {
                switch node.effect {
                case .coinBonus(let value): bonus += value
                case .allBonus(let value): bonus += value
                case .sprintBonus(let value): bonus += value
                default: break
                }
            }
        }
        return bonus
    }
    
    var petXpBonusTotal: Double {
        var bonus = 0.0
        for abilityId in unlockedPlayerAbilities {
            if let node = AbilityTreeData.playerNodes.first(where: { $0.id == abilityId }) {
                if case .petXpBonus(let value) = node.effect {
                    bonus += value
                }
            }
        }
        return bonus
    }
    
    var catchRateBonusTotal: Double {
        var bonus = 0.0
        for abilityId in unlockedPlayerAbilities {
            if let node = AbilityTreeData.playerNodes.first(where: { $0.id == abilityId }) {
                if case .catchRateBonus(let value) = node.effect {
                    bonus += value
                }
            }
        }
        return bonus
    }
    
    var passiveBonusTotal: Double {
        var bonus = 0.0
        for abilityId in unlockedPlayerAbilities {
            if let node = AbilityTreeData.playerNodes.first(where: { $0.id == abilityId }) {
                if case .passiveBonus(let value) = node.effect {
                    bonus += value
                }
            }
        }
        return bonus
    }
    
    var evolutionDiscountTotal: Double {
        var discount = 0.0
        for abilityId in unlockedPlayerAbilities {
            if let node = AbilityTreeData.playerNodes.first(where: { $0.id == abilityId }) {
                if case .evolutionDiscount(let value) = node.effect {
                    discount += value
                }
            }
        }
        return discount
    }
    
    var lootLuckBonusTotal: Double {
        var bonus = 0.0
        for abilityId in unlockedPlayerAbilities {
            if let node = AbilityTreeData.playerNodes.first(where: { $0.id == abilityId }) {
                if case .lootLuckBonus(let value) = node.effect {
                    bonus += value
                }
            }
        }
        return bonus
    }
}

// MARK: - Ability Edge (for tree visualization)
struct AbilityEdge: Identifiable {
    let id: String
    let from: String
    let to: String
    
    init(from: String, to: String) {
        self.id = "\(from)->\(to)"
        self.from = from
        self.to = to
    }
}
