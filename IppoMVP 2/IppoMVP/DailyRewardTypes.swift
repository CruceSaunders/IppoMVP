import Foundation

/// Daily reward state - tracks claimed rewards
/// Stored separately to work with or without Firebase
struct DailyRewardState: Codable, Equatable {
    var lastClaimDate: Date?
    var currentDay: Int
    var streakCount: Int
    
    init(lastClaimDate: Date? = nil, currentDay: Int = 1, streakCount: Int = 0) {
        self.lastClaimDate = lastClaimDate
        self.currentDay = currentDay
        self.streakCount = streakCount
    }
    
    /// Check if user can claim today's reward
    func canClaimToday() -> Bool {
        guard let lastClaim = lastClaimDate else { return true }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastClaimDay = calendar.startOfDay(for: lastClaim)
        
        return !calendar.isDate(today, inSameDayAs: lastClaimDay)
    }
    
    /// Get the next day to claim (1-7, wraps around)
    func getNextClaimDay() -> Int {
        guard let lastClaim = lastClaimDate else { return 1 }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastClaimDay = calendar.startOfDay(for: lastClaim)
        let daysDiff = calendar.dateComponents([.day], from: lastClaimDay, to: today).day ?? 0
        
        if daysDiff == 0 {
            // Already claimed today
            return currentDay
        } else if daysDiff == 1 {
            // Consecutive day - advance to next day
            return (currentDay % 7) + 1
        } else {
            // Streak broken - reset to day 1
            return 1
        }
    }
}
