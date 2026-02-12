// AchievementBadge.swift
// Ippo - Achievement Badge Components
// Adapted from Duolingo achievements, Nike Run Club badges, Apple Fitness awards
//
// Usage:
// - AchievementsView: Display all achievement badges in a grid
// - HomeView: Show recent achievements earned
// - RunCompletedView: Display newly unlocked achievements
// - ProfileView: Achievement showcase/highlight reel

import SwiftUI

// MARK: - Achievement Model

struct IppoAchievement: Identifiable {
    let id: String
    let name: String
    let description: String
    let iconName: String  // SF Symbol name
    let category: AchievementCategory
    let tier: AchievementTier
    let isUnlocked: Bool
    let unlockedAt: Date?
    let progress: Double?  // 0.0-1.0 for progressive achievements
    let requirement: String  // e.g., "Run 10 km total"
    let epReward: Int  // Effort Points reward for unlocking
    
    enum AchievementCategory: String, CaseIterable {
        case distance = "Distance"
        case streak = "Streak"
        case speed = "Speed"
        case effort = "Effort"
        case pet = "Pet"
        case social = "Social"
        case milestone = "Milestone"
        
        var iconName: String {
            switch self {
            case .distance: return "figure.run"
            case .streak: return "flame.fill"
            case .speed: return "bolt.fill"
            case .effort: return "heart.fill"
            case .pet: return "pawprint.fill"
            case .social: return "person.2.fill"
            case .milestone: return "flag.checkered"
            }
        }
        
        var color: Color {
            switch self {
            case .distance: return AppColors.brandPrimary
            case .streak: return AppColors.warning
            case .speed: return AppColors.danger
            case .effort: return AppColors.success
            case .pet: return AppColors.brandSecondary
            case .social: return AppColors.gems
            case .milestone: return AppColors.gold
            }
        }
    }
    
    enum AchievementTier: String, CaseIterable {
        case bronze
        case silver
        case gold
        case platinum
        case diamond
        
        // Map to Ippo's rarity-based color system
        var color: Color {
            switch self {
            case .bronze: return AppColors.rarityCommon
            case .silver: return Color(hex: "#C0C0C0")  // Silver
            case .gold: return AppColors.gold
            case .platinum: return AppColors.rarityRare
            case .diamond: return AppColors.rarityLegendary
            }
        }
        
        var glowColor: Color {
            switch self {
            case .bronze: return AppColors.rarityCommon.opacity(0.5)
            case .silver: return Color.gray.opacity(0.5)
            case .gold: return AppColors.gold.opacity(0.6)
            case .platinum: return AppColors.rarityRare.opacity(0.7)
            case .diamond: return AppColors.rarityLegendary.opacity(0.7)
            }
        }
        
        var epMultiplier: Int {
            switch self {
            case .bronze: return 1
            case .silver: return 2
            case .gold: return 3
            case .platinum: return 5
            case .diamond: return 10
            }
        }
    }
}

// MARK: - Single Achievement Badge

struct AchievementBadge: View {
    let achievement: IppoAchievement
    var size: BadgeSize = .medium
    var showLabel: Bool = true
    var showEP: Bool = false
    var onTap: (() -> Void)? = nil
    
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        var description = achievement.name
        
        if achievement.isUnlocked {
            description += ", \(achievement.tier.rawValue) tier, unlocked"
            if showEP {
                description += ", \(achievement.epReward) effort points earned"
            }
        } else {
            if let progress = achievement.progress {
                description += ", locked, \(Int(progress * 100)) percent progress"
            } else {
                description += ", locked"
            }
            description += ", requirement: \(achievement.requirement)"
        }
        
        return description
    }
    
    enum BadgeSize {
        case small   // 48pt - for inline/compact displays
        case medium  // 72pt - default grid size
        case large   // 120pt - detail/featured display
        
        var dimension: CGFloat {
            switch self {
            case .small: return 48
            case .medium: return 72
            case .large: return 120
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 20
            case .medium: return 32
            case .large: return 52
            }
        }
        
        var fontSize: Font {
            switch self {
            case .small: return AppTypography.caption2
            case .medium: return AppTypography.caption1
            case .large: return AppTypography.callout
            }
        }
        
        var spacing: CGFloat {
            switch self {
            case .small: return AppSpacing.sm
            case .medium: return AppSpacing.sm
            case .large: return AppSpacing.md
            }
        }
    }
    
    var body: some View {
        VStack(spacing: size == .large ? AppSpacing.md : AppSpacing.sm) {
            // Badge circle
            ZStack {
                // Outer glow (unlocked only)
                if achievement.isUnlocked {
                    Circle()
                        .fill(achievement.tier.glowColor)
                        .frame(width: size.dimension + AppSpacing.sm, height: size.dimension + AppSpacing.sm)
                        .blur(radius: AppSpacing.sm)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                }
                
                // Background circle
                Circle()
                    .fill(
                        achievement.isUnlocked
                            ? LinearGradient(
                                colors: [
                                    achievement.tier.color,
                                    achievement.tier.color.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [AppColors.surface, AppColors.surfaceElevated],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .frame(width: size.dimension, height: size.dimension)
                
                // Inner highlight
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [AppColors.textPrimary.opacity(0.4), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: size.dimension - AppSpacing.xxs, height: size.dimension - AppSpacing.xxs)
                
                // Icon
                Image(systemName: achievement.iconName)
                    .font(.system(size: size.iconSize, weight: .semibold))
                    .foregroundColor(achievement.isUnlocked ? AppColors.textPrimary : AppColors.textTertiary)
                
                // Lock overlay (locked state)
                if !achievement.isUnlocked {
                    Circle()
                        .fill(AppColors.background.opacity(0.3))
                        .frame(width: size.dimension, height: size.dimension)
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: size.iconSize * 0.6))
                        .foregroundColor(AppColors.textSecondary)
                }
                
                // Progress ring (progressive achievements)
                if let progress = achievement.progress, !achievement.isUnlocked {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AppColors.brandPrimary,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: size.dimension + AppSpacing.xs, height: size.dimension + AppSpacing.xs)
                        .rotationEffect(.degrees(-90))
                }
            }
            .frame(width: size.dimension + AppSpacing.lg, height: size.dimension + AppSpacing.lg)
            .contentShape(Circle())
            .onTapGesture {
                if achievement.isUnlocked {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
                onTap?()
            }
            
            // Label
            if showLabel {
                VStack(spacing: AppSpacing.xxxs) {
                    Text(achievement.name)
                        .font(size.fontSize)
                        .fontWeight(.semibold)
                        .foregroundColor(achievement.isUnlocked ? AppColors.textPrimary : AppColors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    if size == .large {
                        Text(achievement.description)
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    
                    // EP reward display
                    if showEP && achievement.isUnlocked {
                        HStack(spacing: AppSpacing.xxxs) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 10))
                            Text("+\(achievement.epReward) EP")
                                .font(AppTypography.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(AppColors.brandPrimary)
                    }
                }
                .frame(width: size.dimension + AppSpacing.lg)
            }
        }
        .onAppear {
            if achievement.isUnlocked && !reduceMotion {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(achievement.name)
        .accessibilityValue(accessibilityDescription)
        .accessibilityAddTraits(onTap != nil ? .isButton : [])
        .accessibilityHint(onTap != nil ? "Double tap to view details" : "")
    }
}

// MARK: - Achievement Badge Grid

struct AchievementBadgeGrid: View {
    let achievements: [IppoAchievement]
    var columns: Int = 3
    var showProgress: Bool = true
    var onBadgeTap: ((IppoAchievement) -> Void)? = nil
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: AppSpacing.lg), count: columns)
    }
    
    // MARK: - Accessibility
    private var progressAccessibilityDescription: String {
        let unlockedCount = achievements.filter { $0.isUnlocked }.count
        let totalEP = achievements.filter { $0.isUnlocked }.reduce(0) { $0 + $1.epReward }
        return "\(unlockedCount) of \(achievements.count) achievements unlocked, \(totalEP) effort points earned"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Progress header
            if showProgress {
                HStack {
                    let unlockedCount = achievements.filter { $0.isUnlocked }.count
                    let totalEP = achievements.filter { $0.isUnlocked }.reduce(0) { $0 + $1.epReward }
                    
                    VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                        Text("\(unlockedCount)/\(achievements.count) Unlocked")
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                        
                        HStack(spacing: AppSpacing.xxs) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 12))
                            Text("\(totalEP) EP earned")
                                .font(AppTypography.caption1)
                        }
                        .foregroundColor(AppColors.brandPrimary)
                    }
                    
                    Spacer()
                    
                    // Mini progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(AppColors.surface)
                            
                            Capsule()
                                .fill(AppColors.brandPrimary)
                                .frame(width: geo.size.width * (Double(unlockedCount) / Double(max(achievements.count, 1))))
                        }
                    }
                    .frame(width: 100, height: 6)
                }
                .padding(.horizontal, AppSpacing.xxs)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Achievement progress")
                .accessibilityValue(progressAccessibilityDescription)
            }
            
            // Grid
            LazyVGrid(columns: gridColumns, spacing: AppSpacing.xl) {
                ForEach(achievements) { achievement in
                    AchievementBadge(
                        achievement: achievement,
                        size: .medium,
                        onTap: { onBadgeTap?(achievement) }
                    )
                }
            }
        }
    }
}

// MARK: - Achievement Category Section

struct AchievementCategorySection: View {
    let category: IppoAchievement.AchievementCategory
    let achievements: [IppoAchievement]
    var onBadgeTap: ((IppoAchievement) -> Void)? = nil
    
    // MARK: - Accessibility
    private var categoryAccessibilityDescription: String {
        let unlockedCount = achievements.filter { $0.isUnlocked }.count
        return "\(unlockedCount) of \(achievements.count) \(category.rawValue) achievements unlocked"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Section header
            HStack {
                Image(systemName: category.iconName)
                    .foregroundColor(category.color)
                
                Text(category.rawValue)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                let unlockedCount = achievements.filter { $0.isUnlocked }.count
                Text("\(unlockedCount)/\(achievements.count)")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // Horizontal scroll for category
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.lg) {
                    ForEach(achievements) { achievement in
                        AchievementBadge(
                            achievement: achievement,
                            size: .medium,
                            onTap: { onBadgeTap?(achievement) }
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.xxs)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(category.rawValue) achievements")
        .accessibilityValue(categoryAccessibilityDescription)
    }
}

// MARK: - Achievement Unlock Animation

struct AchievementUnlockView: View {
    let achievement: IppoAchievement
    var onDismiss: () -> Void
    
    @State private var showBadge = false
    @State private var showDetails = false
    @State private var showConfetti = false
    @State private var badgeScale: CGFloat = 0.5
    @State private var badgeRotation: Double = -180
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    // MARK: - Accessibility
    private var unlockAccessibilityDescription: String {
        "\(achievement.name), \(achievement.tier.rawValue) tier, \(achievement.description), plus \(achievement.epReward) effort points"
    }
    
    var body: some View {
        ZStack {
            // Dimmed background
            AppColors.background.opacity(0.95)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            VStack(spacing: AppSpacing.xxl) {
                // "Achievement Unlocked" label
                if showDetails {
                    Text("ACHIEVEMENT UNLOCKED")
                        .font(AppTypography.caption1)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textSecondary)
                        .tracking(3)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // Animated badge
                if showBadge {
                    AchievementBadge(
                        achievement: achievement,
                        size: .large,
                        showLabel: false
                    )
                    .scaleEffect(badgeScale)
                    .rotationEffect(.degrees(badgeRotation))
                }
                
                // Achievement details
                if showDetails {
                    VStack(spacing: AppSpacing.sm) {
                        Text(achievement.name)
                            .font(AppTypography.title2)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(achievement.description)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        // EP reward
                        HStack(spacing: AppSpacing.xxs) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 16))
                            Text("+\(achievement.epReward) EP")
                                .font(AppTypography.headline)
                        }
                        .foregroundColor(AppColors.brandPrimary)
                        .padding(.top, AppSpacing.sm)
                        
                        // Tier badge
                        Text(achievement.tier.rawValue.uppercased())
                            .font(AppTypography.caption1)
                            .fontWeight(.bold)
                            .foregroundColor(achievement.tier.color)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.xxs)
                            .background(achievement.tier.color.opacity(0.2))
                            .cornerRadius(AppSpacing.radiusMd)
                            .padding(.top, AppSpacing.sm)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                // Dismiss button
                if showDetails {
                    Button(action: onDismiss) {
                        Text("Awesome!")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)
                            .frame(width: 200, height: 50)
                            .background(AppColors.brandPrimary)
                            .cornerRadius(AppSpacing.radiusXl)
                    }
                    .padding(.top, AppSpacing.lg)
                    .transition(.opacity)
                }
            }
            .padding(AppSpacing.xxl)
            
            // Confetti overlay (decorative, hidden from VoiceOver)
            if showConfetti {
                IppoAchievementConfetti(reduceMotion: reduceMotion)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Achievement unlocked")
        .accessibilityValue(unlockAccessibilityDescription)
        .accessibilityAddTraits(.isModal)
        .onAppear {
            animateUnlock()
        }
    }
    
    private func animateUnlock() {
        if reduceMotion {
            // Instant appearance for reduce motion
            showBadge = true
            badgeScale = 1.0
            badgeRotation = 0
            showDetails = true
            // Still show confetti briefly (will fade, not animate)
            showConfetti = true
            
            // Haptic feedback still fires
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        } else {
            // Step 1: Show badge with spin-in animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showBadge = true
                badgeScale = 1.2
                badgeRotation = 0
            }
            
            // Step 2: Badge settles + confetti
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    badgeScale = 1.0
                }
                showConfetti = true
                
                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.impactOccurred()
            }
            
            // Step 3: Show details
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showDetails = true
                }
            }
        }
    }
}

// Ippo-branded confetti overlay
private struct IppoAchievementConfetti: View {
    let reduceMotion: Bool
    @State private var particles: [AchievementConfettiParticle] = []
    @State private var fadeOpacity: Double = 1.0
    
    // Ippo brand colors for confetti
    private let confettiColors: [Color] = [
        AppColors.brandPrimary,
        AppColors.brandSecondary,
        AppColors.success,
        AppColors.gold,
        AppColors.gems,
        AppColors.warning,
        AppColors.danger
    ]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if reduceMotion {
                    // Static confetti that fades
                    ForEach(0..<30, id: \.self) { i in
                        Circle()
                            .fill(confettiColors[i % confettiColors.count])
                            .frame(width: CGFloat.random(in: 6...12), height: CGFloat.random(in: 6...12))
                            .position(
                                x: CGFloat.random(in: 0...geo.size.width),
                                y: CGFloat.random(in: 0...geo.size.height)
                            )
                    }
                    .opacity(fadeOpacity)
                    .onAppear {
                        withAnimation(.easeOut(duration: 1.5)) {
                            fadeOpacity = 0
                        }
                    }
                } else {
                    // Animated falling confetti
                    ForEach(particles) { particle in
                        Circle()
                            .fill(particle.color)
                            .frame(width: particle.size, height: particle.size)
                            .position(particle.position)
                            .opacity(particle.opacity)
                    }
                }
            }
            .onAppear {
                if !reduceMotion {
                    createParticles(in: geo.size)
                }
            }
        }
        .allowsHitTesting(false)
    }
    
    private func createParticles(in size: CGSize) {
        for i in 0..<50 {
            let particle = AchievementConfettiParticle(
                id: i,
                color: confettiColors.randomElement()!,
                size: CGFloat.random(in: 6...12),
                position: CGPoint(x: size.width / 2, y: -20),
                opacity: 1.0
            )
            particles.append(particle)
            
            // Animate each particle
            let delay = Double(i) * 0.02
            let endX = CGFloat.random(in: 0...size.width)
            let endY = size.height + 50
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: Double.random(in: 1.5...2.5))) {
                    if let index = particles.firstIndex(where: { $0.id == i }) {
                        particles[index].position = CGPoint(x: endX, y: endY)
                        particles[index].opacity = 0
                    }
                }
            }
        }
    }
}

private struct AchievementConfettiParticle: Identifiable {
    let id: Int
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
}

// MARK: - Recent Achievements Row

struct RecentAchievementsRow: View {
    let achievements: [IppoAchievement]
    var maxVisible: Int = 3
    var onViewAll: (() -> Void)? = nil
    
    private var recentUnlocked: [IppoAchievement] {
        achievements
            .filter { $0.isUnlocked }
            .sorted { ($0.unlockedAt ?? .distantPast) > ($1.unlockedAt ?? .distantPast) }
            .prefix(maxVisible)
            .map { $0 }
    }
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        if recentUnlocked.isEmpty {
            return "No achievements unlocked yet. Complete runs to earn badges."
        }
        let names = recentUnlocked.map { $0.name }.joined(separator: ", ")
        let totalEP = recentUnlocked.reduce(0) { $0 + $1.epReward }
        return "\(recentUnlocked.count) recent achievements: \(names). \(totalEP) effort points total."
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Recent Achievements")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                if let onViewAll = onViewAll {
                    Button("View All") {
                        onViewAll()
                    }
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.brandPrimary)
                }
            }
            
            if recentUnlocked.isEmpty {
                // Empty state
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "trophy")
                        .font(.title2)
                        .foregroundColor(AppColors.textTertiary)
                    
                    VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                        Text("No achievements yet")
                            .font(AppTypography.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.textPrimary)
                        Text("Complete runs to earn badges")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.cardPadding)
                .background(AppColors.surface)
                .cornerRadius(AppSpacing.radiusMd)
            } else {
                // Recent badges
                HStack(spacing: AppSpacing.lg) {
                    ForEach(recentUnlocked) { achievement in
                        AchievementBadge(
                            achievement: achievement,
                            size: .small,
                            showLabel: true,
                            showEP: true
                        )
                    }
                    
                    Spacer()
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Recent achievements")
        .accessibilityValue(accessibilityDescription)
    }
}

// MARK: - Achievement Detail Sheet

struct AchievementDetailSheet: View {
    let achievement: IppoAchievement
    @Environment(\.dismiss) var dismiss
    
    // MARK: - Accessibility
    private var detailAccessibilityDescription: String {
        var desc = "\(achievement.name), \(achievement.tier.rawValue) tier, \(achievement.category.rawValue) category"
        if achievement.isUnlocked {
            desc += ", unlocked"
            if let date = achievement.unlockedAt {
                desc += " on \(date.formatted(date: .abbreviated, time: .omitted))"
            }
        } else {
            if let progress = achievement.progress {
                desc += ", \(Int(progress * 100)) percent progress"
            } else {
                desc += ", locked"
            }
        }
        desc += ", \(achievement.epReward) effort points reward, requirement: \(achievement.requirement)"
        return desc
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: AppSpacing.xl) {
                    // Large badge
                    AchievementBadge(
                        achievement: achievement,
                        size: .large,
                        showLabel: false
                    )
                    .padding(.top, AppSpacing.xxl)
                    
                    // Name and description
                    VStack(spacing: AppSpacing.sm) {
                        Text(achievement.name)
                            .font(AppTypography.title1)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(achievement.description)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Details card
                    VStack(spacing: AppSpacing.lg) {
                        AchievementDetailRow(
                            icon: "folder",
                            label: "Category",
                            value: achievement.category.rawValue,
                            valueColor: achievement.category.color
                        )
                        
                        AchievementDetailRow(
                            icon: "star",
                            label: "Tier",
                            value: achievement.tier.rawValue.capitalized,
                            valueColor: achievement.tier.color
                        )
                        
                        AchievementDetailRow(
                            icon: "bolt.fill",
                            label: "EP Reward",
                            value: "+\(achievement.epReward) EP",
                            valueColor: AppColors.brandPrimary
                        )
                        
                        AchievementDetailRow(
                            icon: "target",
                            label: "Requirement",
                            value: achievement.requirement
                        )
                        
                        if let unlockedAt = achievement.unlockedAt {
                            AchievementDetailRow(
                                icon: "calendar",
                                label: "Unlocked",
                                value: unlockedAt.formatted(date: .abbreviated, time: .omitted)
                            )
                        }
                        
                        if let progress = achievement.progress, !achievement.isUnlocked {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                HStack {
                                    Image(systemName: "chart.bar.fill")
                                        .foregroundColor(AppColors.textSecondary)
                                    Text("Progress")
                                        .foregroundColor(AppColors.textSecondary)
                                    Spacer()
                                    Text("\(Int(progress * 100))%")
                                        .fontWeight(.medium)
                                        .foregroundColor(AppColors.textPrimary)
                                }
                                .font(AppTypography.subheadline)
                                
                                ProgressView(value: progress)
                                    .tint(AppColors.brandPrimary)
                            }
                        }
                    }
                    .padding(AppSpacing.cardPadding)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.radiusLg)
                    .padding(.horizontal, AppSpacing.screenPadding)
                    
                    Spacer()
                }
            }
            .navigationTitle("Achievement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.brandPrimary)
                    .accessibilityLabel("Done")
                    .accessibilityHint("Dismiss achievement details")
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Achievement details")
            .accessibilityValue(detailAccessibilityDescription)
        }
    }
}

private struct AchievementDetailRow: View {
    let icon: String
    let label: String
    let value: String
    var valueColor: Color = AppColors.textPrimary
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .accessibilityHidden(true)
                .foregroundColor(AppColors.textSecondary)
                .frame(width: AppSpacing.xl)
            
            Text(label)
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(AppTypography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Ippo-Specific Achievement Presets

extension IppoAchievement {
    // Distance achievements
    static func firstRun() -> IppoAchievement {
        IppoAchievement(
            id: "first-run",
            name: "First Steps",
            description: "Complete your first run",
            iconName: "figure.run",
            category: .milestone,
            tier: .bronze,
            isUnlocked: false,
            unlockedAt: nil,
            progress: nil,
            requirement: "Complete 1 run",
            epReward: 50
        )
    }
    
    static func distance5K() -> IppoAchievement {
        IppoAchievement(
            id: "distance-5k",
            name: "5K Club",
            description: "Run 5 kilometers total",
            iconName: "figure.run.circle.fill",
            category: .distance,
            tier: .bronze,
            isUnlocked: false,
            unlockedAt: nil,
            progress: nil,
            requirement: "Run 5 km total",
            epReward: 100
        )
    }
    
    static func distance10K() -> IppoAchievement {
        IppoAchievement(
            id: "distance-10k",
            name: "10K Warrior",
            description: "Run 10 kilometers total",
            iconName: "figure.run.circle.fill",
            category: .distance,
            tier: .silver,
            isUnlocked: false,
            unlockedAt: nil,
            progress: nil,
            requirement: "Run 10 km total",
            epReward: 200
        )
    }
    
    // Streak achievements
    static func weekStreak() -> IppoAchievement {
        IppoAchievement(
            id: "streak-7",
            name: "Week Warrior",
            description: "Run every day for 7 days",
            iconName: "flame.fill",
            category: .streak,
            tier: .silver,
            isUnlocked: false,
            unlockedAt: nil,
            progress: nil,
            requirement: "7 day streak",
            epReward: 150
        )
    }
    
    static func monthStreak() -> IppoAchievement {
        IppoAchievement(
            id: "streak-30",
            name: "Month Master",
            description: "Run every day for 30 days",
            iconName: "flame.fill",
            category: .streak,
            tier: .gold,
            isUnlocked: false,
            unlockedAt: nil,
            progress: nil,
            requirement: "30 day streak",
            epReward: 500
        )
    }
    
    // Effort achievements
    static func maxEffort() -> IppoAchievement {
        IppoAchievement(
            id: "max-effort-10min",
            name: "Max Effort",
            description: "Spend 10 minutes in max effort zone",
            iconName: "heart.fill",
            category: .effort,
            tier: .gold,
            isUnlocked: false,
            unlockedAt: nil,
            progress: nil,
            requirement: "10 min in max zone",
            epReward: 300
        )
    }
    
    // Pet achievements
    static func firstPet() -> IppoAchievement {
        IppoAchievement(
            id: "first-pet",
            name: "Pet Parent",
            description: "Unlock your first pet",
            iconName: "pawprint.fill",
            category: .pet,
            tier: .bronze,
            isUnlocked: false,
            unlockedAt: nil,
            progress: nil,
            requirement: "Unlock 1 pet",
            epReward: 100
        )
    }
    
    static func petCollector() -> IppoAchievement {
        IppoAchievement(
            id: "pet-collector-10",
            name: "Pet Collector",
            description: "Collect 10 different pets",
            iconName: "pawprint.circle.fill",
            category: .pet,
            tier: .gold,
            isUnlocked: false,
            unlockedAt: nil,
            progress: nil,
            requirement: "Collect 10 pets",
            epReward: 500
        )
    }
}

// MARK: - Previews

#Preview("Badge Sizes") {
    let sampleAchievement = IppoAchievement(
        id: "first-run",
        name: "First Run",
        description: "Complete your first run",
        iconName: "figure.run",
        category: .milestone,
        tier: .bronze,
        isUnlocked: true,
        unlockedAt: Date(),
        progress: nil,
        requirement: "Complete 1 run",
        epReward: 50
    )
    
    let lockedAchievement = IppoAchievement(
        id: "marathon",
        name: "Marathon",
        description: "Run a total of 42.2 km",
        iconName: "flag.checkered",
        category: .distance,
        tier: .gold,
        isUnlocked: false,
        unlockedAt: nil,
        progress: 0.35,
        requirement: "Run 42.2 km total",
        epReward: 1000
    )
    
    return ZStack {
        AppColors.background.ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: AppSpacing.xxl) {
                Text("Unlocked Badge Sizes")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: AppSpacing.xxl) {
                    AchievementBadge(achievement: sampleAchievement, size: .small, showEP: true)
                    AchievementBadge(achievement: sampleAchievement, size: .medium, showEP: true)
                    AchievementBadge(achievement: sampleAchievement, size: .large, showEP: true)
                }
                
                Divider().background(AppColors.surface)
                
                Text("Locked Badge (with progress)")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: AppSpacing.xxl) {
                    AchievementBadge(achievement: lockedAchievement, size: .small)
                    AchievementBadge(achievement: lockedAchievement, size: .medium)
                    AchievementBadge(achievement: lockedAchievement, size: .large)
                }
            }
            .padding(AppSpacing.screenPadding)
        }
    }
}

#Preview("Achievement Grid") {
    let achievements: [IppoAchievement] = [
        IppoAchievement(id: "1", name: "First Run", description: "Complete your first run", iconName: "figure.run", category: .milestone, tier: .bronze, isUnlocked: true, unlockedAt: Date(), progress: nil, requirement: "Complete 1 run", epReward: 50),
        IppoAchievement(id: "2", name: "Week Warrior", description: "Run every day for a week", iconName: "flame.fill", category: .streak, tier: .silver, isUnlocked: true, unlockedAt: Date().addingTimeInterval(-86400), progress: nil, requirement: "7 day streak", epReward: 150),
        IppoAchievement(id: "3", name: "Speed Demon", description: "Complete a run at 5:00/km pace", iconName: "bolt.fill", category: .speed, tier: .gold, isUnlocked: false, unlockedAt: nil, progress: 0.8, requirement: "Run at 5:00/km pace", epReward: 300),
        IppoAchievement(id: "4", name: "Max Effort", description: "Spend 10 min in max effort zone", iconName: "heart.fill", category: .effort, tier: .platinum, isUnlocked: false, unlockedAt: nil, progress: 0.45, requirement: "10 min in max zone", epReward: 500),
        IppoAchievement(id: "5", name: "Pet Collector", description: "Collect 10 pets", iconName: "pawprint.fill", category: .pet, tier: .gold, isUnlocked: false, unlockedAt: nil, progress: 0.6, requirement: "Collect 10 pets", epReward: 500),
        IppoAchievement(id: "6", name: "Marathon", description: "Run a marathon distance total", iconName: "flag.checkered", category: .distance, tier: .diamond, isUnlocked: false, unlockedAt: nil, progress: 0.2, requirement: "Run 42.2 km", epReward: 2000),
    ]
    
    return ZStack {
        AppColors.background.ignoresSafeArea()
        
        ScrollView {
            AchievementBadgeGrid(
                achievements: achievements,
                onBadgeTap: { print("Tapped \($0.name)") }
            )
            .padding(AppSpacing.screenPadding)
        }
    }
}

#Preview("Tier Colors") {
    let tiers = IppoAchievement.AchievementTier.allCases
    
    return ZStack {
        AppColors.background.ignoresSafeArea()
        
        VStack(spacing: AppSpacing.lg) {
            ForEach(tiers, id: \.self) { tier in
                let achievement = IppoAchievement(
                    id: tier.rawValue,
                    name: tier.rawValue.capitalized,
                    description: "\(tier.rawValue.capitalized) tier badge",
                    iconName: "star.fill",
                    category: .milestone,
                    tier: tier,
                    isUnlocked: true,
                    unlockedAt: Date(),
                    progress: nil,
                    requirement: "Sample",
                    epReward: 100 * tier.epMultiplier
                )
                
                HStack {
                    AchievementBadge(achievement: achievement, size: .medium, showEP: true)
                    
                    VStack(alignment: .leading) {
                        Text("EP Multiplier: \(tier.epMultiplier)x")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(AppSpacing.screenPadding)
    }
}

#Preview("Unlock Animation") {
    AchievementUnlockView(
        achievement: IppoAchievement(
            id: "speed-demon",
            name: "Speed Demon",
            description: "Complete a run at 5:00/km pace or faster",
            iconName: "bolt.fill",
            category: .speed,
            tier: .gold,
            isUnlocked: true,
            unlockedAt: Date(),
            progress: nil,
            requirement: "Run at 5:00/km pace",
            epReward: 300
        ),
        onDismiss: { print("Dismissed") }
    )
}

#Preview("Recent Achievements Row") {
    let achievements: [IppoAchievement] = [
        IppoAchievement(id: "1", name: "First Run", description: "Complete your first run", iconName: "figure.run", category: .milestone, tier: .bronze, isUnlocked: true, unlockedAt: Date(), progress: nil, requirement: "Complete 1 run", epReward: 50),
        IppoAchievement(id: "2", name: "Week Warrior", description: "7 day streak", iconName: "flame.fill", category: .streak, tier: .silver, isUnlocked: true, unlockedAt: Date().addingTimeInterval(-86400), progress: nil, requirement: "7 day streak", epReward: 150),
        IppoAchievement(id: "3", name: "Speed Demon", description: "Fast pace", iconName: "bolt.fill", category: .speed, tier: .gold, isUnlocked: true, unlockedAt: Date().addingTimeInterval(-172800), progress: nil, requirement: "5:00/km pace", epReward: 300),
    ]
    
    return ZStack {
        AppColors.background.ignoresSafeArea()
        
        VStack(spacing: AppSpacing.xl) {
            RecentAchievementsRow(
                achievements: achievements,
                onViewAll: { print("View all") }
            )
            .padding(AppSpacing.screenPadding)
            
            Divider().background(AppColors.surface)
            
            // Empty state
            RecentAchievementsRow(
                achievements: [],
                onViewAll: { print("View all") }
            )
            .padding(AppSpacing.screenPadding)
        }
    }
}

#Preview("Category Section") {
    let achievements: [IppoAchievement] = [
        IppoAchievement(id: "1", name: "5K Club", description: "Run 5km", iconName: "figure.run.circle.fill", category: .distance, tier: .bronze, isUnlocked: true, unlockedAt: Date(), progress: nil, requirement: "Run 5 km", epReward: 100),
        IppoAchievement(id: "2", name: "10K Warrior", description: "Run 10km", iconName: "figure.run.circle.fill", category: .distance, tier: .silver, isUnlocked: true, unlockedAt: nil, progress: nil, requirement: "Run 10 km", epReward: 200),
        IppoAchievement(id: "3", name: "Half Marathon", description: "Run 21.1km", iconName: "figure.run.circle.fill", category: .distance, tier: .gold, isUnlocked: false, unlockedAt: nil, progress: 0.6, requirement: "Run 21.1 km", epReward: 500),
        IppoAchievement(id: "4", name: "Marathon", description: "Run 42.2km", iconName: "flag.checkered", category: .distance, tier: .diamond, isUnlocked: false, unlockedAt: nil, progress: 0.3, requirement: "Run 42.2 km", epReward: 2000),
    ]
    
    return ZStack {
        AppColors.background.ignoresSafeArea()
        
        AchievementCategorySection(
            category: .distance,
            achievements: achievements
        )
        .padding(AppSpacing.screenPadding)
    }
}
