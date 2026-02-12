// CelebrationModal.swift
// Adapted from Duolingo celebration patterns for Ippo
// Source: ~/clawd/tools/ui-ux/swiftui-components/CelebrationModal.swift
//
// Usage in Ippo:
//   CelebrationModal(
//     isPresented: $showCelebration,
//     title: "NEW RECORD!",
//     subtitle: "5K Personal Best",
//     primaryStat: "23:45",
//     secondaryStat: "↓ 32 seconds faster",
//     accentColor: AppColors.brandPrimary,
//     onDismiss: { }
//   )

import SwiftUI

// MARK: - Confetti Particle

struct ConfettiParticle: View {
    let color: Color
    let size: CGFloat
    let reduceMotion: Bool
    
    @State private var position: CGPoint = .zero
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: size, height: size * 2.5)
            .rotationEffect(.degrees(rotation))
            .position(position)
            .opacity(opacity)
            .onAppear {
                startAnimation()
            }
            // Decorative element - hide from VoiceOver
            .accessibilityHidden(true)
    }
    
    private func startAnimation() {
        // Random starting position at top
        let screenWidth = UIScreen.main.bounds.width
        position = CGPoint(
            x: CGFloat.random(in: 0...screenWidth),
            y: -20
        )
        rotation = Double.random(in: 0...360)
        
        // Respect reduce motion preference
        if reduceMotion {
            // Static confetti - just show briefly then fade
            position.y = CGFloat.random(in: 100...400)
            withAnimation(.easeOut(duration: 0.5)) {
                opacity = 0
            }
        } else {
            // Fall animation
            withAnimation(.easeIn(duration: Double.random(in: 2.5...4.0))) {
                position.y = UIScreen.main.bounds.height + 50
                position.x += CGFloat.random(in: -100...100)
                rotation += Double.random(in: 180...720)
            }
            
            // Fade out near end
            withAnimation(.easeIn(duration: 3.0).delay(1.5)) {
                opacity = 0
            }
        }
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    // Use Ippo's brand colors + semantic colors for confetti
    let colors: [Color] = [
        AppColors.brandPrimary,
        AppColors.brandSecondary,
        AppColors.success,
        AppColors.gold,
        AppColors.gems,
        AppColors.warning,
        AppColors.danger
    ]
    
    let particleCount: Int
    
    init(particleCount: Int = 50) {
        self.particleCount = particleCount
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { index in
                ConfettiParticle(
                    color: colors[index % colors.count],
                    size: CGFloat.random(in: 6...12),
                    reduceMotion: reduceMotion
                )
            }
        }
        .allowsHitTesting(false)
        // Entire confetti view is decorative
        .accessibilityHidden(true)
    }
}

// MARK: - Celebration Modal

struct CelebrationModal: View {
    @Binding var isPresented: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    let title: String
    let subtitle: String?
    let primaryStat: String
    let secondaryStat: String?
    let icon: String // SF Symbol name
    let iconColor: Color
    let accentColor: Color
    let onDismiss: () -> Void
    
    @State private var showContent = false
    @State private var showConfetti = false
    @State private var bounceScale: CGFloat = 0.5
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        var description = title
        if let subtitle = subtitle {
            description += ", \(subtitle)"
        }
        description += ". \(primaryStat)"
        if let secondaryStat = secondaryStat {
            description += ", \(secondaryStat)"
        }
        return description
    }
    
    init(
        isPresented: Binding<Bool>,
        title: String,
        subtitle: String? = nil,
        primaryStat: String,
        secondaryStat: String? = nil,
        icon: String = "trophy.fill",
        iconColor: Color = AppColors.gold,
        accentColor: Color = AppColors.brandPrimary,
        onDismiss: @escaping () -> Void = {}
    ) {
        self._isPresented = isPresented
        self.title = title
        self.subtitle = subtitle
        self.primaryStat = primaryStat
        self.secondaryStat = secondaryStat
        self.icon = icon
        self.iconColor = iconColor
        self.accentColor = accentColor
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        ZStack {
            // Backdrop - use Ippo's background
            AppColors.background.opacity(0.95)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            // Confetti layer
            if showConfetti {
                ConfettiView(particleCount: 60)
                    .ignoresSafeArea()
            }
            
            // Content
            VStack(spacing: AppSpacing.xl) {
                // Icon with glow
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(iconColor.opacity(0.3))
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)
                    
                    // Icon circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [iconColor, iconColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: icon)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                }
                .scaleEffect(bounceScale)
                .accessibilityHidden(true) // Icon is decorative
                
                // Title
                Text(title)
                    .font(AppTypography.largeTitle)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                // Subtitle
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                // Stats card
                VStack(spacing: AppSpacing.sm) {
                    Text(primaryStat)
                        .font(AppTypography.timer)
                        .foregroundColor(accentColor)
                    
                    if let secondaryStat = secondaryStat {
                        Text(secondaryStat)
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.success)
                    }
                }
                .padding(.vertical, AppSpacing.lg)
                .padding(.horizontal, AppSpacing.xxl)
                .background(
                    RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                        .fill(AppColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                                .stroke(AppColors.surfaceElevated, lineWidth: 1)
                        )
                )
                
                // Continue button
                Button(action: dismiss) {
                    Text("CONTINUE")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                                .fill(accentColor)
                        )
                }
                .accessibilityLabel("Continue")
                .accessibilityHint("Dismiss celebration and continue")
                .padding(.horizontal, AppSpacing.xxxl)
                .padding(.top, AppSpacing.sm)
            }
            .padding(AppSpacing.xxl)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 50)
            // VoiceOver: Announce the celebration as a single element
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Celebration")
            .accessibilityValue(accessibilityDescription)
            .accessibilityAddTraits(.isModal)
        }
        .onAppear {
            triggerCelebration()
        }
    }
    
    private func triggerCelebration() {
        // Trigger haptic (always - this is tactile, not motion)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Respect reduce motion preference
        if reduceMotion {
            // Instant appearance - no animations
            showContent = true
            bounceScale = 1.0
            // Still show confetti briefly (it will fade quickly due to reduceMotion)
            showConfetti = true
        } else {
            // Full animation experience
            
            // Show confetti immediately
            showConfetti = true
            
            // Animate content in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showContent = true
            }
            
            // Bounce the icon
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                bounceScale = 1.0
            }
            
            // Add a secondary bounce
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                    bounceScale = 1.1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        bounceScale = 1.0
                    }
                }
            }
        }
    }
    
    private func dismiss() {
        if reduceMotion {
            // Instant dismissal - no animation
            showContent = false
            showConfetti = false
            isPresented = false
            onDismiss()
        } else {
            // Animated dismissal
            withAnimation(.easeOut(duration: 0.2)) {
                showContent = false
                showConfetti = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isPresented = false
                onDismiss()
            }
        }
    }
}

// MARK: - Ippo-Specific Preset Variants

extension CelebrationModal {
    /// Personal Record celebration (gold trophy, brand accent)
    static func personalRecord(
        isPresented: Binding<Bool>,
        recordType: String,
        newTime: String,
        improvement: String,
        onDismiss: @escaping () -> Void = {}
    ) -> CelebrationModal {
        CelebrationModal(
            isPresented: isPresented,
            title: "NEW PERSONAL RECORD!",
            subtitle: recordType,
            primaryStat: newTime,
            secondaryStat: improvement,
            icon: "trophy.fill",
            iconColor: AppColors.gold,
            accentColor: AppColors.brandPrimary,
            onDismiss: onDismiss
        )
    }
    
    /// Achievement unlocked celebration (purple theme)
    static func achievementUnlocked(
        isPresented: Binding<Bool>,
        achievementName: String,
        description: String,
        onDismiss: @escaping () -> Void = {}
    ) -> CelebrationModal {
        CelebrationModal(
            isPresented: isPresented,
            title: "ACHIEVEMENT UNLOCKED!",
            subtitle: description,
            primaryStat: achievementName,
            secondaryStat: nil,
            icon: "star.fill",
            iconColor: AppColors.brandSecondary,
            accentColor: AppColors.brandSecondary,
            onDismiss: onDismiss
        )
    }
    
    /// Run completed celebration (green success theme)
    static func runCompleted(
        isPresented: Binding<Bool>,
        distance: String,
        duration: String,
        pace: String,
        onDismiss: @escaping () -> Void = {}
    ) -> CelebrationModal {
        CelebrationModal(
            isPresented: isPresented,
            title: "RUN COMPLETE!",
            subtitle: "\(duration) • \(pace)/km",
            primaryStat: distance,
            secondaryStat: nil,
            icon: "figure.run",
            iconColor: AppColors.success,
            accentColor: AppColors.success,
            onDismiss: onDismiss
        )
    }
    
    /// Streak milestone celebration (fire theme)
    static func streakMilestone(
        isPresented: Binding<Bool>,
        days: Int,
        onDismiss: @escaping () -> Void = {}
    ) -> CelebrationModal {
        CelebrationModal(
            isPresented: isPresented,
            title: "STREAK MILESTONE!",
            subtitle: "You're on fire! 🔥",
            primaryStat: "\(days) DAYS",
            secondaryStat: "Keep the momentum going!",
            icon: "flame.fill",
            iconColor: AppColors.warning,
            accentColor: AppColors.danger,
            onDismiss: onDismiss
        )
    }
    
    /// Pet unlocked celebration (rarity-based colors)
    static func petUnlocked(
        isPresented: Binding<Bool>,
        petName: String,
        rarity: Rarity,
        onDismiss: @escaping () -> Void = {}
    ) -> CelebrationModal {
        let rarityColor = AppColors.forRarity(rarity)
        return CelebrationModal(
            isPresented: isPresented,
            title: "NEW PET UNLOCKED!",
            subtitle: rarity.rawValue.uppercased(),
            primaryStat: petName,
            secondaryStat: "Added to your collection!",
            icon: "pawprint.fill",
            iconColor: rarityColor,
            accentColor: rarityColor,
            onDismiss: onDismiss
        )
    }
    
    /// Level up celebration (brand primary)
    static func levelUp(
        isPresented: Binding<Bool>,
        newLevel: Int,
        onDismiss: @escaping () -> Void = {}
    ) -> CelebrationModal {
        CelebrationModal(
            isPresented: isPresented,
            title: "LEVEL UP!",
            subtitle: "You reached a new level!",
            primaryStat: "LEVEL \(newLevel)",
            secondaryStat: "New abilities unlocked!",
            icon: "arrow.up.circle.fill",
            iconColor: AppColors.brandPrimary,
            accentColor: AppColors.brandPrimary,
            onDismiss: onDismiss
        )
    }
    
    /// Loot box opened celebration (gems theme)
    static func lootBoxOpened(
        isPresented: Binding<Bool>,
        itemName: String,
        rarity: Rarity,
        onDismiss: @escaping () -> Void = {}
    ) -> CelebrationModal {
        let rarityColor = AppColors.forRarity(rarity)
        return CelebrationModal(
            isPresented: isPresented,
            title: "LOOT ACQUIRED!",
            subtitle: rarity.rawValue.uppercased(),
            primaryStat: itemName,
            secondaryStat: nil,
            icon: "gift.fill",
            iconColor: rarityColor,
            accentColor: rarityColor,
            onDismiss: onDismiss
        )
    }
}

// MARK: - Preview

#Preview("Personal Record") {
    CelebrationModal(
        isPresented: .constant(true),
        title: "NEW PERSONAL RECORD!",
        subtitle: "5K Best Time",
        primaryStat: "23:45",
        secondaryStat: "↓ 32 seconds faster"
    )
}

#Preview("Achievement") {
    CelebrationModal.achievementUnlocked(
        isPresented: .constant(true),
        achievementName: "🏃 Speed Demon",
        description: "Run 5K under 25 minutes"
    )
}

#Preview("Run Complete") {
    CelebrationModal.runCompleted(
        isPresented: .constant(true),
        distance: "5.02 km",
        duration: "32:14",
        pace: "6'25\""
    )
}

#Preview("Streak Milestone") {
    CelebrationModal.streakMilestone(
        isPresented: .constant(true),
        days: 30
    )
}

#Preview("Level Up") {
    CelebrationModal.levelUp(
        isPresented: .constant(true),
        newLevel: 10
    )
}
