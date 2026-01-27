import Foundation
import Combine

@MainActor
final class RewardsSystem: ObservableObject {
    static let shared = RewardsSystem()
    
    private let config = RewardsConfig.shared
    
    private init() {}
    
    // MARK: - Calculate Sprint Rewards
    func calculateSprintRewards(result: SprintResult) -> SprintRewards {
        guard result.isValid else { return .empty }
        
        let userData = UserData.shared
        let base = config.baseSprintRewards()
        
        // Calculate bonuses
        var rpBonus = userData.abilities.rpBonusTotal
        let xpBonus = userData.abilities.xpBonusTotal
        let coinBonus = userData.abilities.coinBonusTotal
        
        // Pet ability bonuses
        if let pet = userData.equippedPet, let def = pet.definition {
            let effectiveness = pet.abilityEffectiveness
            
            switch def.id {
            case "pet_01":  // Ember: short sprints
                if result.duration < 35 { rpBonus += 0.15 * effectiveness }
            case "pet_09":  // Blaze: long sprints
                if result.duration > 40 { rpBonus += 0.30 * effectiveness }
            default:
                break
            }
        }
        
        // Apply bonuses
        let final = config.applyBonuses(
            base: base,
            rpBonus: rpBonus,
            xpBonus: xpBonus,
            coinBonus: coinBonus,
            streakDays: userData.profile.currentStreak
        )
        
        // Roll for loot box
        let lootBox = EncounterConfig.shared.rollLootBoxRarity()
        
        return SprintRewards(
            rp: final.rp,
            xp: final.xp,
            coins: final.coins,
            lootBox: lootBox
        )
    }
    
    // MARK: - Passive Rewards
    func calculatePassiveRewards(minutes: Int) -> (rp: Int, xp: Int) {
        let userData = UserData.shared
        let passiveBonus = userData.abilities.passiveBonusTotal
        
        // Splash's Flow: +10% passive XP
        var xpBonus = 0.0
        if let pet = userData.equippedPet, pet.petDefinitionId == "pet_02" {
            xpBonus = 0.10 * pet.abilityEffectiveness
        }
        
        var totalRP = 0
        var totalXP = 0
        
        for _ in 0..<minutes {
            let baseRP = Int.random(in: config.rpPerMinute)
            let baseXP = Int.random(in: config.xpPerMinute)
            
            totalRP += Int(Double(baseRP) * (1.0 + passiveBonus))
            totalXP += Int(Double(baseXP) * (1.0 + passiveBonus + xpBonus))
        }
        
        return (totalRP, totalXP)
    }
    
    // MARK: - Pet Catch Rewards
    func getPetCatchRewards() -> (coins: Int, rp: Int, xp: Int) {
        (
            config.bonusCoinsForPetCatch,
            config.bonusRPForPetCatch,
            config.bonusXPForPetCatch
        )
    }
    
    // MARK: - Apply All Rewards
    func applyRewards(_ rewards: SprintRewards) {
        let userData = UserData.shared
        
        userData.addRP(rewards.rp)
        userData.addXP(rewards.xp)
        userData.addCoins(rewards.coins)
        
        if let rarity = rewards.lootBox {
            userData.addLootBox(rarity)
        }
        
        // Pet XP
        if let petId = userData.equippedPet?.id {
            userData.addPetXP(petId, xp: PetConfig.shared.xpPerCompletedSprint)
        }
    }
}
