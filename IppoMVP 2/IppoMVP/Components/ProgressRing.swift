// ProgressRing.swift
// Adapted from Apple Fitness activity rings pattern
// Customized for Ippo's design system
//
// Source: ~/clawd/tools/ui-ux/TOP-APP-PATTERNS.md (Apple Fitness section)
// Pattern: Circular progress indicator with customizable appearance
//
// Usage:
//   ProgressRing(progress: 0.75, color: AppColors.success, size: 100)
//   
//   ActivityRings(
//     move: 0.84, exercise: 0.93, stand: 0.83,
//     size: 150
//   )
//
//   EffortRing(currentEffort: 0.72, targetEffort: 0.7, size: 120)

import SwiftUI

// MARK: - Single Progress Ring

struct ProgressRing: View {
    let progress: Double // 0.0 to 1.0 (can exceed 1.0 for overflow)
    let color: Color
    let size: CGFloat
    let lineWidth: CGFloat
    let showLabel: Bool
    let labelFormat: LabelFormat
    
    enum LabelFormat {
        case percentage
        case fraction(current: Int, total: Int)
        case custom(String)
        case none
    }
    
    @State private var animatedProgress: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    init(
        progress: Double,
        color: Color = AppColors.brandPrimary,
        size: CGFloat = 100,
        lineWidth: CGFloat? = nil,
        showLabel: Bool = true,
        labelFormat: LabelFormat = .percentage
    ) {
        self.progress = progress
        self.color = color
        self.size = size
        self.lineWidth = lineWidth ?? (size * 0.15)
        self.showLabel = showLabel
        self.labelFormat = labelFormat
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    color.opacity(0.2),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
            
            // Progress ring
            Circle()
                .trim(from: 0, to: min(animatedProgress, 1.0))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [color.opacity(0.8), color]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * min(animatedProgress, 1.0))
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            // Overflow ring (if progress > 1.0)
            if animatedProgress > 1.0 {
                Circle()
                    .trim(from: 0, to: min(animatedProgress - 1.0, 1.0))
                    .stroke(
                        color.opacity(0.6),
                        style: StrokeStyle(lineWidth: lineWidth * 0.5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            }
            
            // End cap glow
            if animatedProgress > 0.05 {
                Circle()
                    .fill(color)
                    .frame(width: lineWidth, height: lineWidth)
                    .offset(y: -size / 2 + lineWidth / 2)
                    .rotationEffect(.degrees(360 * min(animatedProgress, 1.0) - 90))
                    .shadow(color: color.opacity(0.5), radius: 4)
            }
            
            // Center label
            if showLabel {
                labelView
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue(accessibilityValueText)
        .onAppear {
            if reduceMotion {
                animatedProgress = progress
            } else {
                withAnimation(.easeOut(duration: 1.0)) {
                    animatedProgress = progress
                }
            }
        }
        .onChange(of: progress) { newValue in
            if reduceMotion {
                animatedProgress = newValue
            } else {
                withAnimation(.easeOut(duration: 0.5)) {
                    animatedProgress = newValue
                }
            }
        }
    }
    
    private var accessibilityValueText: String {
        switch labelFormat {
        case .percentage:
            return "\(Int(min(progress, 1.0) * 100)) percent complete"
        case .fraction(let current, let total):
            return "\(current) of \(total)"
        case .custom(let text):
            return text.replacingOccurrences(of: "\n", with: ", ")
        case .none:
            return "\(Int(min(progress, 1.0) * 100)) percent"
        }
    }
    
    @ViewBuilder
    private var labelView: some View {
        switch labelFormat {
        case .percentage:
            Text("\(Int(min(progress, 1.0) * 100))%")
                .font(size > 80 ? AppTypography.statNumber : AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)
        case .fraction(let current, let total):
            VStack(spacing: 0) {
                Text("\(current)")
                    .font(size > 80 ? AppTypography.statNumber : AppTypography.title2)
                    .foregroundColor(AppColors.textPrimary)
                Text("/\(total)")
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textSecondary)
            }
        case .custom(let text):
            Text(text)
                .font(AppTypography.footnote)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
        case .none:
            EmptyView()
        }
    }
}

// MARK: - Apple Fitness-style Activity Rings

struct ActivityRings: View {
    let move: Double      // Red ring (calories)
    let exercise: Double  // Green ring (minutes)
    let stand: Double     // Blue ring (hours)
    let size: CGFloat
    let showLabels: Bool
    
    init(
        move: Double,
        exercise: Double,
        stand: Double,
        size: CGFloat = 150,
        showLabels: Bool = true
    ) {
        self.move = move
        self.exercise = exercise
        self.stand = stand
        self.size = size
        self.showLabels = showLabels
    }
    
    private var ringSpacing: CGFloat { size * 0.12 }
    private var lineWidth: CGFloat { size * 0.11 }
    
    var body: some View {
        ZStack {
            // Move ring (outermost, red/danger)
            ProgressRing(
                progress: move,
                color: AppColors.danger,
                size: size,
                lineWidth: lineWidth,
                showLabel: false
            )
            
            // Exercise ring (middle, green/success)
            ProgressRing(
                progress: exercise,
                color: AppColors.success,
                size: size - ringSpacing * 2,
                lineWidth: lineWidth,
                showLabel: false
            )
            
            // Stand ring (innermost, cyan/brandPrimary)
            ProgressRing(
                progress: stand,
                color: AppColors.brandPrimary,
                size: size - ringSpacing * 4,
                lineWidth: lineWidth,
                showLabel: false
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Activity rings")
        .accessibilityValue("Move \(Int(move * 100)) percent, Exercise \(Int(exercise * 100)) percent, Stand \(Int(stand * 100)) percent")
    }
}

// MARK: - Ippo Effort Ring (Custom for Effort-Based Gameplay)

struct EffortRing: View {
    let currentEffort: Double // 0.0 to 1.0 (percentage of max effort)
    let targetEffort: Double  // Target zone (e.g., 0.7 for zone 3)
    let size: CGFloat
    
    @State private var animatedEffort: Double = 0
    @State private var isPulsing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    /// Ippo's effort zone colors matching the effort-based gameplay system
    private var effortColor: Color {
        switch animatedEffort {
        case 0..<0.5: return AppColors.brandPrimary   // Recovery/Easy - Cyan
        case 0.5..<0.7: return AppColors.success      // Moderate - Green
        case 0.7..<0.85: return AppColors.warning     // Hard - Orange
        default: return AppColors.danger              // Max - Red
        }
    }
    
    private var zoneName: String {
        switch animatedEffort {
        case 0..<0.5: return "EASY"
        case 0.5..<0.7: return "MODERATE"
        case 0.7..<0.85: return "HARD"
        default: return "MAX"
        }
    }
    
    init(
        currentEffort: Double,
        targetEffort: Double = 0.7,
        size: CGFloat = 120
    ) {
        self.currentEffort = currentEffort
        self.targetEffort = targetEffort
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Background ring with zone markers
            Circle()
                .stroke(AppColors.surface, lineWidth: size * 0.12)
            
            // Target zone indicator
            Circle()
                .trim(from: targetEffort - 0.05, to: targetEffort + 0.05)
                .stroke(
                    AppColors.textTertiary,
                    style: StrokeStyle(lineWidth: size * 0.14, lineCap: .butt)
                )
                .rotationEffect(.degrees(-90))
            
            // Current effort arc
            Circle()
                .trim(from: 0, to: animatedEffort)
                .stroke(
                    effortColor,
                    style: StrokeStyle(lineWidth: size * 0.12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: effortColor.opacity(0.5), radius: isPulsing ? 10 : 5)
            
            // Center content
            VStack(spacing: AppSpacing.xxs) {
                Text("\(Int(animatedEffort * 100))")
                    .font(AppTypography.timer)
                    .foregroundColor(effortColor)
                
                Text(zoneName)
                    .font(AppTypography.caption1)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Effort level")
        .accessibilityValue("\(Int(animatedEffort * 100)) percent, \(zoneName) zone")
        .onAppear {
            if reduceMotion {
                animatedEffort = currentEffort
            } else {
                withAnimation(.easeOut(duration: 0.8)) {
                    animatedEffort = currentEffort
                }
                // Pulse animation for high effort
                if currentEffort >= 0.85 {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                }
            }
        }
        .onChange(of: currentEffort) { newValue in
            if reduceMotion {
                animatedEffort = newValue
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    animatedEffort = newValue
                }
            }
        }
    }
}

// MARK: - Ippo Daily Effort Goal Ring

struct DailyEffortRing: View {
    let earnedPoints: Int
    let goalPoints: Int
    let size: CGFloat
    
    private var progress: Double {
        guard goalPoints > 0 else { return 0 }
        return Double(earnedPoints) / Double(goalPoints)
    }
    
    init(earnedPoints: Int, goalPoints: Int = 100, size: CGFloat = 150) {
        self.earnedPoints = earnedPoints
        self.goalPoints = goalPoints
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Multi-color ring based on progress
            ProgressRing(
                progress: progress,
                color: progressColor,
                size: size,
                showLabel: false
            )
            
            // Center content
            VStack(spacing: AppSpacing.xxs) {
                Text("\(earnedPoints)")
                    .font(AppTypography.timer)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("/ \(goalPoints) EP")
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textSecondary)
                
                if progress >= 1.0 {
                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                        Text("GOAL MET")
                            .font(AppTypography.caption2)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(AppColors.success)
                    .padding(.top, AppSpacing.xxs)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Daily Effort Points")
        .accessibilityValue("\(earnedPoints) of \(goalPoints) points, \(Int(progress * 100)) percent\(progress >= 1.0 ? ", goal met" : "")")
    }
    
    private var progressColor: Color {
        switch progress {
        case 0..<0.25: return AppColors.danger
        case 0.25..<0.5: return AppColors.warning
        case 0.5..<0.75: return AppColors.brandPrimary
        case 0.75..<1.0: return AppColors.success
        default: return AppColors.gold // Goal exceeded
        }
    }
}

// MARK: - Streak Counter (Duolingo-inspired)

struct StreakCounter: View {
    let days: Int
    let isActive: Bool // Did user complete today?
    let size: CGFloat
    
    @State private var flameScale: CGFloat = 1.0
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    init(days: Int, isActive: Bool = true, size: CGFloat = 60) {
        self.days = days
        self.isActive = isActive
        self.size = size
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Fire icon
            ZStack {
                // Glow
                if isActive {
                    Image(systemName: "flame.fill")
                        .font(.system(size: size * 0.6))
                        .foregroundColor(AppColors.warning)
                        .blur(radius: 8)
                        .opacity(isAnimating ? 0.8 : 0.4)
                }
                
                Image(systemName: "flame.fill")
                    .font(.system(size: size * 0.6))
                    .foregroundStyle(
                        isActive ?
                        LinearGradient(
                            colors: [AppColors.gold, AppColors.warning, AppColors.danger],
                            startPoint: .top,
                            endPoint: .bottom
                        ) :
                        LinearGradient(
                            colors: [AppColors.textTertiary, AppColors.surface],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(flameScale)
            }
            
            // Day count
            VStack(alignment: .leading, spacing: 0) {
                Text("\(days)")
                    .font(AppTypography.statNumber)
                    .foregroundColor(isActive ? AppColors.warning : AppColors.textTertiary)
                
                Text("day streak")
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                .fill(AppColors.surface)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Running streak")
        .accessibilityValue("\(days) day streak, \(isActive ? "active today" : "not active today")")
        .onAppear {
            if isActive && !reduceMotion {
                // Subtle flame animation
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
                // Bounce on appear
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                    flameScale = 1.15
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        flameScale = 1.0
                    }
                }
            }
        }
    }
}

// MARK: - Weekly Progress Dots

struct WeeklyProgressDots: View {
    let completedDays: Set<Int> // 0 = Monday, 6 = Sunday
    let activeColor: Color
    let size: CGFloat
    
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
    
    init(
        completedDays: Set<Int>,
        activeColor: Color = AppColors.success,
        size: CGFloat = 32
    ) {
        self.completedDays = completedDays
        self.activeColor = activeColor
        self.size = size
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ForEach(0..<7, id: \.self) { day in
                VStack(spacing: AppSpacing.xxs) {
                    // Day label
                    Text(dayLabels[day])
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.textSecondary)
                    
                    // Dot
                    Circle()
                        .fill(completedDays.contains(day) ? activeColor : AppColors.surface)
                        .frame(width: size * 0.6, height: size * 0.6)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Weekly progress")
        .accessibilityValue("\(completedDays.count) of 7 days completed")
    }
}

// MARK: - Previews

#Preview("Progress Ring") {
    ZStack {
        AppColors.background.ignoresSafeArea()
        
        VStack(spacing: AppSpacing.xxl) {
            ProgressRing(progress: 0.75, color: AppColors.success, size: 120)
            
            ProgressRing(
                progress: 0.6,
                color: AppColors.brandPrimary,
                size: 100,
                labelFormat: .fraction(current: 3, total: 5)
            )
            
            ProgressRing(
                progress: 1.25,
                color: AppColors.warning,
                size: 80,
                labelFormat: .custom("125%\nOverflow!")
            )
        }
        .padding()
    }
}

#Preview("Activity Rings") {
    ZStack {
        AppColors.background.ignoresSafeArea()
        
        ActivityRings(
            move: 0.84,
            exercise: 0.93,
            stand: 0.83,
            size: 200
        )
        .padding()
    }
}

#Preview("Effort Ring") {
    ZStack {
        AppColors.background.ignoresSafeArea()
        
        VStack(spacing: AppSpacing.xxl) {
            EffortRing(currentEffort: 0.45, size: 150)
            EffortRing(currentEffort: 0.72, size: 150)
            EffortRing(currentEffort: 0.92, size: 150)
        }
        .padding()
    }
}

#Preview("Daily Effort Ring") {
    ZStack {
        AppColors.background.ignoresSafeArea()
        
        VStack(spacing: AppSpacing.xxl) {
            DailyEffortRing(earnedPoints: 42, goalPoints: 100, size: 180)
            DailyEffortRing(earnedPoints: 100, goalPoints: 100, size: 180)
            DailyEffortRing(earnedPoints: 150, goalPoints: 100, size: 180)
        }
        .padding()
    }
}

#Preview("Streak Counter") {
    ZStack {
        AppColors.background.ignoresSafeArea()
        
        VStack(spacing: AppSpacing.xl) {
            StreakCounter(days: 142, isActive: true, size: 60)
            StreakCounter(days: 5, isActive: false, size: 60)
        }
        .padding()
    }
}

#Preview("Weekly Progress") {
    ZStack {
        AppColors.background.ignoresSafeArea()
        
        WeeklyProgressDots(
            completedDays: [0, 2, 4],
            activeColor: AppColors.success,
            size: 40
        )
        .padding()
    }
}
