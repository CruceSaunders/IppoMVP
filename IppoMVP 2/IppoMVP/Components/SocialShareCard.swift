// SocialShareCard.swift
// Adapted from Strava, Nike Run Club, and Apple Fitness share cards for Ippo
// Source: ~/clawd/tools/ui-ux/swiftui-components/SocialShareCard.swift
//
// Usage in Ippo:
//   IppoRunShareCard(run: shareableRun, userName: "Cruce")
//   IppoPRShareCard(run: shareableRun, userName: "Cruce", previousBest: "5:42", improvement: "12 sec")
//   IppoStreakShareCard(streakDays: 30, userName: "Cruce", totalRuns: 45, totalDistance: 182.5)
//   IppoEPShareCard(epEarned: 250, bonusEP: 50, streakBonus: true)
//   IppoInstagramStoryCard(run: shareableRun, userName: "Cruce", backgroundStyle: .ippoGradient)
//
// Ippo-Specific Adaptations:
// - ALL colors use AppColors (brandPrimary, brandSecondary, semantic colors)
// - ALL spacing uses AppSpacing tokens (8pt grid)
// - ALL fonts use AppTypography (rounded, branded fonts)
// - EP (Effort Points) integration throughout - Ippo's core metric
// - Pet companion shown on share cards
// - Rarity-colored achievement tiers
// - Ippo-branded gradients and confetti colors

import SwiftUI

// MARK: - Ippo Effort Level

/// Effort level with EP multipliers
/// Used for run effort tracking and share cards
enum IppoEffortLevel: String, CaseIterable {
    case recovery = "Recovery"
    case easy = "Easy"
    case moderate = "Moderate"
    case hard = "Hard"
    case max = "Max"
    
    /// Color from Ippo's design system
    var color: Color {
        switch self {
        case .recovery: return AppColors.textTertiary
        case .easy: return AppColors.brandPrimary
        case .moderate: return AppColors.success
        case .hard: return AppColors.warning
        case .max: return AppColors.danger
        }
    }
    
    /// EP multiplier for effort-based rewards
    var epMultiplier: Double {
        switch self {
        case .recovery: return 0.5
        case .easy: return 1.0
        case .moderate: return 1.5
        case .hard: return 2.0
        case .max: return 3.0
        }
    }
    
    /// Icon for effort level
    var icon: String {
        switch self {
        case .recovery: return "figure.walk"
        case .easy: return "figure.run"
        case .moderate: return "figure.run.circle"
        case .hard: return "flame"
        case .max: return "bolt.heart.fill"
        }
    }
}

// MARK: - Shareable Run Model

/// Represents a shareable run summary with EP tracking
struct IppoShareableRun: Identifiable {
    let id = UUID()
    let distance: Double // meters
    let duration: TimeInterval // seconds
    let pace: Double // seconds per km
    let date: Date
    let routeImage: Image? // Optional map snapshot
    let isPR: Bool
    let prType: IppoPRType?
    let elevation: Double? // meters gained
    let calories: Int?
    let avgHeartRate: Int?
    let effortLevel: IppoEffortLevel
    let effortPoints: Int // Ippo's core metric
    let bonusEP: Int? // Streak bonus, PR bonus, etc.
    let petName: String? // Active pet companion
    let petEmoji: String? // Pet emoji for display
    
    /// PR types with icons
    enum IppoPRType: String, CaseIterable {
        case fastestKm = "Fastest KM"
        case fastest5K = "Fastest 5K"
        case fastest10K = "Fastest 10K"
        case longestRun = "Longest Run"
        case mostElevation = "Most Elevation"
        case mostEP = "Most EP" // Ippo-specific PR
        
        var icon: String {
            switch self {
            case .fastestKm, .fastest5K, .fastest10K: return "bolt.fill"
            case .longestRun: return "ruler"
            case .mostElevation: return "mountain.2.fill"
            case .mostEP: return "bolt.heart.fill"
            }
        }
        
        /// Color from Ippo palette
        var color: Color {
            switch self {
            case .fastestKm, .fastest5K, .fastest10K: return AppColors.brandPrimary
            case .longestRun: return AppColors.brandSecondary
            case .mostElevation: return AppColors.success
            case .mostEP: return AppColors.gold
            }
        }
    }
    
    // MARK: - Formatting Helpers
    
    var formattedDistance: String {
        String(format: "%.2f", distance / 1000)
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedPace: String {
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var totalEP: Int {
        effortPoints + (bonusEP ?? 0)
    }
}

// MARK: - Run Share Card

/// Standard share card with run summary and EP display
/// Use for: Post-run share, history share
struct IppoRunShareCard: View {
    let run: IppoShareableRun
    let userName: String
    let userAvatar: Image?
    let showAppBranding: Bool
    
    init(
        run: IppoShareableRun,
        userName: String,
        userAvatar: Image? = nil,
        showAppBranding: Bool = true
    ) {
        self.run = run
        self.userName = userName
        self.userAvatar = userAvatar
        self.showAppBranding = showAppBranding
    }
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        var description = "\(run.formattedDistance) kilometer run in \(run.formattedDuration), pace \(run.formattedPace) per kilometer"
        description += ", \(run.totalEP) Effort Points earned"
        if let bonus = run.bonusEP, bonus > 0 {
            description += " including \(bonus) bonus"
        }
        description += ", effort level \(run.effortLevel.rawValue)"
        if run.isPR, let prType = run.prType {
            description += ", new personal record for \(prType.rawValue)"
        }
        if let elevation = run.elevation {
            description += ", \(Int(elevation)) meters elevation"
        }
        if let calories = run.calories {
            description += ", \(calories) calories"
        }
        if let petName = run.petName {
            description += ", with pet companion \(petName)"
        }
        description += ". By \(userName)"
        return description
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Route map or gradient header
            headerView
            
            // Stats section
            VStack(spacing: AppSpacing.md) {
                // PR banner if applicable
                if run.isPR, let prType = run.prType {
                    prBanner(prType: prType)
                }
                
                // Main stats row
                HStack(spacing: AppSpacing.lg) {
                    IppoStatColumn(value: run.formattedDistance, label: "km")
                    
                    Divider()
                        .frame(height: 50)
                    
                    IppoStatColumn(value: run.formattedDuration, label: "time")
                    
                    Divider()
                        .frame(height: 50)
                    
                    IppoStatColumn(value: run.formattedPace, label: "/km")
                }
                .padding(.horizontal, AppSpacing.md)
                
                // EP Display - Ippo's core metric
                epDisplayRow
                
                // Secondary stats
                secondaryStatsRow
                
                // Effort level
                HStack(spacing: AppSpacing.xs) {
                    Text("Effort:")
                        .foregroundStyle(AppColors.textSecondary)
                    Image(systemName: run.effortLevel.icon)
                        .foregroundStyle(run.effortLevel.color)
                    Text(run.effortLevel.rawValue)
                        .fontWeight(.semibold)
                        .foregroundStyle(run.effortLevel.color)
                }
                .font(AppTypography.caption)
                
                Divider()
                    .padding(.horizontal, AppSpacing.md)
                
                // User and date row
                userRow
            }
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.background)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusLg))
        .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Run share card")
        .accessibilityValue(accessibilityDescription)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var headerView: some View {
        if let routeImage = run.routeImage {
            routeImage
                .resizable()
                .aspectRatio(16/9, contentMode: .fill)
                .frame(height: 200)
                .clipped()
                .overlay(
                    // EP badge overlay
                    epBadgeOverlay
                        .padding(AppSpacing.sm),
                    alignment: .topTrailing
                )
        } else {
            // Ippo-branded gradient placeholder
            LinearGradient(
                colors: [AppColors.brandPrimary, AppColors.brandSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 200)
            .overlay(
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 60))
                        .foregroundStyle(AppColors.textPrimary.opacity(0.3))
                    
                    if let petEmoji = run.petEmoji {
                        Text(petEmoji)
                            .font(.system(size: 40))
                    }
                }
            )
            .overlay(
                epBadgeOverlay
                    .padding(AppSpacing.sm),
                alignment: .topTrailing
            )
        }
    }
    
    private var epBadgeOverlay: some View {
        HStack(spacing: AppSpacing.xxs) {
            Image(systemName: "bolt.heart.fill")
                .foregroundStyle(AppColors.brandPrimary)
            Text("+\(run.totalEP)")
                .font(AppTypography.caption.bold())
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(
            Capsule()
                .fill(AppColors.surface.opacity(0.95))
        )
    }
    
    private func prBanner(prType: IppoShareableRun.IppoPRType) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: prType.icon)
            Text("NEW \(prType.rawValue.uppercased())!")
            Image(systemName: prType.icon)
        }
        .font(AppTypography.caption.bold())
        .foregroundStyle(AppColors.gold)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs)
        .background(
            Capsule()
                .fill(AppColors.gold.opacity(0.2))
        )
    }
    
    private var epDisplayRow: some View {
        HStack(spacing: AppSpacing.md) {
            // Main EP earned
            HStack(spacing: AppSpacing.xxs) {
                Image(systemName: "bolt.heart.fill")
                    .foregroundStyle(AppColors.brandPrimary)
                Text("\(run.effortPoints)")
                    .font(AppTypography.title3.bold())
                    .foregroundStyle(AppColors.textPrimary)
                Text("EP")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            // Bonus EP if any
            if let bonus = run.bonusEP, bonus > 0 {
                HStack(spacing: AppSpacing.xxs) {
                    Text("+\(bonus)")
                        .font(AppTypography.caption.bold())
                    Text("bonus")
                        .font(AppTypography.caption2)
                }
                .foregroundStyle(AppColors.gold)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xxs)
                .background(
                    Capsule()
                        .fill(AppColors.gold.opacity(0.2))
                )
            }
            
            // EP multiplier badge
            Text("\(String(format: "%.1f", run.effortLevel.epMultiplier))x")
                .font(AppTypography.caption.bold())
                .foregroundStyle(run.effortLevel.color)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xxs)
                .background(
                    Capsule()
                        .stroke(run.effortLevel.color, lineWidth: 1)
                )
        }
    }
    
    private var secondaryStatsRow: some View {
        HStack(spacing: AppSpacing.xl) {
            if let elevation = run.elevation {
                IppoSecondaryStatLabel(
                    icon: "arrow.up.right",
                    value: "\(Int(elevation))m",
                    label: "Elevation"
                )
            }
            if let calories = run.calories {
                IppoSecondaryStatLabel(
                    icon: "flame.fill",
                    value: "\(calories)",
                    label: "Calories"
                )
            }
            if let hr = run.avgHeartRate {
                IppoSecondaryStatLabel(
                    icon: "heart.fill",
                    value: "\(hr)",
                    label: "Avg HR"
                )
            }
        }
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.textSecondary)
    }
    
    private var userRow: some View {
        HStack {
            // User info
            HStack(spacing: AppSpacing.xs) {
                if let avatar = userAvatar {
                    avatar
                        .resizable()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.brandPrimary, AppColors.brandSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(String(userName.prefix(1)))
                                .font(AppTypography.caption.bold())
                                .foregroundStyle(AppColors.textPrimary)
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(userName)
                        .font(AppTypography.caption.bold())
                        .foregroundStyle(AppColors.textPrimary)
                    Text(run.date, style: .date)
                        .font(AppTypography.caption2)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            
            Spacer()
            
            // Pet companion if present
            if let petEmoji = run.petEmoji, let petName = run.petName {
                HStack(spacing: AppSpacing.xxs) {
                    Text(petEmoji)
                    Text(petName)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            
            // App branding
            if showAppBranding {
                ippoBranding
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }
    
    private var ippoBranding: some View {
        HStack(spacing: AppSpacing.xxs) {
            Image(systemName: "pawprint.fill")
                .foregroundStyle(AppColors.brandPrimary)
            Text("Ippo")
                .font(AppTypography.caption.bold())
                .foregroundStyle(AppColors.textPrimary)
        }
    }
}

// MARK: - PR Share Card

/// Celebration-focused card for personal records with EP bonus
/// Use for: PR achievement shares, milestone celebrations
struct IppoPRShareCard: View {
    let run: IppoShareableRun
    let userName: String
    let previousBest: String?
    let improvement: String?
    let prBonusEP: Int
    
    init(
        run: IppoShareableRun,
        userName: String,
        previousBest: String? = nil,
        improvement: String? = nil,
        prBonusEP: Int = 100
    ) {
        self.run = run
        self.userName = userName
        self.previousBest = previousBest
        self.improvement = improvement
        self.prBonusEP = prBonusEP
    }
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        var description = "Personal record"
        if let prType = run.prType {
            description += " for \(prType.rawValue)"
        }
        description += ", \(prBonusEP) bonus Effort Points"
        if run.prType == .longestRun {
            description += ", new distance \(run.formattedDistance) kilometers"
        } else if run.prType == .mostEP {
            description += ", \(run.totalEP) Effort Points"
        } else {
            description += ", new pace \(run.formattedPace) per kilometer"
        }
        if let previous = previousBest, let improvement = improvement {
            description += ", improved from \(previous) by \(improvement)"
        }
        description += ", run was \(run.formattedDistance) km in \(run.formattedDuration)"
        description += ". By \(userName)"
        return description
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Trophy header with Ippo gradient
            ZStack {
                LinearGradient(
                    colors: [AppColors.gold, AppColors.warning],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(AppColors.textPrimary)
                        .shadow(color: Color.black.opacity(0.2), radius: 2, y: 2)
                    
                    Text("PERSONAL RECORD")
                        .font(AppTypography.title2.bold())
                        .foregroundStyle(AppColors.textPrimary)
                    
                    if let prType = run.prType {
                        Text(prType.rawValue)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textPrimary.opacity(0.9))
                    }
                    
                    // EP bonus badge
                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: "bolt.heart.fill")
                        Text("+\(prBonusEP) BONUS EP")
                    }
                    .font(AppTypography.caption.bold())
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.xs)
                    .background(
                        Capsule()
                            .fill(AppColors.textPrimary.opacity(0.2))
                    )
                }
                .padding(.vertical, AppSpacing.xxl)
            }
            .frame(height: 200)
            
            // Record details
            VStack(spacing: AppSpacing.lg) {
                // New record value
                VStack(spacing: AppSpacing.xxs) {
                    Text("NEW RECORD")
                        .font(AppTypography.caption.bold())
                        .foregroundStyle(AppColors.textSecondary)
                    
                    if run.prType == .longestRun {
                        Text("\(run.formattedDistance) km")
                            .font(AppTypography.timer)
                            .foregroundStyle(AppColors.textPrimary)
                    } else if run.prType == .mostEP {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "bolt.heart.fill")
                                .foregroundStyle(AppColors.brandPrimary)
                            Text("\(run.totalEP)")
                                .font(AppTypography.timer)
                                .foregroundStyle(AppColors.textPrimary)
                        }
                    } else {
                        Text(run.formattedPace)
                            .font(AppTypography.timer)
                            .foregroundStyle(AppColors.textPrimary)
                        Text("per km")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                
                // Improvement comparison
                if let previous = previousBest, let improvement = improvement {
                    HStack(spacing: AppSpacing.lg) {
                        VStack {
                            Text("Previous")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                            Text(previous)
                                .font(AppTypography.title3)
                                .strikethrough()
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        
                        Image(systemName: "arrow.right")
                            .foregroundStyle(AppColors.success)
                        
                        VStack {
                            Text("Improved by")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                            Text(improvement)
                                .font(AppTypography.title3.bold())
                                .foregroundStyle(AppColors.success)
                        }
                    }
                }
                
                Divider()
                    .padding(.horizontal, AppSpacing.md)
                
                // Run summary row
                HStack(spacing: AppSpacing.lg) {
                    VStack {
                        Text(run.formattedDistance)
                            .font(AppTypography.title3.bold())
                            .foregroundStyle(AppColors.textPrimary)
                        Text("km")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    
                    VStack {
                        Text(run.formattedDuration)
                            .font(AppTypography.title3.bold())
                            .foregroundStyle(AppColors.textPrimary)
                        Text("time")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    
                    VStack {
                        HStack(spacing: AppSpacing.xxs) {
                            Image(systemName: "bolt.heart.fill")
                                .foregroundStyle(AppColors.brandPrimary)
                            Text("\(run.totalEP)")
                        }
                        .font(AppTypography.title3.bold())
                        .foregroundStyle(AppColors.textPrimary)
                        Text("EP")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                
                // User and branding
                HStack {
                    Text(userName)
                        .font(AppTypography.caption.bold())
                        .foregroundStyle(AppColors.textPrimary)
                    Text("•")
                        .foregroundStyle(AppColors.textSecondary)
                    Text(run.date, style: .date)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    
                    Spacer()
                    
                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: "pawprint.fill")
                            .foregroundStyle(AppColors.brandPrimary)
                        Text("Ippo")
                            .font(AppTypography.caption.bold())
                            .foregroundStyle(AppColors.textPrimary)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
            .padding(AppSpacing.lg)
            .background(AppColors.background)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusLg))
        .shadow(color: Color.black.opacity(0.15), radius: 15, y: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Personal record share card")
        .accessibilityValue(accessibilityDescription)
    }
}

// MARK: - Streak Share Card

/// Share card for streak milestones with streak bonus EP
/// Use for: 7-day streak, 30-day streak, etc.
struct IppoStreakShareCard: View {
    let streakDays: Int
    let userName: String
    let totalRuns: Int
    let totalDistance: Double // km
    let totalEP: Int
    let streakBonusEP: Int
    
    init(
        streakDays: Int,
        userName: String,
        totalRuns: Int,
        totalDistance: Double,
        totalEP: Int = 0,
        streakBonusEP: Int = 50
    ) {
        self.streakDays = streakDays
        self.userName = userName
        self.totalRuns = totalRuns
        self.totalDistance = totalDistance
        self.totalEP = totalEP
        self.streakBonusEP = streakBonusEP
    }
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        var description = "\(streakDays) day running streak"
        description += ", \(streakBonusEP) bonus Effort Points"
        description += ", \(String(format: "%.1f", streakMultiplier)) times EP multiplier"
        description += ", \(totalRuns) total runs"
        description += ", \(String(format: "%.1f", totalDistance)) kilometers total"
        description += ", \(totalEP) total Effort Points earned"
        description += ". By \(userName)"
        return description
    }
    
    private var milestoneText: String {
        switch streakDays {
        case 7: return "ONE WEEK STREAK!"
        case 14: return "TWO WEEK STREAK!"
        case 30: return "ONE MONTH STREAK!"
        case 60: return "TWO MONTH STREAK!"
        case 90: return "THREE MONTH STREAK!"
        case 100: return "100 DAY STREAK!"
        case 365: return "ONE YEAR STREAK!"
        default: return "\(streakDays) DAY STREAK!"
        }
    }
    
    private var streakMultiplier: Double {
        switch streakDays {
        case 1...6: return 1.0
        case 7...13: return 1.2
        case 14...29: return 1.5
        case 30...89: return 2.0
        case 90...: return 3.0
        default: return 1.0
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Fire header with Ippo colors
            ZStack {
                LinearGradient(
                    colors: [AppColors.warning, AppColors.danger],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                VStack(spacing: AppSpacing.md) {
                    // Flame stack
                    ZStack {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(AppColors.gold)
                            .offset(y: 5)
                        
                        Image(systemName: "flame.fill")
                            .font(.system(size: 70))
                            .foregroundStyle(AppColors.warning)
                    }
                    
                    Text(milestoneText)
                        .font(AppTypography.title2.bold())
                        .foregroundStyle(AppColors.textPrimary)
                    
                    // Streak bonus badge
                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: "bolt.heart.fill")
                        Text("+\(streakBonusEP) BONUS EP")
                    }
                    .font(AppTypography.caption.bold())
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.xs)
                    .background(
                        Capsule()
                            .fill(AppColors.textPrimary.opacity(0.2))
                    )
                }
                .padding(.vertical, AppSpacing.xxl)
            }
            .frame(height: 220)
            
            // Stats
            VStack(spacing: AppSpacing.lg) {
                // Streak count with multiplier
                HStack(spacing: AppSpacing.xs) {
                    Text("\(streakDays)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)
                    
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text("days")
                            .font(AppTypography.title2)
                            .foregroundStyle(AppColors.textSecondary)
                        
                        Text("\(String(format: "%.1f", streakMultiplier))x EP")
                            .font(AppTypography.caption.bold())
                            .foregroundStyle(AppColors.warning)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xxs)
                            .background(
                                Capsule()
                                    .fill(AppColors.warning.opacity(0.2))
                            )
                    }
                }
                
                // Supporting stats
                HStack(spacing: AppSpacing.xxl) {
                    VStack {
                        Text("\(totalRuns)")
                            .font(AppTypography.title2.bold())
                            .foregroundStyle(AppColors.textPrimary)
                        Text("total runs")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    
                    VStack {
                        Text(String(format: "%.1f", totalDistance))
                            .font(AppTypography.title2.bold())
                            .foregroundStyle(AppColors.textPrimary)
                        Text("km total")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    
                    VStack {
                        HStack(spacing: AppSpacing.xxs) {
                            Image(systemName: "bolt.heart.fill")
                                .foregroundStyle(AppColors.brandPrimary)
                            Text("\(totalEP)")
                        }
                        .font(AppTypography.title2.bold())
                        .foregroundStyle(AppColors.textPrimary)
                        Text("total EP")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                
                Divider()
                    .padding(.horizontal, AppSpacing.md)
                
                // User and branding
                HStack {
                    Text(userName)
                        .font(AppTypography.caption.bold())
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Spacer()
                    
                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: "pawprint.fill")
                            .foregroundStyle(AppColors.brandPrimary)
                        Text("Ippo")
                            .font(AppTypography.caption.bold())
                            .foregroundStyle(AppColors.textPrimary)
                    }
                }
            }
            .padding(AppSpacing.lg)
            .background(AppColors.background)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusLg))
        .shadow(color: Color.black.opacity(0.15), radius: 15, y: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Streak share card")
        .accessibilityValue(accessibilityDescription)
    }
}

// MARK: - EP Share Card (Ippo-Exclusive)

/// Ippo-specific card for sharing EP milestones
/// Use for: EP milestone celebrations (1000 EP, 10000 EP, etc.)
struct IppoEPShareCard: View {
    let totalEP: Int
    let milestone: Int // The milestone achieved (1000, 5000, 10000, etc.)
    let userName: String
    let daysActive: Int
    let avgEPPerRun: Int
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        var description = "Effort Points milestone, \(milestone) points reached"
        description += ", total \(totalEP) Effort Points"
        description += ", \(daysActive) days active"
        description += ", averaging \(avgEPPerRun) Effort Points per run"
        description += ". By \(userName)"
        return description
    }
    
    private var milestoneText: String {
        switch milestone {
        case 1000: return "1K EP CLUB!"
        case 5000: return "5K EP MILESTONE!"
        case 10000: return "10K EP LEGEND!"
        case 25000: return "25K EP MASTER!"
        case 50000: return "50K EP ELITE!"
        case 100000: return "100K EP GOD!"
        default: return "\(milestone) EP REACHED!"
        }
    }
    
    private var milestoneColor: Color {
        switch milestone {
        case 1000: return AppColors.brandPrimary
        case 5000: return AppColors.success
        case 10000: return AppColors.gold
        case 25000: return AppColors.brandSecondary
        case 50000: return AppColors.danger
        case 100000: return AppColors.legendary
        default: return AppColors.brandPrimary
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // EP header
            ZStack {
                LinearGradient(
                    colors: [milestoneColor, milestoneColor.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(spacing: AppSpacing.md) {
                    // EP icon with glow
                    Image(systemName: "bolt.heart.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(AppColors.textPrimary)
                        .shadow(color: AppColors.textPrimary.opacity(0.5), radius: 10)
                    
                    Text(milestoneText)
                        .font(AppTypography.title2.bold())
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text("EFFORT POINTS MILESTONE")
                        .font(AppTypography.caption.bold())
                        .tracking(2)
                        .foregroundStyle(AppColors.textPrimary.opacity(0.8))
                }
                .padding(.vertical, AppSpacing.xxl)
            }
            .frame(height: 200)
            
            // Stats
            VStack(spacing: AppSpacing.lg) {
                // Total EP count
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "bolt.heart.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(milestoneColor)
                    
                    Text("\(totalEP)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text("EP")
                        .font(AppTypography.title2)
                        .foregroundStyle(AppColors.textSecondary)
                        .offset(y: 10)
                }
                
                // Stats
                HStack(spacing: AppSpacing.xxl) {
                    VStack {
                        Text("\(daysActive)")
                            .font(AppTypography.title2.bold())
                            .foregroundStyle(AppColors.textPrimary)
                        Text("days active")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    
                    VStack {
                        Text("\(avgEPPerRun)")
                            .font(AppTypography.title2.bold())
                            .foregroundStyle(AppColors.textPrimary)
                        Text("avg EP/run")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                
                Divider()
                    .padding(.horizontal, AppSpacing.md)
                
                // User and branding
                HStack {
                    Text(userName)
                        .font(AppTypography.caption.bold())
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Spacer()
                    
                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: "pawprint.fill")
                            .foregroundStyle(AppColors.brandPrimary)
                        Text("Ippo")
                            .font(AppTypography.caption.bold())
                            .foregroundStyle(AppColors.textPrimary)
                    }
                }
            }
            .padding(AppSpacing.lg)
            .background(AppColors.background)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusLg))
        .shadow(color: Color.black.opacity(0.15), radius: 15, y: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Effort Points milestone share card")
        .accessibilityValue(accessibilityDescription)
    }
}

// MARK: - Pet Unlock Share Card (Ippo-Exclusive)

/// Share card for pet unlocks/evolutions
/// Use for: New pet hatched, pet evolved, rare pet unlocked
struct IppoPetShareCard: View {
    let petName: String
    let petEmoji: String
    let petRarity: PetRarity
    let isEvolution: Bool
    let previousForm: String? // For evolutions
    let userName: String
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        var description: String
        if isEvolution {
            description = "Pet evolved, \(petName)"
            if let previous = previousForm {
                description += " from previous form"
            }
        } else {
            description = "New pet hatched, \(petName)"
        }
        description += ", \(petRarity.rawValue) rarity"
        description += ". By \(userName)"
        return description
    }
    
    enum PetRarity: String, CaseIterable {
        case common = "Common"
        case uncommon = "Uncommon"
        case rare = "Rare"
        case epic = "Epic"
        case legendary = "Legendary"
        
        var color: Color {
            switch self {
            case .common: return AppColors.common
            case .uncommon: return AppColors.uncommon
            case .rare: return AppColors.rare
            case .epic: return AppColors.epic
            case .legendary: return AppColors.legendary
            }
        }
        
        var gradientColors: [Color] {
            switch self {
            case .common: return [AppColors.common, AppColors.common.opacity(0.7)]
            case .uncommon: return [AppColors.uncommon, AppColors.success]
            case .rare: return [AppColors.rare, AppColors.brandPrimary]
            case .epic: return [AppColors.epic, AppColors.brandSecondary]
            case .legendary: return [AppColors.legendary, AppColors.gold, AppColors.warning]
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Pet header
            ZStack {
                LinearGradient(
                    colors: petRarity.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(spacing: AppSpacing.md) {
                    // Pet emoji with glow
                    Text(petEmoji)
                        .font(.system(size: 80))
                        .shadow(color: petRarity.color.opacity(0.5), radius: 20)
                    
                    if isEvolution {
                        if let previous = previousForm {
                            HStack(spacing: AppSpacing.sm) {
                                Text(previous)
                                    .font(.system(size: 30))
                                    .opacity(0.5)
                                Image(systemName: "arrow.right")
                                    .foregroundStyle(AppColors.textPrimary)
                                Text(petEmoji)
                                    .font(.system(size: 30))
                            }
                        }
                        Text("PET EVOLVED!")
                            .font(AppTypography.title2.bold())
                            .foregroundStyle(AppColors.textPrimary)
                    } else {
                        Text("NEW PET HATCHED!")
                            .font(AppTypography.title2.bold())
                            .foregroundStyle(AppColors.textPrimary)
                    }
                }
                .padding(.vertical, AppSpacing.xxl)
            }
            .frame(height: 200)
            
            // Pet details
            VStack(spacing: AppSpacing.lg) {
                // Pet name
                Text(petName)
                    .font(AppTypography.title2.bold())
                    .foregroundStyle(AppColors.textPrimary)
                
                // Rarity badge
                Text(petRarity.rawValue.uppercased())
                    .font(AppTypography.caption.bold())
                    .tracking(1)
                    .foregroundStyle(petRarity.color)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.xs)
                    .background(
                        Capsule()
                            .fill(petRarity.color.opacity(0.2))
                    )
                
                Divider()
                    .padding(.horizontal, AppSpacing.md)
                
                // User and branding
                HStack {
                    Text(userName)
                        .font(AppTypography.caption.bold())
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Spacer()
                    
                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: "pawprint.fill")
                            .foregroundStyle(AppColors.brandPrimary)
                        Text("Ippo")
                            .font(AppTypography.caption.bold())
                            .foregroundStyle(AppColors.textPrimary)
                    }
                }
            }
            .padding(AppSpacing.lg)
            .background(AppColors.background)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusLg))
        .shadow(color: Color.black.opacity(0.15), radius: 15, y: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pet share card")
        .accessibilityValue(accessibilityDescription)
    }
}

// MARK: - Instagram Story Card

/// Optimized for Instagram Stories (9:16 aspect ratio)
/// Use for: Social media sharing, story posts
struct IppoInstagramStoryCard: View {
    let run: IppoShareableRun
    let userName: String
    let backgroundStyle: BackgroundStyle
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        var description = "Instagram story, \(run.formattedDistance) kilometers"
        description += " in \(run.formattedDuration)"
        description += ", pace \(run.formattedPace) per kilometer"
        description += ", \(run.totalEP) Effort Points"
        if run.isPR, let prType = run.prType {
            description += ", new personal record for \(prType.rawValue)"
        }
        if let petEmoji = run.petEmoji {
            description += ", with pet companion"
        }
        description += ". Tracked with Ippo"
        return description
    }
    
    enum BackgroundStyle {
        case ippoGradient
        case effortGradient(IppoEffortLevel)
        case route(image: Image)
        case solid(color: Color)
        
        var colors: [Color] {
            switch self {
            case .ippoGradient:
                return [AppColors.brandPrimary, AppColors.brandSecondary, AppColors.epic]
            case .effortGradient(let level):
                return [level.color, level.color.opacity(0.7)]
            case .solid(let color):
                return [color, color]
            case .route:
                return []
            }
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                backgroundView
                
                // Content
                VStack(spacing: AppSpacing.lg) {
                    Spacer()
                    
                    // Date
                    Text(run.date, style: .date)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textPrimary.opacity(0.8))
                    
                    // Pet companion if present
                    if let petEmoji = run.petEmoji {
                        Text(petEmoji)
                            .font(.system(size: 50))
                    }
                    
                    // Main stat
                    VStack(spacing: AppSpacing.xxs) {
                        Text(run.formattedDistance)
                            .font(.system(size: 80, weight: .bold, design: .rounded))
                        Text("KILOMETERS")
                            .font(AppTypography.caption.bold())
                            .tracking(3)
                    }
                    .foregroundStyle(AppColors.textPrimary)
                    
                    // Secondary stats
                    HStack(spacing: AppSpacing.xxl) {
                        VStack {
                            Text(run.formattedDuration)
                                .font(AppTypography.title2.bold())
                            Text("time")
                                .font(AppTypography.caption)
                                .opacity(0.8)
                        }
                        
                        VStack {
                            Text(run.formattedPace)
                                .font(AppTypography.title2.bold())
                            Text("/km")
                                .font(AppTypography.caption)
                                .opacity(0.8)
                        }
                    }
                    .foregroundStyle(AppColors.textPrimary)
                    
                    // EP display
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "bolt.heart.fill")
                            .foregroundStyle(AppColors.brandPrimary)
                        Text("+\(run.totalEP) EP")
                            .font(AppTypography.title3.bold())
                    }
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.sm)
                    .background(
                        Capsule()
                            .fill(AppColors.surface.opacity(0.3))
                    )
                    
                    // PR badge if applicable
                    if run.isPR, let prType = run.prType {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "trophy.fill")
                            Text("NEW \(prType.rawValue.uppercased())!")
                            Image(systemName: "trophy.fill")
                        }
                        .font(AppTypography.caption.bold())
                        .foregroundStyle(AppColors.gold)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.sm)
                        .background(
                            Capsule()
                                .fill(AppColors.gold.opacity(0.2))
                        )
                    }
                    
                    Spacer()
                    
                    // Branding
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "pawprint.fill")
                            .foregroundStyle(AppColors.brandPrimary)
                        Text("Tracked with Ippo")
                            .font(AppTypography.caption.bold())
                    }
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.bottom, 60)
                }
                .padding(AppSpacing.xxl)
            }
        }
        .aspectRatio(9/16, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusLg))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Instagram story share card")
        .accessibilityValue(accessibilityDescription)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch backgroundStyle {
        case .ippoGradient, .effortGradient, .solid:
            LinearGradient(
                colors: backgroundStyle.colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .route(let image):
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .overlay(Color.black.opacity(0.4))
        }
    }
}

// MARK: - Share Button

/// Button that triggers native share sheet
/// Use for: Share button in RunDetailView, PRView
struct IppoShareButton: View {
    let run: IppoShareableRun
    let userName: String
    let style: ShareButtonStyle
    let onShare: () -> Void
    
    enum ShareButtonStyle {
        case prominent
        case subtle
        case icon
    }
    
    // MARK: - Accessibility
    private var accessibilityLabel: String {
        "Share run"
    }
    
    private var accessibilityHint: String {
        "Double tap to share your \(run.formattedDistance) kilometer run with \(run.totalEP) Effort Points"
    }
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onShare()
        }) {
            switch style {
            case .prominent:
                Label("Share Run", systemImage: "square.and.arrow.up")
                    .font(AppTypography.caption.bold())
                    .frame(maxWidth: .infinity)
                    .padding(AppSpacing.md)
                    .background(AppColors.brandPrimary)
                    .foregroundStyle(AppColors.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
            case .subtle:
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.brandPrimary)
            case .icon:
                Image(systemName: "square.and.arrow.up")
                    .font(AppTypography.title3)
                    .foregroundStyle(AppColors.brandPrimary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }
}

// MARK: - Supporting Views

private struct IppoStatColumn: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: AppSpacing.xxs) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        // Parent share card handles accessibility, this is part of combined element
        .accessibilityHidden(true)
    }
}

private struct IppoSecondaryStatLabel: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: AppSpacing.xxs) {
            Image(systemName: icon)
                .accessibilityHidden(true) // Icon is decorative
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .fontWeight(.medium)
                Text(label)
                    .font(AppTypography.caption2)
            }
        }
        // Parent share card handles accessibility, this is part of combined element
        .accessibilityHidden(true)
    }
}

// MARK: - Render to Image Extension

extension View {
    /// Renders the view to a UIImage for sharing
    /// Use for: Creating shareable images from cards
    @MainActor
    func renderToIppoShareImage(scale: CGFloat = 2.0) -> UIImage? {
        let renderer = ImageRenderer(content: self)
        renderer.scale = scale
        return renderer.uiImage
    }
}

// MARK: - Previews

#Preview("Ippo Run Share Card") {
    let sampleRun = IppoShareableRun(
        distance: 5230,
        duration: 1620,
        pace: 310,
        date: Date(),
        routeImage: nil,
        isPR: true,
        prType: .fastest5K,
        elevation: 45,
        calories: 380,
        avgHeartRate: 158,
        effortLevel: .hard,
        effortPoints: 185,
        bonusEP: 25,
        petName: "Blaze",
        petEmoji: "🦊"
    )
    
    IppoRunShareCard(run: sampleRun, userName: "Cruce")
        .frame(width: 350)
        .padding()
        .background(Color.gray.opacity(0.1))
}

#Preview("Ippo PR Share Card") {
    let sampleRun = IppoShareableRun(
        distance: 5000,
        duration: 1500,
        pace: 300,
        date: Date(),
        routeImage: nil,
        isPR: true,
        prType: .fastest5K,
        elevation: nil,
        calories: nil,
        avgHeartRate: nil,
        effortLevel: .max,
        effortPoints: 220,
        bonusEP: 100,
        petName: nil,
        petEmoji: nil
    )
    
    IppoPRShareCard(
        run: sampleRun,
        userName: "Cruce",
        previousBest: "5:12",
        improvement: "12 sec"
    )
    .frame(width: 350)
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Ippo Streak Share Card") {
    IppoStreakShareCard(
        streakDays: 30,
        userName: "Cruce",
        totalRuns: 45,
        totalDistance: 182.5,
        totalEP: 8500,
        streakBonusEP: 100
    )
    .frame(width: 350)
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Ippo EP Milestone Card") {
    IppoEPShareCard(
        totalEP: 10250,
        milestone: 10000,
        userName: "Cruce",
        daysActive: 45,
        avgEPPerRun: 180
    )
    .frame(width: 350)
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Ippo Pet Share Card - New") {
    IppoPetShareCard(
        petName: "Phoenix",
        petEmoji: "🦅",
        petRarity: .legendary,
        isEvolution: false,
        previousForm: nil,
        userName: "Cruce"
    )
    .frame(width: 350)
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Ippo Pet Share Card - Evolution") {
    IppoPetShareCard(
        petName: "Blaze",
        petEmoji: "🦊",
        petRarity: .epic,
        isEvolution: true,
        previousForm: "🐕",
        userName: "Cruce"
    )
    .frame(width: 350)
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Ippo Instagram Story") {
    let sampleRun = IppoShareableRun(
        distance: 10230,
        duration: 3120,
        pace: 305,
        date: Date(),
        routeImage: nil,
        isPR: true,
        prType: .fastest10K,
        elevation: 85,
        calories: 680,
        avgHeartRate: 162,
        effortLevel: .hard,
        effortPoints: 320,
        bonusEP: 100,
        petName: "Blaze",
        petEmoji: "🦊"
    )
    
    IppoInstagramStoryCard(
        run: sampleRun,
        userName: "Cruce",
        backgroundStyle: .ippoGradient
    )
    .frame(width: 270, height: 480)
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Share Button Styles") {
    let sampleRun = IppoShareableRun(
        distance: 5000,
        duration: 1500,
        pace: 300,
        date: Date(),
        routeImage: nil,
        isPR: false,
        prType: nil,
        elevation: nil,
        calories: nil,
        avgHeartRate: nil,
        effortLevel: .moderate,
        effortPoints: 150,
        bonusEP: nil,
        petName: nil,
        petEmoji: nil
    )
    
    VStack(spacing: AppSpacing.lg) {
        IppoShareButton(run: sampleRun, userName: "Cruce", style: .prominent) {}
            .frame(width: 300)
        
        IppoShareButton(run: sampleRun, userName: "Cruce", style: .subtle) {}
        
        IppoShareButton(run: sampleRun, userName: "Cruce", style: .icon) {}
    }
    .padding()
    .background(AppColors.background)
}
