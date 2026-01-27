import Foundation

// MARK: - Rank
enum Rank: String, Codable, CaseIterable {
    case bronze1 = "bronze_1"
    case bronze2 = "bronze_2"
    case bronze3 = "bronze_3"
    case silver1 = "silver_1"
    case silver2 = "silver_2"
    case silver3 = "silver_3"
    case gold1 = "gold_1"
    case gold2 = "gold_2"
    case gold3 = "gold_3"
    case platinum = "platinum"
    case diamond = "diamond"
    case champion = "champion"
    
    var displayName: String {
        switch self {
        case .bronze1: return "Bronze I"
        case .bronze2: return "Bronze II"
        case .bronze3: return "Bronze III"
        case .silver1: return "Silver I"
        case .silver2: return "Silver II"
        case .silver3: return "Silver III"
        case .gold1: return "Gold I"
        case .gold2: return "Gold II"
        case .gold3: return "Gold III"
        case .platinum: return "Platinum"
        case .diamond: return "Diamond"
        case .champion: return "Champion"
        }
    }
    
    var rpRequired: Int {
        switch self {
        case .bronze1: return 0
        case .bronze2: return 500
        case .bronze3: return 1000
        case .silver1: return 2000
        case .silver2: return 3500
        case .silver3: return 5500
        case .gold1: return 8000
        case .gold2: return 11000
        case .gold3: return 15000
        case .platinum: return 20000
        case .diamond: return 30000
        case .champion: return 50000
        }
    }
    
    var iconName: String {
        switch self {
        case .bronze1, .bronze2, .bronze3: return "shield.fill"
        case .silver1, .silver2, .silver3: return "shield.fill"
        case .gold1, .gold2, .gold3: return "crown.fill"
        case .platinum: return "star.fill"
        case .diamond: return "diamond.fill"
        case .champion: return "trophy.fill"
        }
    }
    
    var nextRank: Rank? {
        let allRanks = Rank.allCases
        guard let currentIndex = allRanks.firstIndex(of: self),
              currentIndex < allRanks.count - 1 else { return nil }
        return allRanks[currentIndex + 1]
    }
    
    static func rank(forRP rp: Int) -> Rank {
        let sortedRanks = Rank.allCases.reversed()
        for rank in sortedRanks {
            if rp >= rank.rpRequired {
                return rank
            }
        }
        return .bronze1
    }
}

// MARK: - Player Profile
struct PlayerProfile: Codable, Equatable {
    var id: String
    var displayName: String
    var rp: Int
    var xp: Int
    var level: Int
    var equippedPetId: String?
    var totalRuns: Int
    var totalSprints: Int
    var totalSprintsValid: Int
    var createdAt: Date
    var lastRunDate: Date?
    var currentStreak: Int
    var longestStreak: Int
    var totalDistanceMeters: Double
    var totalDurationSeconds: Int
    
    init(
        id: String = UUID().uuidString,
        displayName: String = "Runner",
        rp: Int = 0,
        xp: Int = 0,
        level: Int = 1,
        equippedPetId: String? = nil,
        totalRuns: Int = 0,
        totalSprints: Int = 0,
        totalSprintsValid: Int = 0,
        createdAt: Date = Date(),
        lastRunDate: Date? = nil,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        totalDistanceMeters: Double = 0,
        totalDurationSeconds: Int = 0
    ) {
        self.id = id
        self.displayName = displayName
        self.rp = rp
        self.xp = xp
        self.level = level
        self.equippedPetId = equippedPetId
        self.totalRuns = totalRuns
        self.totalSprints = totalSprints
        self.totalSprintsValid = totalSprintsValid
        self.createdAt = createdAt
        self.lastRunDate = lastRunDate
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalDistanceMeters = totalDistanceMeters
        self.totalDurationSeconds = totalDurationSeconds
    }
    
    var rank: Rank {
        Rank.rank(forRP: rp)
    }
    
    var xpForNextLevel: Int {
        PlayerLevelConfig.xpRequired(for: level + 1)
    }
    
    var xpProgress: Double {
        let currentLevelXP = PlayerLevelConfig.xpRequired(for: level)
        let nextLevelXP = xpForNextLevel
        let progressXP = xp - currentLevelXP
        let neededXP = nextLevelXP - currentLevelXP
        guard neededXP > 0 else { return 1.0 }
        return min(max(0.0, Double(progressXP) / Double(neededXP)), 1.0)
    }
    
    var rpToNextRank: Int? {
        guard let next = rank.nextRank else { return nil }
        return next.rpRequired - rp
    }
    
    var streakBonus: Double {
        switch currentStreak {
        case 1...3: return 0.05
        case 4...7: return 0.10
        case 8...14: return 0.15
        default: return currentStreak >= 15 ? 0.20 : 0.0
        }
    }
}

// MARK: - Player Level Config
struct PlayerLevelConfig {
    static func xpRequired(for level: Int) -> Int {
        switch level {
        case 1...10: return (level - 1) * 100
        case 11...20: return 1000 + (level - 10) * 200
        case 21...30: return 3000 + (level - 20) * 400
        case 31...40: return 7000 + (level - 30) * 800
        case 41...50: return 15000 + (level - 40) * 1600
        default: return 31000 + (level - 50) * 3200
        }
    }
    
    static func level(forXP xp: Int) -> Int {
        var level = 1
        while xpRequired(for: level + 1) <= xp && level < 100 {
            level += 1
        }
        return level
    }
}

// MARK: - Completed Run
struct CompletedRun: Identifiable, Codable, Equatable {
    let id: String
    let date: Date
    let durationSeconds: Int
    let distanceMeters: Double
    let sprintsCompleted: Int
    let sprintsTotal: Int
    let rpEarned: Int
    let xpEarned: Int
    let coinsEarned: Int
    let petCaught: String?
    let lootBoxesEarned: [Rarity]
    
    init(
        id: String = UUID().uuidString,
        date: Date = Date(),
        durationSeconds: Int,
        distanceMeters: Double = 0,
        sprintsCompleted: Int,
        sprintsTotal: Int,
        rpEarned: Int,
        xpEarned: Int,
        coinsEarned: Int,
        petCaught: String? = nil,
        lootBoxesEarned: [Rarity] = []
    ) {
        self.id = id
        self.date = date
        self.durationSeconds = durationSeconds
        self.distanceMeters = distanceMeters
        self.sprintsCompleted = sprintsCompleted
        self.sprintsTotal = sprintsTotal
        self.rpEarned = rpEarned
        self.xpEarned = xpEarned
        self.coinsEarned = coinsEarned
        self.petCaught = petCaught
        self.lootBoxesEarned = lootBoxesEarned
    }
    
    var formattedDuration: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var sprintSuccessRate: Double {
        guard sprintsTotal > 0 else { return 0 }
        return Double(sprintsCompleted) / Double(sprintsTotal)
    }
}
