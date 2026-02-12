// EffortZones.swift
// Adapted from Nike Run Club pace zones and heart rate zone displays for Ippo
// Source: ~/clawd/tools/ui-ux/swiftui-components/EffortZones.swift
//
// Usage in Ippo:
//   EffortZoneBar(zones: [
//     EffortZone(zone: 1, label: "Recovery", minutes: 2),
//     EffortZone(zone: 2, label: "Easy", minutes: 8),
//     EffortZone(zone: 3, label: "Moderate", minutes: 15),
//     EffortZone(zone: 4, label: "Hard", minutes: 10),
//     EffortZone(zone: 5, label: "Max", minutes: 3)
//   ])
//
//   LiveEffortIndicator(currentZone: 3, heartRate: 145, effortPercentage: 0.72)
//
//   EffortPointsZoneBar(zones: zones, totalEP: 250) // Ippo-specific EP variant

import SwiftUI

// MARK: - Effort Zone Colors

/// Ippo's effort zone color mapping
/// Derived from brand colors for consistent visual language
enum EffortZoneColors {
    /// Zone 1: Recovery - Muted/passive state
    static let recovery = AppColors.textTertiary
    /// Zone 2: Easy - Brand primary (cyan) - Ippo's signature color
    static let easy = AppColors.brandPrimary
    /// Zone 3: Moderate - Success (green) - Good steady effort
    static let moderate = AppColors.success
    /// Zone 4: Hard - Warning (orange) - Pushing limits
    static let hard = AppColors.warning
    /// Zone 5: Max - Danger (red) - All out effort
    static let max = AppColors.danger
    
    static func forZone(_ zone: Int) -> Color {
        switch zone {
        case 1: return recovery
        case 2: return easy
        case 3: return moderate
        case 4: return hard
        case 5: return max
        default: return AppColors.textTertiary
        }
    }
    
    static func labelForZone(_ zone: Int) -> String {
        switch zone {
        case 1: return "RECOVERY"
        case 2: return "EASY"
        case 3: return "MODERATE"
        case 4: return "HARD"
        case 5: return "MAX"
        default: return "---"
        }
    }
}

// MARK: - Zone Data Model

struct EffortZone: Identifiable {
    let id = UUID()
    let zone: Int
    let label: String
    let minutes: Double
    
    var color: Color {
        EffortZoneColors.forZone(zone)
    }
    
    var percentage: Double {
        // Calculated externally based on total
        0
    }
    
    static let defaultZones: [EffortZone] = [
        EffortZone(zone: 1, label: "Recovery", minutes: 0),
        EffortZone(zone: 2, label: "Easy", minutes: 0),
        EffortZone(zone: 3, label: "Moderate", minutes: 0),
        EffortZone(zone: 4, label: "Hard", minutes: 0),
        EffortZone(zone: 5, label: "Max", minutes: 0)
    ]
}

// MARK: - Horizontal Effort Zone Bar

struct EffortZoneBar: View {
    let zones: [EffortZone]
    let totalMinutes: Double
    let height: CGFloat
    let showLabels: Bool
    
    init(
        zones: [EffortZone],
        height: CGFloat = AppSpacing.xl,
        showLabels: Bool = true
    ) {
        self.zones = zones
        self.totalMinutes = zones.reduce(0) { $0 + $1.minutes }
        self.height = height
        self.showLabels = showLabels
    }
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        let activeZones = zones.filter { $0.minutes > 0 }
        if activeZones.isEmpty { return "No effort zone data" }
        
        let descriptions = activeZones.map { zone in
            let percentage = totalMinutes > 0 ? Int((zone.minutes / totalMinutes) * 100) : 0
            return "Zone \(zone.zone) \(zone.label): \(percentage)%, \(formatMinutes(zone.minutes))"
        }
        return "Effort zones breakdown. " + descriptions.joined(separator: ". ")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Stacked bar
            GeometryReader { geometry in
                HStack(spacing: AppSpacing.xxxs) {
                    ForEach(zones.filter { $0.minutes > 0 }) { zone in
                        let width = max(
                            (zone.minutes / totalMinutes) * geometry.size.width - AppSpacing.xxxs,
                            0
                        )
                        
                        RoundedRectangle(cornerRadius: AppSpacing.xxs)
                            .fill(zone.color)
                            .frame(width: width)
                    }
                }
            }
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.xs))
            
            // Labels below
            if showLabels {
                HStack(spacing: AppSpacing.md) {
                    ForEach(zones.filter { $0.minutes > 0 }) { zone in
                        HStack(spacing: AppSpacing.xxs) {
                            Circle()
                                .fill(zone.color)
                                .frame(width: AppSpacing.sm, height: AppSpacing.sm)
                            
                            Text("Z\(zone.zone)")
                                .font(AppTypography.caption2)
                                .foregroundColor(AppColors.textSecondary)
                            
                            Text(formatMinutes(zone.minutes))
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Effort zone distribution")
        .accessibilityValue(accessibilityDescription)
    }
    
    private func formatMinutes(_ minutes: Double) -> String {
        if minutes >= 60 {
            let hours = Int(minutes) / 60
            let mins = Int(minutes) % 60
            return "\(hours)h\(mins)m"
        }
        return "\(Int(minutes))m"
    }
}

// MARK: - Ippo Effort Points Zone Bar

/// Ippo-specific variant showing EP earned per zone
struct EffortPointsZoneBar: View {
    let zones: [EffortZone]
    let totalEP: Int
    let epByZone: [Int: Int] // zone -> EP earned
    
    init(zones: [EffortZone], totalEP: Int, epByZone: [Int: Int] = [:]) {
        self.zones = zones
        self.totalEP = totalEP
        self.epByZone = epByZone
    }
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        let activeZones = zones.filter { $0.minutes > 0 }
        var descriptions = ["Total \(totalEP) Effort Points"]
        
        for zone in activeZones.reversed() {
            let ep = epByZone[zone.zone] ?? 0
            if ep > 0 {
                descriptions.append("Zone \(zone.zone) \(zone.label): \(ep) points")
            }
        }
        return descriptions.joined(separator: ". ")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header with total EP
            HStack {
                Text("EFFORT BREAKDOWN")
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textSecondary)
                    .tracking(0.5)
                
                Spacer()
                
                HStack(spacing: AppSpacing.xxs) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.brandPrimary)
                    Text("\(totalEP) EP")
                        .font(AppTypography.currency)
                        .foregroundColor(AppColors.brandPrimary)
                }
            }
            
            // Zone breakdown
            ForEach(zones.filter { $0.minutes > 0 }.reversed()) { zone in
                let ep = epByZone[zone.zone] ?? 0
                
                HStack(spacing: AppSpacing.md) {
                    // Zone badge
                    ZStack {
                        Circle()
                            .fill(zone.color)
                            .frame(width: 28, height: 28)
                        Text("\(zone.zone)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(zone.zone == 1 ? AppColors.textPrimary : .white)
                    }
                    
                    // Zone label + time
                    VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                        Text(zone.label)
                            .font(AppTypography.footnote)
                            .foregroundColor(AppColors.textPrimary)
                        Text(formatMinutes(zone.minutes))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // EP earned in this zone
                    if ep > 0 {
                        Text("+\(ep) EP")
                            .font(AppTypography.currency)
                            .foregroundColor(zone.color)
                    }
                }
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                .fill(AppColors.surface)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Effort Points breakdown")
        .accessibilityValue(accessibilityDescription)
    }
    
    private func formatMinutes(_ minutes: Double) -> String {
        if minutes >= 60 {
            let hours = Int(minutes) / 60
            let mins = Int(minutes) % 60
            return "\(hours)h \(mins)m"
        }
        return "\(Int(minutes))m"
    }
}

// MARK: - Vertical Effort Zone Breakdown

struct EffortZoneBreakdown: View {
    let zones: [EffortZone]
    let totalMinutes: Double
    
    init(zones: [EffortZone]) {
        self.zones = zones
        self.totalMinutes = zones.reduce(0) { $0 + $1.minutes }
    }
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        var descriptions: [String] = []
        for zone in zones.reversed() {
            let percentage = totalMinutes > 0 ? Int((zone.minutes / totalMinutes) * 100) : 0
            descriptions.append("Zone \(zone.zone): \(percentage) percent")
        }
        descriptions.append("Total: \(formatTotalTime(totalMinutes))")
        return descriptions.joined(separator: ". ")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            Text("EFFORT ZONES")
                .font(AppTypography.caption1)
                .foregroundColor(AppColors.textSecondary)
                .tracking(0.5)
            
            // Zone bars
            ForEach(zones.reversed()) { zone in
                let percentage = totalMinutes > 0 ? zone.minutes / totalMinutes : 0
                
                HStack(spacing: AppSpacing.md) {
                    // Zone label
                    Text("Zone \(zone.zone)")
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 60, alignment: .leading)
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: AppSpacing.xxs)
                                .fill(AppColors.surfaceElevated)
                            
                            // Fill
                            RoundedRectangle(cornerRadius: AppSpacing.xxs)
                                .fill(zone.color)
                                .frame(width: geometry.size.width * percentage)
                        }
                    }
                    .frame(height: AppSpacing.lg)
                    
                    // Percentage
                    Text("\(Int(percentage * 100))%")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .frame(width: 40, alignment: .trailing)
                        .foregroundColor(zone.minutes > 0 ? AppColors.textPrimary : AppColors.textTertiary)
                }
            }
            
            // Total time
            HStack {
                Text("Total:")
                    .font(AppTypography.footnote)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                Text(formatTotalTime(totalMinutes))
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(AppColors.textPrimary)
            }
            .padding(.top, AppSpacing.xxs)
        }
        .padding(AppSpacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                .fill(AppColors.surface)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Effort zones")
        .accessibilityValue(accessibilityDescription)
    }
    
    private func formatTotalTime(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        let secs = Int((minutes - Double(Int(minutes))) * 60)
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, mins, secs)
        }
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Live Effort Indicator (During Run)

struct LiveEffortIndicator: View {
    let currentZone: Int
    let heartRate: Int?
    let effortPercentage: Double // 0.0 to 1.0
    let currentEP: Int?
    
    @State private var isPulsing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private var zoneColor: Color {
        EffortZoneColors.forZone(currentZone)
    }
    
    private var zoneName: String {
        EffortZoneColors.labelForZone(currentZone)
    }
    
    init(currentZone: Int, heartRate: Int? = nil, effortPercentage: Double, currentEP: Int? = nil) {
        self.currentZone = currentZone
        self.heartRate = heartRate
        self.effortPercentage = effortPercentage
        self.currentEP = currentEP
    }
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        var parts: [String] = [
            "Zone \(currentZone), \(zoneName)",
            "\(Int(effortPercentage * 100)) percent effort"
        ]
        if let hr = heartRate {
            parts.append("\(hr) beats per minute")
        }
        if let ep = currentEP {
            parts.append("\(ep) Effort Points")
        }
        return parts.joined(separator: ". ")
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.lg) {
            // Zone indicator circle
            ZStack {
                // Pulsing background for high zones (respects reduceMotion)
                if currentZone >= 4 && !reduceMotion {
                    Circle()
                        .fill(zoneColor.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .scaleEffect(isPulsing ? 1.2 : 1.0)
                }
                
                Circle()
                    .fill(zoneColor)
                    .frame(width: 50, height: 50)
                
                Text("\(currentZone)")
                    .font(AppTypography.title2)
                    .foregroundColor(currentZone == 1 ? AppColors.textPrimary : .white)
            }
            
            // Zone details
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(zoneName)
                    .font(AppTypography.headline)
                    .foregroundColor(zoneColor)
                
                if let hr = heartRate {
                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.danger)
                        Text("\(hr) BPM")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                // Ippo: Show current EP earned
                if let ep = currentEP {
                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.brandPrimary)
                        Text("\(ep) EP")
                            .font(AppTypography.currency)
                            .foregroundColor(AppColors.brandPrimary)
                    }
                }
            }
            
            Spacer()
            
            // Effort bar (vertical)
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: AppSpacing.xxs)
                    .fill(AppColors.surfaceElevated)
                    .frame(width: AppSpacing.md, height: 60)
                
                RoundedRectangle(cornerRadius: AppSpacing.xxs)
                    .fill(zoneColor)
                    .frame(width: AppSpacing.md, height: 60 * effortPercentage)
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                .fill(AppColors.surface.opacity(0.95))
                .shadow(color: zoneColor.opacity(0.3), radius: 10)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Live effort indicator")
        .accessibilityValue(accessibilityDescription)
        .onAppear {
            // Only animate if reduceMotion is OFF
            if currentZone >= 4 && !reduceMotion {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
        }
        .onChange(of: currentZone) { oldValue, newValue in
            // Haptic feedback on zone change
            if newValue >= 4 && oldValue < 4 {
                let impact = UIImpactFeedbackGenerator(style: .heavy)
                impact.impactOccurred()
            } else if newValue != oldValue {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            }
        }
    }
}

// MARK: - Compact Live Effort (for Watch/Overlay)

struct CompactEffortIndicator: View {
    let currentZone: Int
    let effortPercentage: Double
    
    private var zoneColor: Color {
        EffortZoneColors.forZone(currentZone)
    }
    
    private var zoneName: String {
        EffortZoneColors.labelForZone(currentZone)
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            // Zone badge
            ZStack {
                Circle()
                    .fill(zoneColor)
                    .frame(width: 32, height: 32)
                Text("\(currentZone)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(currentZone == 1 ? AppColors.textPrimary : .white)
            }
            
            // Mini progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: AppSpacing.xxxs)
                        .fill(AppColors.surfaceElevated)
                    
                    RoundedRectangle(cornerRadius: AppSpacing.xxxs)
                        .fill(zoneColor)
                        .frame(width: geometry.size.width * effortPercentage)
                }
            }
            .frame(height: AppSpacing.sm)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(
            Capsule()
                .fill(AppColors.surface.opacity(0.9))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Effort zone")
        .accessibilityValue("Zone \(currentZone), \(zoneName), \(Int(effortPercentage * 100)) percent")
    }
}

// MARK: - Zone Legend

struct EffortZoneLegend: View {
    let zones: [(zone: Int, label: String, hrRange: String)] = [
        (1, "Recovery", "< 60%"),
        (2, "Easy", "60-70%"),
        (3, "Moderate", "70-80%"),
        (4, "Hard", "80-90%"),
        (5, "Max", "90-100%")
    ]
    
    let showEPMultipliers: Bool
    
    // EP multipliers per zone (Ippo-specific)
    let epMultipliers: [Int: String] = [
        1: "0.5x",
        2: "1x",
        3: "1.5x",
        4: "2x",
        5: "3x"
    ]
    
    init(showEPMultipliers: Bool = true) {
        self.showEPMultipliers = showEPMultipliers
    }
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        var descriptions: [String] = []
        for zone in zones {
            var desc = "Zone \(zone.zone), \(zone.label), heart rate \(zone.hrRange)"
            if showEPMultipliers, let mult = epMultipliers[zone.zone] {
                desc += ", \(mult) Effort Points multiplier"
            }
            descriptions.append(desc)
        }
        return descriptions.joined(separator: ". ")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("EFFORT ZONES")
                .font(AppTypography.caption1)
                .foregroundColor(AppColors.textSecondary)
                .tracking(0.5)
            
            ForEach(zones, id: \.zone) { zone in
                HStack(spacing: AppSpacing.md) {
                    // Zone badge
                    ZStack {
                        Circle()
                            .fill(EffortZoneColors.forZone(zone.zone))
                            .frame(width: 28, height: 28)
                        Text("\(zone.zone)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(zone.zone == 1 ? AppColors.textPrimary : .white)
                    }
                    
                    // Label
                    Text(zone.label)
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 70, alignment: .leading)
                    
                    // HR Range
                    Text(zone.hrRange)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    // EP Multiplier (Ippo-specific)
                    if showEPMultipliers, let mult = epMultipliers[zone.zone] {
                        HStack(spacing: AppSpacing.xxxs) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 10))
                                .foregroundColor(AppColors.brandPrimary)
                            Text(mult)
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(AppColors.brandPrimary)
                        }
                    }
                }
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                .fill(AppColors.surface)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Effort zone legend")
        .accessibilityValue(accessibilityDescription)
    }
}

// MARK: - Run Summary Zone Distribution

/// Shows post-run zone distribution with visual pie/donut chart
struct ZoneDistributionChart: View {
    let zones: [EffortZone]
    let totalMinutes: Double
    
    init(zones: [EffortZone]) {
        self.zones = zones
        self.totalMinutes = zones.reduce(0) { $0 + $1.minutes }
    }
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        let activeZones = zones.filter { $0.minutes > 0 }
        var descriptions = ["Total time: \(formatTotalTime(totalMinutes))"]
        
        for zone in activeZones {
            let percentage = totalMinutes > 0 ? Int((zone.minutes / totalMinutes) * 100) : 0
            descriptions.append("Zone \(zone.zone): \(percentage) percent")
        }
        return descriptions.joined(separator: ". ")
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Donut chart
            ZStack {
                ForEach(zones.indices, id: \.self) { index in
                    let zone = zones[index]
                    let percentage = totalMinutes > 0 ? zone.minutes / totalMinutes : 0
                    let startAngle = startAngle(for: index)
                    let endAngle = startAngle + (360 * percentage)
                    
                    if zone.minutes > 0 {
                        DonutSegment(
                            startAngle: .degrees(startAngle),
                            endAngle: .degrees(endAngle),
                            thickness: 24
                        )
                        .fill(zone.color)
                    }
                }
                
                // Center content
                VStack(spacing: AppSpacing.xxxs) {
                    Text(formatTotalTime(totalMinutes))
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.textPrimary)
                    Text("TOTAL")
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .frame(width: 140, height: 140)
            
            // Legend
            HStack(spacing: AppSpacing.lg) {
                ForEach(zones.filter { $0.minutes > 0 }) { zone in
                    let percentage = totalMinutes > 0 ? (zone.minutes / totalMinutes) * 100 : 0
                    
                    VStack(spacing: AppSpacing.xxs) {
                        Circle()
                            .fill(zone.color)
                            .frame(width: AppSpacing.sm, height: AppSpacing.sm)
                        Text("Z\(zone.zone)")
                            .font(AppTypography.caption2)
                            .foregroundColor(AppColors.textSecondary)
                        Text("\(Int(percentage))%")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Zone distribution chart")
        .accessibilityValue(accessibilityDescription)
    }
    
    private func startAngle(for index: Int) -> Double {
        var angle: Double = -90 // Start from top
        for i in 0..<index {
            let percentage = totalMinutes > 0 ? zones[i].minutes / totalMinutes : 0
            angle += 360 * percentage
        }
        return angle
    }
    
    private func formatTotalTime(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
}

// MARK: - Donut Segment Shape

struct DonutSegment: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var thickness: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius - thickness
        
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: endAngle,
            endAngle: startAngle,
            clockwise: true
        )
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Previews

#Preview("Effort Zone Bar") {
    VStack(spacing: 30) {
        EffortZoneBar(zones: [
            EffortZone(zone: 1, label: "Recovery", minutes: 2),
            EffortZone(zone: 2, label: "Easy", minutes: 8),
            EffortZone(zone: 3, label: "Moderate", minutes: 15),
            EffortZone(zone: 4, label: "Hard", minutes: 10),
            EffortZone(zone: 5, label: "Max", minutes: 3)
        ])
        
        EffortZoneBar(zones: [
            EffortZone(zone: 2, label: "Easy", minutes: 25),
            EffortZone(zone: 3, label: "Moderate", minutes: 5)
        ], height: 32, showLabels: false)
    }
    .padding(AppSpacing.screenPadding)
    .background(AppColors.background)
}

#Preview("EP Zone Bar - Ippo") {
    EffortPointsZoneBar(
        zones: [
            EffortZone(zone: 2, label: "Easy", minutes: 10),
            EffortZone(zone: 3, label: "Moderate", minutes: 15),
            EffortZone(zone: 4, label: "Hard", minutes: 8),
            EffortZone(zone: 5, label: "Max", minutes: 2)
        ],
        totalEP: 250,
        epByZone: [2: 50, 3: 100, 4: 64, 5: 36]
    )
    .padding(AppSpacing.screenPadding)
    .background(AppColors.background)
}

#Preview("Effort Zone Breakdown") {
    EffortZoneBreakdown(zones: [
        EffortZone(zone: 1, label: "Recovery", minutes: 1),
        EffortZone(zone: 2, label: "Easy", minutes: 4),
        EffortZone(zone: 3, label: "Moderate", minutes: 14.5),
        EffortZone(zone: 4, label: "Hard", minutes: 9),
        EffortZone(zone: 5, label: "Max", minutes: 4)
    ])
    .padding(AppSpacing.screenPadding)
    .background(AppColors.background)
}

#Preview("Live Effort") {
    VStack(spacing: 20) {
        LiveEffortIndicator(currentZone: 3, heartRate: 145, effortPercentage: 0.72, currentEP: 125)
        LiveEffortIndicator(currentZone: 5, heartRate: 178, effortPercentage: 0.95, currentEP: 280)
        CompactEffortIndicator(currentZone: 4, effortPercentage: 0.82)
    }
    .padding(AppSpacing.screenPadding)
    .background(AppColors.background)
}

#Preview("Zone Legend") {
    VStack(spacing: AppSpacing.lg) {
        EffortZoneLegend(showEPMultipliers: true)
        EffortZoneLegend(showEPMultipliers: false)
    }
    .padding(AppSpacing.screenPadding)
    .background(AppColors.background)
}

#Preview("Zone Distribution Chart") {
    ZoneDistributionChart(zones: [
        EffortZone(zone: 1, label: "Recovery", minutes: 2),
        EffortZone(zone: 2, label: "Easy", minutes: 8),
        EffortZone(zone: 3, label: "Moderate", minutes: 15),
        EffortZone(zone: 4, label: "Hard", minutes: 10),
        EffortZone(zone: 5, label: "Max", minutes: 3)
    ])
    .padding(AppSpacing.screenPadding)
    .background(AppColors.background)
}
