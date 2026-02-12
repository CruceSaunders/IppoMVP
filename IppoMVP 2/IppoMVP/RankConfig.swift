import Foundation
import SwiftUI

/// Configuration for the 5-tier rank progression system with perks
/// Uses GameRank to avoid conflict with existing Rank enum
struct RankConfig: Sendable {
    static let shared = RankConfig()
    
    /// All available game ranks in order
    let allRanks: [GameRank] = [
        GameRank(
            id: "bronze",
            name: "Bronze",
            tier: 1,
            rpRequired: 0,
            rpCap: 999,
            iconName: "shield.fill",
            color: Color(red: 0.8, green: 0.5, blue: 0.2),
            perks: [
                RankPerk(type: .coinBonus, value: 0, description: "Base rewards")
            ]
        ),
        GameRank(
            id: "silver",
            name: "Silver",
            tier: 2,
            rpRequired: 1000,
            rpCap: 2999,
            iconName: "shield.lefthalf.filled",
            color: Color(red: 0.75, green: 0.75, blue: 0.8),
            perks: [
                RankPerk(type: .coinBonus, value: 0.05, description: "+5% coin bonus")
            ]
        ),
        GameRank(
            id: "gold",
            name: "Gold",
            tier: 3,
            rpRequired: 3000,
            rpCap: 6999,
            iconName: "shield.fill",
            color: Color(red: 1.0, green: 0.84, blue: 0.0),
            perks: [
                RankPerk(type: .coinBonus, value: 0.10, description: "+10% coin bonus"),
                RankPerk(type: .xpBonus, value: 0.05, description: "+5% XP bonus")
            ]
        ),
        GameRank(
            id: "platinum",
            name: "Platinum",
            tier: 4,
            rpRequired: 7000,
            rpCap: 14999,
            iconName: "crown.fill",
            color: Color(red: 0.9, green: 0.9, blue: 0.95),
            perks: [
                RankPerk(type: .coinBonus, value: 0.15, description: "+15% coin bonus"),
                RankPerk(type: .xpBonus, value: 0.10, description: "+10% XP bonus"),
                RankPerk(type: .catchRate, value: 0.05, description: "+5% catch rate")
            ]
        ),
        GameRank(
            id: "diamond",
            name: "Diamond",
            tier: 5,
            rpRequired: 15000,
            rpCap: Int.max,
            iconName: "diamond.fill",
            color: Color(red: 0.73, green: 0.87, blue: 0.98),
            perks: [
                RankPerk(type: .coinBonus, value: 0.25, description: "+25% coin bonus"),
                RankPerk(type: .xpBonus, value: 0.15, description: "+15% XP bonus"),
                RankPerk(type: .catchRate, value: 0.10, description: "+10% catch rate")
            ]
        )
    ]
    
    /// Get rank for given RP amount
    func rank(forRP rp: Int) -> GameRank {
        for rank in allRanks.reversed() {
            if rp >= rank.rpRequired {
                return rank
            }
        }
        return allRanks.first!
    }
    
    /// Get next rank after current
    func nextRank(after current: GameRank) -> GameRank? {
        guard let index = allRanks.firstIndex(where: { $0.id == current.id }),
              index + 1 < allRanks.count else {
            return nil
        }
        return allRanks[index + 1]
    }
    
    /// Calculate progress to next rank (0.0 - 1.0)
    func progressToNextRank(currentRP: Int, currentRank: GameRank) -> Double {
        guard let nextRank = nextRank(after: currentRank) else {
            return 1.0 // Max rank
        }
        
        let rpInCurrentRank = currentRP - currentRank.rpRequired
        let rpNeededForNext = nextRank.rpRequired - currentRank.rpRequired
        
        return min(1.0, max(0.0, Double(rpInCurrentRank) / Double(rpNeededForNext)))
    }
}

// MARK: - GameRank Model (distinct from Rank enum in PlayerTypes)

struct GameRank: Identifiable, Sendable, Equatable {
    let id: String
    let name: String
    let tier: Int
    let rpRequired: Int
    let rpCap: Int
    let iconName: String
    let color: Color
    let perks: [RankPerk]
    
    var displayName: String {
        name
    }
    
    static func == (lhs: GameRank, rhs: GameRank) -> Bool {
        lhs.id == rhs.id
    }
}

struct RankPerk: Identifiable, Sendable {
    let id = UUID()
    let type: PerkType
    let value: Double
    let description: String
    
    enum PerkType: Sendable {
        case coinBonus
        case xpBonus
        case catchRate
        case special
    }
}

// MARK: - Extensions for PlayerProfile (using GameRank)

extension PlayerProfile {
    /// Get current game rank with perks based on RP
    var gameRank: GameRank {
        RankConfig.shared.rank(forRP: rp)
    }
    
    /// Get next game rank (nil if at max)
    var nextGameRank: GameRank? {
        RankConfig.shared.nextRank(after: gameRank)
    }
    
    /// Progress to next rank (0.0 - 1.0)
    var rankProgress: Double {
        RankConfig.shared.progressToNextRank(currentRP: rp, currentRank: gameRank)
    }
}
