// StatsCard.swift
// Adapted from Nike Run Club post-run summary and Strava activity cards
// Customized for Ippo's design system
//
// Source: ~/clawd/tools/ui-ux/TOP-APP-PATTERNS.md (Nike Run Club, Strava sections)
// Pattern: Clean stat display with comparison and visual hierarchy
//
// Usage:
//   StatCard(label: "Distance", value: "5.02", unit: "km")
//   
//   RunSummaryCard(
//     distance: 5.02, time: "32:14", pace: "6'25\"",
//     calories: 524, elevation: 45
//   )

import SwiftUI

// MARK: - Single Stat Card

struct StatCard: View {
    let label: String
    let value: String
    let unit: String?
    let icon: String?
    let trend: Trend?
    let trendValue: String?
    let color: Color
    let size: Size
    
    enum Trend {
        case up, down, neutral
        
        var color: Color {
            switch self {
            case .up: return AppColors.success
            case .down: return AppColors.danger
            case .neutral: return AppColors.textTertiary
            }
        }
        
        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .neutral: return "minus"
            }
        }
    }
    
    enum Size {
        case small, medium, large
        
        var valueFont: Font {
            switch self {
            case .small: return AppTypography.title2
            case .medium: return AppTypography.statNumber
            case .large: return AppTypography.timer
            }
        }
        
        var labelFont: Font {
            switch self {
            case .small: return AppTypography.caption2
            case .medium: return AppTypography.caption1
            case .large: return AppTypography.footnote
            }
        }
        
        var padding: CGFloat {
            switch self {
            case .small: return AppSpacing.md
            case .medium: return AppSpacing.lg
            case .large: return AppSpacing.xl
            }
        }
    }
    
    init(
        label: String,
        value: String,
        unit: String? = nil,
        icon: String? = nil,
        trend: Trend? = nil,
        trendValue: String? = nil,
        color: Color = AppColors.textPrimary,
        size: Size = .medium
    ) {
        self.label = label
        self.value = value
        self.unit = unit
        self.icon = icon
        self.trend = trend
        self.trendValue = trendValue
        self.color = color
        self.size = size
    }
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        var description = "\(value)"
        if let unit = unit {
            description += " \(unit)"
        }
        if let trend = trend, let trendValue = trendValue {
            let trendText = trend == .up ? "up" : (trend == .down ? "down" : "unchanged")
            description += ", \(trendText) \(trendValue)"
        }
        return description
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Header row
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(size.labelFont)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Text(label.uppercased())
                    .font(size.labelFont)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textSecondary)
                    .tracking(0.5)
                
                Spacer()
                
                // Trend indicator
                if let trend = trend {
                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: trend.icon)
                            .font(.system(size: 10, weight: .bold))
                        if let trendValue = trendValue {
                            Text(trendValue)
                                .font(AppTypography.caption2)
                                .fontWeight(.medium)
                        }
                    }
                    .foregroundColor(trend.color)
                }
            }
            
            // Value
            HStack(alignment: .lastTextBaseline, spacing: AppSpacing.xxs) {
                Text(value)
                    .font(size.valueFont)
                    .foregroundColor(color)
                
                if let unit = unit {
                    Text(unit)
                        .font(size.labelFont)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding(size.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                .fill(AppColors.surface)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(accessibilityDescription)
    }
}

// MARK: - Stat Row (Three Stats Inline)

struct StatRow: View {
    let stats: [(label: String, value: String, unit: String?)]
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        stats.map { stat in
            if let unit = stat.unit {
                return "\(stat.label): \(stat.value) \(unit)"
            } else {
                return "\(stat.label): \(stat.value)"
            }
        }.joined(separator: ", ")
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<stats.count, id: \.self) { index in
                VStack(spacing: AppSpacing.xxs) {
                    Text(stats[index].value)
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack(spacing: AppSpacing.xxs) {
                        Text(stats[index].label)
                        if let unit = stats[index].unit {
                            Text("(\(unit))")
                        }
                    }
                    .font(AppTypography.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                
                if index < stats.count - 1 {
                    Rectangle()
                        .fill(AppColors.surfaceElevated)
                        .frame(width: 1, height: 40)
                }
            }
        }
        .padding(.vertical, AppSpacing.lg)
        .padding(.horizontal, AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                .fill(AppColors.surface)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Run statistics")
        .accessibilityValue(accessibilityDescription)
    }
}

// MARK: - Run Summary Card (Nike Run Club Style)

struct RunSummaryCard: View {
    let title: String?
    let date: String
    let distance: Double // in km
    let time: String     // formatted duration
    let pace: String     // e.g., "6'25\""
    let calories: Int?
    let elevation: Int?  // in meters
    let effortPoints: Int? // Ippo-specific: earned effort points
    let splits: [(km: Int, pace: String, intensity: Double)]?
    let onTap: (() -> Void)?
    
    init(
        title: String? = nil,
        date: String,
        distance: Double,
        time: String,
        pace: String,
        calories: Int? = nil,
        elevation: Int? = nil,
        effortPoints: Int? = nil,
        splits: [(km: Int, pace: String, intensity: Double)]? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.date = date
        self.distance = distance
        self.time = time
        self.pace = pace
        self.calories = calories
        self.elevation = elevation
        self.effortPoints = effortPoints
        self.splits = splits
        self.onTap = onTap
    }
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        var description = String(format: "%.2f kilometers in %@, pace %@ per kilometer", distance, time, pace)
        if let ep = effortPoints {
            description += ", \(ep) effort points"
        }
        if let elevation = elevation {
            description += ", \(elevation) meters elevation"
        }
        if let calories = calories {
            description += ", \(calories) calories"
        }
        if let splits = splits, !splits.isEmpty {
            description += ", \(splits.count) splits recorded"
        }
        return description
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Header
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                if let title = title {
                    Text(title)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                }
                Text(date)
                    .font(AppTypography.footnote)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Rectangle()
                .fill(AppColors.surfaceElevated)
                .frame(height: 1)
            
            // Primary stats
            HStack(spacing: AppSpacing.xl) {
                // Distance
                VStack(spacing: AppSpacing.xxs) {
                    Text(String(format: "%.2f", distance))
                        .font(AppTypography.statNumber)
                        .foregroundColor(AppColors.textPrimary)
                    Text("km")
                        .font(AppTypography.caption1)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                // Time
                VStack(spacing: AppSpacing.xxs) {
                    Text(time)
                        .font(AppTypography.statNumber)
                        .foregroundColor(AppColors.textPrimary)
                    Text("Time")
                        .font(AppTypography.caption1)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                // Pace
                VStack(spacing: AppSpacing.xxs) {
                    Text(pace)
                        .font(AppTypography.statNumber)
                        .foregroundColor(AppColors.textPrimary)
                    Text("/km")
                        .font(AppTypography.caption1)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            // Secondary stats (including Ippo effort points)
            if calories != nil || elevation != nil || effortPoints != nil {
                Rectangle()
                    .fill(AppColors.surfaceElevated)
                    .frame(height: 1)
                
                HStack(spacing: AppSpacing.xl) {
                    // Effort Points (Ippo-specific)
                    if let ep = effortPoints {
                        Label {
                            Text("\(ep) EP")
                                .font(AppTypography.footnote)
                                .fontWeight(.semibold)
                        } icon: {
                            Image(systemName: "bolt.fill")
                        }
                        .foregroundColor(AppColors.brandPrimary)
                    }
                    
                    if let elevation = elevation {
                        Label("\(elevation)m", systemImage: "arrow.up.right")
                            .font(AppTypography.footnote)
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    if let calories = calories {
                        Label("\(calories) kcal", systemImage: "flame.fill")
                            .font(AppTypography.footnote)
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            
            // Splits (if provided)
            if let splits = splits, !splits.isEmpty {
                Rectangle()
                    .fill(AppColors.surfaceElevated)
                    .frame(height: 1)
                
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("SPLITS")
                        .font(AppTypography.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textSecondary)
                        .tracking(0.5)
                    
                    ForEach(splits, id: \.km) { split in
                        HStack {
                            Text("\(split.km) km")
                                .font(AppTypography.footnote)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.textSecondary)
                                .frame(width: 50, alignment: .leading)
                            
                            Text(split.pace)
                                .font(AppTypography.currency)
                                .foregroundColor(AppColors.textPrimary)
                                .frame(width: 60)
                            
                            // Intensity bar
                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: AppSpacing.xxs)
                                    .fill(intensityColor(split.intensity))
                                    .frame(width: geo.size.width * split.intensity)
                            }
                            .frame(height: 12)
                        }
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.radiusLg)
                .fill(AppColors.surface)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title ?? "Run summary")
        .accessibilityValue(accessibilityDescription)
        .accessibilityHint(onTap != nil ? "Double tap to view details" : "")
        .accessibilityAddTraits(onTap != nil ? .isButton : [])
    }
    
    private func intensityColor(_ intensity: Double) -> Color {
        switch intensity {
        case 0..<0.5: return AppColors.brandPrimary  // Easy
        case 0.5..<0.7: return AppColors.success     // Moderate
        case 0.7..<0.85: return AppColors.warning    // Hard
        default: return AppColors.danger             // Max
        }
    }
}

// MARK: - Weekly Summary Card (Nike Run Club Style)

struct WeeklySummaryCard: View {
    let runs: Int
    let totalDistance: Double
    let totalTime: String
    let totalEffortPoints: Int // Ippo-specific
    let distanceChange: Double? // percentage vs last week
    let timeChange: Double?
    let runsChange: Int?
    let weekDays: Set<Int> // 0-6 for M-S
    
    init(
        runs: Int,
        totalDistance: Double,
        totalTime: String,
        totalEffortPoints: Int = 0,
        distanceChange: Double? = nil,
        timeChange: Double? = nil,
        runsChange: Int? = nil,
        weekDays: Set<Int>
    ) {
        self.runs = runs
        self.totalDistance = totalDistance
        self.totalTime = totalTime
        self.totalEffortPoints = totalEffortPoints
        self.distanceChange = distanceChange
        self.timeChange = timeChange
        self.runsChange = runsChange
        self.weekDays = weekDays
    }
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        var description = "\(runs) runs, \(String(format: "%.1f", totalDistance)) kilometers, \(totalTime)"
        if totalEffortPoints > 0 {
            description += ", \(totalEffortPoints) effort points"
        }
        if let change = distanceChange, change != 0 {
            let changeText = change > 0 ? "up" : "down"
            description += ", distance \(changeText) \(String(format: "%.1f", abs(change))) kilometers from last week"
        }
        description += ", \(weekDays.count) days active"
        return description
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Header
            HStack {
                Text("THIS WEEK")
                    .font(AppTypography.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textSecondary)
                    .tracking(0.5)
                
                Spacer()
                
                // Effort points highlight
                if totalEffortPoints > 0 {
                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12))
                        Text("\(totalEffortPoints) EP")
                            .font(AppTypography.caption1)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(AppColors.brandPrimary)
                }
            }
            
            // Stats row
            HStack(spacing: AppSpacing.xl) {
                // Runs
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    HStack(alignment: .lastTextBaseline, spacing: AppSpacing.xxs) {
                        Text("\(runs)")
                            .font(AppTypography.title2)
                            .foregroundColor(AppColors.textPrimary)
                        Text("runs")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    if let change = runsChange {
                        changeLabel(change > 0 ? "+\(change)" : "\(change)", isPositive: change > 0)
                    }
                }
                
                // Distance
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    HStack(alignment: .lastTextBaseline, spacing: AppSpacing.xxs) {
                        Text(String(format: "%.1f", totalDistance))
                            .font(AppTypography.title2)
                            .foregroundColor(AppColors.textPrimary)
                        Text("km")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    if let change = distanceChange {
                        changeLabel(String(format: "%+.1f km", change), isPositive: change > 0)
                    }
                }
                
                // Time
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(totalTime)
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.textPrimary)
                    if let change = timeChange {
                        changeLabel(String(format: "%+.0f min", change), isPositive: change > 0)
                    }
                }
            }
            
            Rectangle()
                .fill(AppColors.surfaceElevated)
                .frame(height: 1)
            
            // Week visualization
            WeeklyProgressDots(
                completedDays: weekDays,
                activeColor: AppColors.success,
                size: 28
            )
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.radiusLg)
                .fill(AppColors.surface)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("This week summary")
        .accessibilityValue(accessibilityDescription)
    }
    
    @ViewBuilder
    private func changeLabel(_ text: String, isPositive: Bool) -> some View {
        HStack(spacing: AppSpacing.xxs) {
            Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                .font(.system(size: 10, weight: .bold))
            Text(text)
                .font(AppTypography.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(isPositive ? AppColors.success : AppColors.danger)
    }
}

// MARK: - Personal Record Card (Strava Style)

struct PersonalRecordCard: View {
    let recordType: String // e.g., "5K", "10K", "Half Marathon"
    let newTime: String
    let previousTime: String
    let improvement: String
    let achievement: (name: String, icon: String)?
    let bonusEffortPoints: Int? // Ippo-specific: EP bonus for PR
    
    init(
        recordType: String,
        newTime: String,
        previousTime: String,
        improvement: String,
        achievement: (name: String, icon: String)? = nil,
        bonusEffortPoints: Int? = nil
    ) {
        self.recordType = recordType
        self.newTime = newTime
        self.previousTime = previousTime
        self.improvement = improvement
        self.achievement = achievement
        self.bonusEffortPoints = bonusEffortPoints
    }
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        var description = "\(recordType), new time \(newTime), \(improvement), previous best \(previousTime)"
        if let bonus = bonusEffortPoints {
            description += ", plus \(bonus) bonus effort points"
        }
        if let achievement = achievement {
            description += ", achievement unlocked: \(achievement.name)"
        }
        return description
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Header
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.gold)
                
                Text("NEW PERSONAL RECORD!")
                    .font(AppTypography.caption1)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.warning)
                
                Spacer()
                
                // Bonus EP
                if let bonus = bonusEffortPoints {
                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: "bolt.fill")
                        Text("+\(bonus) EP")
                    }
                    .font(AppTypography.caption1)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.brandPrimary)
                }
            }
            
            // Record details
            VStack(spacing: AppSpacing.sm) {
                Text(recordType)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textSecondary)
                
                Text(newTime)
                    .font(AppTypography.timer)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: AppSpacing.xxs) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 12, weight: .bold))
                    Text(improvement)
                        .font(AppTypography.footnote)
                        .fontWeight(.semibold)
                }
                .foregroundColor(AppColors.success)
                
                Text("Previous: \(previousTime)")
                    .font(AppTypography.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(.vertical, AppSpacing.lg)
            .padding(.horizontal, AppSpacing.xl)
            .background(
                RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                    .fill(AppColors.surfaceElevated)
            )
            
            // Achievement (if any)
            if let achievement = achievement {
                HStack {
                    Text(achievement.icon)
                        .font(.system(size: 24))
                    
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text("Achievement unlocked")
                            .font(AppTypography.caption2)
                            .foregroundColor(AppColors.textSecondary)
                        Text(achievement.name)
                            .font(AppTypography.footnote)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    Spacer()
                }
                .padding(AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppSpacing.radiusSm)
                        .fill(AppColors.brandSecondary.opacity(0.15))
                )
            }
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.radiusLg)
                .fill(AppColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.radiusLg)
                        .stroke(
                            LinearGradient(
                                colors: [AppColors.gold, AppColors.warning],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("New personal record")
        .accessibilityValue(accessibilityDescription)
    }
}

// MARK: - Effort Points Card (Ippo-specific)

struct EffortPointsCard: View {
    let earnedPoints: Int
    let goalPoints: Int
    let zoneTimes: [(zone: String, minutes: Int, color: Color)]
    
    private var progress: Double {
        guard goalPoints > 0 else { return 0 }
        return Double(earnedPoints) / Double(goalPoints)
    }
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        let percentComplete = Int(progress * 100)
        var description = "\(earnedPoints) of \(goalPoints) points, \(percentComplete) percent complete"
        if !zoneTimes.isEmpty {
            let zoneBreakdown = zoneTimes.map { "\($0.zone) \($0.minutes) minutes" }.joined(separator: ", ")
            description += ". Zone breakdown: \(zoneBreakdown)"
        }
        return description
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Header
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.brandPrimary)
                
                Text("EFFORT POINTS")
                    .font(AppTypography.caption1)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textSecondary)
                    .tracking(0.5)
                
                Spacer()
            }
            
            // Points display
            HStack(alignment: .lastTextBaseline) {
                Text("\(earnedPoints)")
                    .font(AppTypography.timer)
                    .foregroundColor(AppColors.brandPrimary)
                
                Text("/ \(goalPoints) EP")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: AppSpacing.xxs)
                        .fill(AppColors.surfaceElevated)
                    
                    RoundedRectangle(cornerRadius: AppSpacing.xxs)
                        .fill(
                            LinearGradient(
                                colors: [AppColors.brandPrimary.opacity(0.7), AppColors.brandPrimary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * min(progress, 1.0))
                }
            }
            .frame(height: 8)
            
            // Zone breakdown
            if !zoneTimes.isEmpty {
                Rectangle()
                    .fill(AppColors.surfaceElevated)
                    .frame(height: 1)
                
                VStack(spacing: AppSpacing.sm) {
                    ForEach(zoneTimes, id: \.zone) { zone in
                        HStack {
                            Circle()
                                .fill(zone.color)
                                .frame(width: 8, height: 8)
                            
                            Text(zone.zone)
                                .font(AppTypography.footnote)
                                .foregroundColor(AppColors.textSecondary)
                            
                            Spacer()
                            
                            Text("\(zone.minutes) min")
                                .font(AppTypography.footnote)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.radiusLg)
                .fill(AppColors.surface)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Effort points")
        .accessibilityValue(accessibilityDescription)
    }
}

// MARK: - Previews

#Preview("Stat Card") {
    ZStack {
        AppColors.background.ignoresSafeArea()
        
        VStack(spacing: AppSpacing.lg) {
            StatCard(
                label: "Distance",
                value: "5.02",
                unit: "km",
                icon: "figure.run",
                trend: .up,
                trendValue: "+12%"
            )
            
            StatCard(
                label: "Pace",
                value: "6'25\"",
                icon: "speedometer",
                size: .large
            )
        }
        .padding()
    }
}

#Preview("Stat Row") {
    ZStack {
        AppColors.background.ignoresSafeArea()
        
        StatRow(stats: [
            ("Distance", "5.02", "km"),
            ("Time", "32:14", nil),
            ("Pace", "6'25\"", "/km")
        ])
        .padding()
    }
}

#Preview("Run Summary") {
    ZStack {
        AppColors.background.ignoresSafeArea()
        
        RunSummaryCard(
            title: "Saturday Morning Run",
            date: "Feb 5, 2026 • 7:15 AM",
            distance: 5.02,
            time: "32:14",
            pace: "6'25\"",
            calories: 524,
            elevation: 45,
            effortPoints: 87,
            splits: [
                (1, "5'58\"", 0.4),
                (2, "6'12\"", 0.5),
                (3, "6'35\"", 0.65),
                (4, "6'45\"", 0.7),
                (5, "6'44\"", 0.7)
            ]
        )
        .padding()
    }
}

#Preview("Weekly Summary") {
    ZStack {
        AppColors.background.ignoresSafeArea()
        
        WeeklySummaryCard(
            runs: 3,
            totalDistance: 15.4,
            totalTime: "1:42:30",
            totalEffortPoints: 245,
            distanceChange: 3.2,
            timeChange: 22,
            runsChange: 1,
            weekDays: [0, 2, 4]
        )
        .padding()
    }
}

#Preview("Personal Record") {
    ZStack {
        AppColors.background.ignoresSafeArea()
        
        PersonalRecordCard(
            recordType: "5K",
            newTime: "23:45",
            previousTime: "24:17",
            improvement: "0:32 faster",
            achievement: (name: "Speed Demon - Sub 24min 5K", icon: "🏅"),
            bonusEffortPoints: 50
        )
        .padding()
    }
}

#Preview("Effort Points Card") {
    ZStack {
        AppColors.background.ignoresSafeArea()
        
        EffortPointsCard(
            earnedPoints: 87,
            goalPoints: 100,
            zoneTimes: [
                ("Easy", 8, AppColors.brandPrimary),
                ("Moderate", 15, AppColors.success),
                ("Hard", 7, AppColors.warning),
                ("Max", 2, AppColors.danger)
            ]
        )
        .padding()
    }
}
