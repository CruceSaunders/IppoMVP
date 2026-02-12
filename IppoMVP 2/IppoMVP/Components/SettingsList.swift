// SettingsList.swift
// Ippo - Settings UI Components
// Adapted from iOS Settings patterns for Ippo design system
//
// Usage:
// - SettingsView: Main app settings
// - ProfileView: Account settings section
// - WatchSettingsView: Apple Watch preferences
// - NotificationSettings: Push notification controls

import SwiftUI

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let header: String?
    let footer: String?
    @ViewBuilder let content: () -> Content
    
    init(
        header: String? = nil,
        footer: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.header = header
        self.footer = footer
        self.content = content
    }
    
    var body: some View {
        Section {
            content()
        } header: {
            if let header = header {
                Text(header)
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textTertiary)
            }
        } footer: {
            if let footer = footer {
                Text(footer)
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
    }
}

// MARK: - Settings Row Types

/// Standard navigation row with chevron
struct SettingsNavigationRow<Destination: View>: View {
    let icon: String?
    let iconColor: Color
    let title: String
    let subtitle: String?
    let value: String?
    let destination: () -> Destination
    
    init(
        icon: String? = nil,
        iconColor: Color = AppColors.brandPrimary,
        title: String,
        subtitle: String? = nil,
        value: String? = nil,
        @ViewBuilder destination: @escaping () -> Destination
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.destination = destination
    }
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: AppSpacing.md) {
                if let icon = icon {
                    SettingsIcon(systemName: icon, color: iconColor)
                }
                
                VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                    Text(title)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                
                Spacer()
                
                if let value = value {
                    Text(value)
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .contentShape(Rectangle())
        }
        .frame(minHeight: 44)
    }
}

/// Toggle row with switch
struct SettingsToggleRow: View {
    let icon: String?
    let iconColor: Color
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool
    
    init(
        icon: String? = nil,
        iconColor: Color = AppColors.brandPrimary,
        title: String,
        subtitle: String? = nil,
        isOn: Binding<Bool>
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
    }
    
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: AppSpacing.md) {
                if let icon = icon {
                    SettingsIcon(systemName: icon, color: iconColor)
                }
                
                VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                    Text(title)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }
        }
        .tint(AppColors.brandPrimary)
        .frame(minHeight: 44)
    }
}

/// Button row (destructive or standard action)
struct SettingsButtonRow: View {
    let icon: String?
    let iconColor: Color
    let title: String
    let role: ButtonRole?
    let action: () -> Void
    
    init(
        icon: String? = nil,
        iconColor: Color = AppColors.brandPrimary,
        title: String,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.role = role
        self.action = action
    }
    
    var body: some View {
        Button(role: role, action: action) {
            HStack(spacing: AppSpacing.md) {
                if let icon = icon {
                    SettingsIcon(
                        systemName: icon,
                        color: role == .destructive ? AppColors.danger : iconColor
                    )
                }
                
                Text(title)
                    .font(AppTypography.body)
                    .foregroundColor(role == .destructive ? AppColors.danger : AppColors.textPrimary)
                
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
    }
}

/// Value display row (non-interactive)
struct SettingsValueRow: View {
    let icon: String?
    let iconColor: Color
    let title: String
    let value: String
    var valueColor: Color = AppColors.textSecondary
    
    init(
        icon: String? = nil,
        iconColor: Color = AppColors.brandPrimary,
        title: String,
        value: String,
        valueColor: Color = AppColors.textSecondary
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.value = value
        self.valueColor = valueColor
    }
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        "\(title), \(value)"
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            if let icon = icon {
                SettingsIcon(systemName: icon, color: iconColor)
            }
            
            Text(title)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(AppTypography.subheadline)
                .foregroundColor(valueColor)
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }
}

/// Picker row (inline selection)
struct SettingsPickerRow<T: Hashable & CustomStringConvertible>: View {
    let icon: String?
    let iconColor: Color
    let title: String
    let options: [T]
    @Binding var selection: T
    
    init(
        icon: String? = nil,
        iconColor: Color = AppColors.brandPrimary,
        title: String,
        options: [T],
        selection: Binding<T>
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.options = options
        self._selection = selection
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            if let icon = icon {
                SettingsIcon(systemName: icon, color: iconColor)
            }
            
            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option.description).tag(option)
                }
            }
            .tint(AppColors.brandPrimary)
        }
        .frame(minHeight: 44)
    }
}

/// Slider row
struct SettingsSliderRow: View {
    let icon: String?
    let iconColor: Color
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double?
    let valueFormatter: ((Double) -> String)?
    
    init(
        icon: String? = nil,
        iconColor: Color = AppColors.brandPrimary,
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double? = nil,
        valueFormatter: ((Double) -> String)? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        self.valueFormatter = valueFormatter
    }
    
    // MARK: - Accessibility
    private var accessibilityValueText: String {
        if let formatter = valueFormatter {
            return formatter(value)
        }
        let percent = Int(((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * 100)
        return "\(percent) percent"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.md) {
                if let icon = icon {
                    SettingsIcon(systemName: icon, color: iconColor)
                }
                
                Text(title)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                if let formatter = valueFormatter {
                    Text(formatter(value))
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            if let step = step {
                Slider(value: $value, in: range, step: step)
                    .tint(AppColors.brandPrimary)
                    .accessibilityLabel(title)
                    .accessibilityValue(accessibilityValueText)
            } else {
                Slider(value: $value, in: range)
                    .tint(AppColors.brandPrimary)
                    .accessibilityLabel(title)
                    .accessibilityValue(accessibilityValueText)
            }
        }
        .padding(.vertical, AppSpacing.xxs)
    }
}

/// Stepper row
struct SettingsStepperRow: View {
    let icon: String?
    let iconColor: Color
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let valueFormatter: ((Int) -> String)?
    
    init(
        icon: String? = nil,
        iconColor: Color = AppColors.brandPrimary,
        title: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        valueFormatter: ((Int) -> String)? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self._value = value
        self.range = range
        self.valueFormatter = valueFormatter
    }
    
    var body: some View {
        Stepper(value: $value, in: range) {
            HStack(spacing: AppSpacing.md) {
                if let icon = icon {
                    SettingsIcon(systemName: icon, color: iconColor)
                }
                
                Text(title)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                if let formatter = valueFormatter {
                    Text(formatter(value))
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .tint(AppColors.brandPrimary)
        .frame(minHeight: 44)
    }
}

// MARK: - Settings Icon

struct SettingsIcon: View {
    let systemName: String
    let color: Color
    var size: CGFloat = 28
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppSpacing.xs)
                .fill(color)
                .frame(width: size, height: size)
            
            Image(systemName: systemName)
                .font(.system(size: size * 0.55, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
        }
        .accessibilityHidden(true) // Decorative - text labels provide context
    }
}

// MARK: - Account Header Row

struct SettingsAccountRow<Destination: View>: View {
    let name: String
    let email: String?
    let avatarURL: URL?
    let avatarInitials: String?
    let totalEP: Int?
    let destination: () -> Destination
    
    init(
        name: String,
        email: String? = nil,
        avatarURL: URL? = nil,
        avatarInitials: String? = nil,
        totalEP: Int? = nil,
        @ViewBuilder destination: @escaping () -> Destination
    ) {
        self.name = name
        self.email = email
        self.avatarURL = avatarURL
        self.avatarInitials = avatarInitials
        self.totalEP = totalEP
        self.destination = destination
    }
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        var description = name
        if let email = email {
            description += ", \(email)"
        }
        if let ep = totalEP {
            description += ", \(ep.formatted()) Effort Points total"
        }
        return description
    }
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: AppSpacing.lg) {
                // Avatar
                if let url = avatarURL {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        initialsView
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .accessibilityHidden(true) // Decorative - name is announced
                } else {
                    initialsView
                        .frame(width: 60, height: 60)
                        .accessibilityHidden(true) // Decorative - name is announced
                }
                
                // Name, email, and EP
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(name)
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.textPrimary)
                    
                    if let email = email {
                        Text(email)
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    if let ep = totalEP {
                        HStack(spacing: AppSpacing.xxs) {
                            Image(systemName: "bolt.fill")
                                .font(AppTypography.caption1)
                                .foregroundColor(AppColors.brandPrimary)
                                .accessibilityHidden(true) // Decorative
                            Text("\(ep.formatted()) EP")
                                .font(AppTypography.caption1)
                                .foregroundColor(AppColors.brandPrimary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, AppSpacing.sm)
            .contentShape(Rectangle())
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Account")
        .accessibilityValue(accessibilityDescription)
        .accessibilityHint("Double tap to view account details")
    }
    
    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(AppColors.surfaceElevated)
            
            Text(avatarInitials ?? String(name.prefix(2)).uppercased())
                .font(AppTypography.title2)
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

// MARK: - Connected Device Row (Watch Connection)

struct SettingsDeviceRow: View {
    let icon: String
    let iconColor: Color
    let deviceName: String
    let connectionStatus: ConnectionStatus
    let lastSynced: Date?
    var onTap: (() -> Void)? = nil
    
    enum ConnectionStatus {
        case connected
        case disconnected
        case syncing
        
        var color: Color {
            switch self {
            case .connected: return AppColors.success
            case .disconnected: return AppColors.textTertiary
            case .syncing: return AppColors.brandPrimary
            }
        }
        
        var text: String {
            switch self {
            case .connected: return "Connected"
            case .disconnected: return "Not Connected"
            case .syncing: return "Syncing..."
            }
        }
    }
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        var description = "\(deviceName), \(connectionStatus.text)"
        if let lastSynced = lastSynced {
            description += ", last synced at \(lastSynced.formatted(date: .omitted, time: .shortened))"
        }
        return description
    }
    
    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: AppSpacing.md) {
                SettingsIcon(systemName: icon, color: iconColor, size: 44)
                
                VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                    Text(deviceName)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack(spacing: AppSpacing.xxs) {
                        Circle()
                            .fill(connectionStatus.color)
                            .frame(width: 8, height: 8)
                            .accessibilityHidden(true) // Status color is decorative
                        
                        Text(connectionStatus.text)
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textSecondary)
                        
                        if connectionStatus == .syncing {
                            ProgressView()
                                .scaleEffect(0.6)
                                .tint(AppColors.brandPrimary)
                                .accessibilityHidden(true) // Status already announced
                        }
                    }
                    
                    if let lastSynced = lastSynced {
                        Text("Last synced: \(lastSynced.formatted(date: .omitted, time: .shortened))")
                            .font(AppTypography.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textTertiary)
                    .accessibilityHidden(true) // Decorative
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(minHeight: 60)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(deviceName)
        .accessibilityValue(connectionStatus.text + (lastSynced != nil ? ", last synced at \(lastSynced!.formatted(date: .omitted, time: .shortened))" : ""))
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to view device settings")
    }
}

// MARK: - Danger Zone Section

struct SettingsDangerZone: View {
    let items: [DangerItem]
    
    struct DangerItem: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let description: String
        let action: () -> Void
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            ForEach(items) { item in
                Button(action: {
                    // Haptic feedback for destructive actions
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    item.action()
                }) {
                    HStack(spacing: AppSpacing.md) {
                        Image(systemName: item.icon)
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.danger)
                            .frame(width: 28)
                            .accessibilityHidden(true) // Decorative
                        
                        VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                            Text(item.title)
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.danger)
                            
                            Text(item.description)
                                .font(AppTypography.caption1)
                                .foregroundColor(AppColors.textTertiary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, AppSpacing.sm)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(item.title)
                .accessibilityValue(item.description)
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Warning: This is a destructive action. Double tap to proceed.")
                
                if item.id != items.last?.id {
                    Divider()
                        .background(AppColors.danger.opacity(0.3))
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.danger.opacity(0.05))
        .cornerRadius(AppSpacing.radiusMd)
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                .stroke(AppColors.danger.opacity(0.2), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Danger zone, \(items.count) destructive actions")
    }
}

// MARK: - Storage Usage Row

struct SettingsStorageRow: View {
    let usedBytes: Int64
    let totalBytes: Int64
    let categories: [StorageCategory]
    
    struct StorageCategory: Identifiable {
        let id = UUID()
        let name: String
        let bytes: Int64
        let color: Color
    }
    
    private var formatter: ByteCountFormatter {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter
    }
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        let usedFormatted = formatter.string(fromByteCount: usedBytes)
        let totalFormatted = formatter.string(fromByteCount: totalBytes)
        let percentUsed = Int((Double(usedBytes) / Double(totalBytes)) * 100)
        
        var description = "\(usedFormatted) of \(totalFormatted) used, \(percentUsed) percent. "
        description += "Breakdown: "
        description += categories.map { "\($0.name) \(formatter.string(fromByteCount: $0.bytes))" }.joined(separator: ", ")
        
        return description
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Storage")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Text("\(formatter.string(fromByteCount: usedBytes)) of \(formatter.string(fromByteCount: totalBytes))")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // Progress bar with categories
            GeometryReader { geo in
                HStack(spacing: 1) {
                    ForEach(categories) { category in
                        let width = (Double(category.bytes) / Double(totalBytes)) * geo.size.width
                        Rectangle()
                            .fill(category.color)
                            .frame(width: max(width, 2))
                    }
                    
                    Spacer()
                }
                .frame(height: 8)
                .background(AppColors.surfaceElevated)
                .cornerRadius(AppSpacing.xxs)
            }
            .frame(height: 8)
            .accessibilityHidden(true) // Visual progress bar - described in main label
            
            // Legend
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                ForEach(categories) { category in
                    HStack(spacing: AppSpacing.xs) {
                        Circle()
                            .fill(category.color)
                            .frame(width: 10, height: 10)
                            .accessibilityHidden(true) // Color is decorative
                        
                        Text(category.name)
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Spacer()
                        
                        Text(formatter.string(fromByteCount: category.bytes))
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(category.name), \(formatter.string(fromByteCount: category.bytes))")
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.radiusMd)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Storage usage")
        .accessibilityValue(accessibilityDescription)
    }
}

// MARK: - Ippo-Specific Settings Components

/// Effort Point Settings Card
struct EPSettingsCard: View {
    @Binding var effortSensitivity: Double
    @Binding var showZoneDuringRun: Bool
    @Binding var hapticOnZoneChange: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Header
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "bolt.fill")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.brandPrimary)
                    .accessibilityHidden(true) // Decorative
                
                Text("Effort Points")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Effort Points settings")
            .accessibilityAddTraits(.isHeader)
            
            Divider()
                .background(AppColors.surfaceElevated)
            
            // Sensitivity slider
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text("Effort Sensitivity")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Text(sensitivityLabel)
                        .font(AppTypography.subheadline)
                        .foregroundColor(sensitivityColor)
                }
                .accessibilityHidden(true) // Slider announces this
                
                Slider(value: $effortSensitivity, in: 0...1, step: 0.1)
                    .tint(AppColors.brandPrimary)
                    .accessibilityLabel("Effort Sensitivity")
                    .accessibilityValue(sensitivityLabel)
                    .accessibilityHint("Higher sensitivity means earning Effort Points faster but requires more effort")
                
                Text("Higher sensitivity = earn EP faster but requires more effort")
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textTertiary)
                    .accessibilityHidden(true) // Already in hint
            }
            
            Divider()
                .background(AppColors.surfaceElevated)
            
            // Zone toggles
            VStack(spacing: AppSpacing.md) {
                Toggle(isOn: $showZoneDuringRun) {
                    VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                        Text("Show Zone During Run")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                        Text("Display current effort zone on Watch")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                .tint(AppColors.brandPrimary)
                
                Toggle(isOn: $hapticOnZoneChange) {
                    VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                        Text("Haptic on Zone Change")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                        Text("Feel a tap when entering a new zone")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                .tint(AppColors.brandPrimary)
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.radiusMd)
    }
    
    private var sensitivityLabel: String {
        switch effortSensitivity {
        case 0..<0.3: return "Low"
        case 0.3..<0.7: return "Normal"
        default: return "High"
        }
    }
    
    private var sensitivityColor: Color {
        switch effortSensitivity {
        case 0..<0.3: return AppColors.success
        case 0.3..<0.7: return AppColors.brandPrimary
        default: return AppColors.warning
        }
    }
}

/// Pet Preferences Card
struct PetSettingsCard: View {
    @Binding var showPetDuringRun: Bool
    @Binding var petAnimationsEnabled: Bool
    @Binding var petNotificationsEnabled: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Header
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "pawprint.fill")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.brandSecondary)
                    .accessibilityHidden(true) // Decorative
                
                Text("Pets")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Pets settings")
            .accessibilityAddTraits(.isHeader)
            
            Divider()
                .background(AppColors.surfaceElevated)
            
            // Pet toggles
            VStack(spacing: AppSpacing.md) {
                Toggle(isOn: $showPetDuringRun) {
                    VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                        Text("Pet Companion During Run")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                        Text("Show your active pet on the Watch screen")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                .tint(AppColors.brandPrimary)
                
                Toggle(isOn: $petAnimationsEnabled) {
                    VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                        Text("Pet Animations")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                        Text("Enable bouncing and celebration animations")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                .tint(AppColors.brandPrimary)
                
                Toggle(isOn: $petNotificationsEnabled) {
                    VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                        Text("Pet Reminders")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                        Text("Get notified when your pet needs attention")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                .tint(AppColors.brandPrimary)
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.radiusMd)
    }
}

/// Running Preferences Card
struct RunningSettingsCard: View {
    @Binding var distanceUnit: String
    @Binding var autoPauseEnabled: Bool
    @Binding var countdownEnabled: Bool
    @Binding var weeklyGoal: Int
    
    let distanceUnits = ["Miles", "Kilometers"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Header
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "figure.run")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.success)
                    .accessibilityHidden(true) // Decorative
                
                Text("Running")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Running settings")
            .accessibilityAddTraits(.isHeader)
            
            Divider()
                .background(AppColors.surfaceElevated)
            
            // Distance unit picker
            HStack {
                Text("Distance Unit")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Picker("Distance Unit", selection: $distanceUnit) {
                    ForEach(distanceUnits, id: \.self) { unit in
                        Text(unit).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }
            
            Divider()
                .background(AppColors.surfaceElevated)
            
            // Weekly goal stepper
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                    Text("Weekly Goal")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                    Text("How many runs per week")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Spacer()
                
                Stepper(value: $weeklyGoal, in: 1...7) {
                    Text("\(weeklyGoal) runs")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.brandPrimary)
                }
                .labelsHidden()
                .accessibilityLabel("Weekly goal")
                .accessibilityValue("\(weeklyGoal) runs per week")
            }
            
            Divider()
                .background(AppColors.surfaceElevated)
            
            // Running toggles
            VStack(spacing: AppSpacing.md) {
                Toggle(isOn: $autoPauseEnabled) {
                    VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                        Text("Auto-Pause")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                        Text("Automatically pause when you stop moving")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                .tint(AppColors.brandPrimary)
                
                Toggle(isOn: $countdownEnabled) {
                    VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                        Text("Start Countdown")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                        Text("3-second countdown before run starts")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                .tint(AppColors.brandPrimary)
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.radiusMd)
    }
}

// MARK: - Complete Settings View Example

struct IppoSettingsView: View {
    // Account
    @State private var userName = "Cruce"
    @State private var userEmail = "cruce@example.com"
    @State private var totalEP = 12450
    
    // Notifications
    @State private var notificationsEnabled = true
    @State private var soundEnabled = true
    @State private var hapticEnabled = true
    
    // Effort Points
    @State private var effortSensitivity: Double = 0.5
    @State private var showZoneDuringRun = true
    @State private var hapticOnZoneChange = true
    
    // Pets
    @State private var showPetDuringRun = true
    @State private var petAnimationsEnabled = true
    @State private var petNotificationsEnabled = true
    
    // Running
    @State private var distanceUnit = "Miles"
    @State private var autoPauseEnabled = true
    @State private var countdownEnabled = true
    @State private var weeklyGoal = 3
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Account section
                    SettingsAccountRow(
                        name: userName,
                        email: userEmail,
                        avatarInitials: "CR",
                        totalEP: totalEP
                    ) {
                        Text("Account Details")
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .padding(.top, AppSpacing.lg)
                    
                    // Connected devices
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("CONNECTED DEVICES")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textTertiary)
                            .padding(.horizontal, AppSpacing.screenPadding)
                        
                        SettingsDeviceRow(
                            icon: "applewatch",
                            iconColor: AppColors.textTertiary,
                            deviceName: "Cruce's Apple Watch",
                            connectionStatus: .connected,
                            lastSynced: Date()
                        )
                        .padding(.horizontal, AppSpacing.screenPadding)
                        .padding(AppSpacing.md)
                        .background(AppColors.surface)
                        .cornerRadius(AppSpacing.radiusMd)
                        .padding(.horizontal, AppSpacing.screenPadding)
                    }
                    
                    // Effort Points settings
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        EPSettingsCard(
                            effortSensitivity: $effortSensitivity,
                            showZoneDuringRun: $showZoneDuringRun,
                            hapticOnZoneChange: $hapticOnZoneChange
                        )
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    
                    // Pet settings
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        PetSettingsCard(
                            showPetDuringRun: $showPetDuringRun,
                            petAnimationsEnabled: $petAnimationsEnabled,
                            petNotificationsEnabled: $petNotificationsEnabled
                        )
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    
                    // Running settings
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        RunningSettingsCard(
                            distanceUnit: $distanceUnit,
                            autoPauseEnabled: $autoPauseEnabled,
                            countdownEnabled: $countdownEnabled,
                            weeklyGoal: $weeklyGoal
                        )
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    
                    // Notifications section
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("NOTIFICATIONS")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textTertiary)
                            .padding(.horizontal, AppSpacing.screenPadding)
                        
                        VStack(spacing: 0) {
                            SettingsToggleRow(
                                icon: "bell.fill",
                                iconColor: AppColors.danger,
                                title: "Push Notifications",
                                isOn: $notificationsEnabled
                            )
                            .padding(.horizontal, AppSpacing.md)
                            
                            Divider()
                                .background(AppColors.surfaceElevated)
                                .padding(.leading, 52)
                            
                            SettingsToggleRow(
                                icon: "speaker.wave.2.fill",
                                iconColor: AppColors.gems,
                                title: "Sounds",
                                isOn: $soundEnabled
                            )
                            .padding(.horizontal, AppSpacing.md)
                            
                            Divider()
                                .background(AppColors.surfaceElevated)
                                .padding(.leading, 52)
                            
                            SettingsToggleRow(
                                icon: "iphone.radiowaves.left.and.right",
                                iconColor: AppColors.brandSecondary,
                                title: "Haptics",
                                isOn: $hapticEnabled
                            )
                            .padding(.horizontal, AppSpacing.md)
                        }
                        .padding(.vertical, AppSpacing.sm)
                        .background(AppColors.surface)
                        .cornerRadius(AppSpacing.radiusMd)
                        .padding(.horizontal, AppSpacing.screenPadding)
                    }
                    
                    // App info
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("ABOUT")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textTertiary)
                            .padding(.horizontal, AppSpacing.screenPadding)
                        
                        VStack(spacing: 0) {
                            SettingsValueRow(
                                icon: "info.circle.fill",
                                iconColor: AppColors.brandPrimary,
                                title: "Version",
                                value: "1.0.0 (42)"
                            )
                            .padding(.horizontal, AppSpacing.md)
                            
                            Divider()
                                .background(AppColors.surfaceElevated)
                                .padding(.leading, 52)
                            
                            SettingsNavigationRow(
                                icon: "doc.text.fill",
                                iconColor: AppColors.textTertiary,
                                title: "Privacy Policy"
                            ) {
                                Text("Privacy Policy Content")
                            }
                            .padding(.horizontal, AppSpacing.md)
                            
                            Divider()
                                .background(AppColors.surfaceElevated)
                                .padding(.leading, 52)
                            
                            SettingsNavigationRow(
                                icon: "doc.text.fill",
                                iconColor: AppColors.textTertiary,
                                title: "Terms of Service"
                            ) {
                                Text("Terms of Service Content")
                            }
                            .padding(.horizontal, AppSpacing.md)
                        }
                        .padding(.vertical, AppSpacing.sm)
                        .background(AppColors.surface)
                        .cornerRadius(AppSpacing.radiusMd)
                        .padding(.horizontal, AppSpacing.screenPadding)
                    }
                    
                    // Storage usage
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        SettingsStorageRow(
                            usedBytes: 2_500_000_000,
                            totalBytes: 5_000_000_000,
                            categories: [
                                .init(name: "Runs", bytes: 1_200_000_000, color: AppColors.brandPrimary),
                                .init(name: "Pets", bytes: 800_000_000, color: AppColors.brandSecondary),
                                .init(name: "Cache", bytes: 500_000_000, color: AppColors.warning)
                            ]
                        )
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    
                    // Danger zone
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("DANGER ZONE")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textTertiary)
                            .padding(.horizontal, AppSpacing.screenPadding)
                        
                        SettingsDangerZone(items: [
                            .init(
                                icon: "arrow.counterclockwise",
                                title: "Reset All Progress",
                                description: "This will reset all your runs, achievements, and pets.",
                                action: { print("Reset tapped") }
                            ),
                            .init(
                                icon: "trash.fill",
                                title: "Delete Account",
                                description: "Permanently delete your account and all data.",
                                action: { print("Delete tapped") }
                            )
                        ])
                        .padding(.horizontal, AppSpacing.screenPadding)
                    }
                    
                    Spacer()
                        .frame(height: AppSpacing.xxxl)
                }
            }
            .background(AppColors.background)
            .navigationTitle("Settings")
            .toolbarBackground(AppColors.background, for: .navigationBar)
        }
    }
}

// MARK: - Previews

#Preview("Settings View") {
    IppoSettingsView()
        .preferredColorScheme(.dark)
}

#Preview("Icon Styles") {
    VStack(spacing: AppSpacing.lg) {
        HStack(spacing: AppSpacing.md) {
            SettingsIcon(systemName: "gear", color: AppColors.textTertiary)
            SettingsIcon(systemName: "bell.fill", color: AppColors.danger)
            SettingsIcon(systemName: "heart.fill", color: AppColors.gems)
            SettingsIcon(systemName: "figure.run", color: AppColors.success)
            SettingsIcon(systemName: "flame.fill", color: AppColors.warning)
        }
        
        HStack(spacing: AppSpacing.md) {
            SettingsIcon(systemName: "bolt.fill", color: AppColors.brandPrimary)
            SettingsIcon(systemName: "pawprint.fill", color: AppColors.brandSecondary)
        }
        
        HStack(spacing: AppSpacing.md) {
            SettingsIcon(systemName: "applewatch", color: AppColors.textTertiary, size: 44)
            SettingsIcon(systemName: "iphone", color: AppColors.brandPrimary, size: 44)
        }
    }
    .padding(AppSpacing.lg)
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}

#Preview("Device Row States") {
    VStack(spacing: AppSpacing.lg) {
        SettingsDeviceRow(
            icon: "applewatch",
            iconColor: AppColors.textTertiary,
            deviceName: "Cruce's Apple Watch",
            connectionStatus: .connected,
            lastSynced: Date()
        )
        
        SettingsDeviceRow(
            icon: "applewatch",
            iconColor: AppColors.textTertiary,
            deviceName: "Cruce's Apple Watch",
            connectionStatus: .syncing,
            lastSynced: nil
        )
        
        SettingsDeviceRow(
            icon: "applewatch",
            iconColor: AppColors.textTertiary,
            deviceName: "Cruce's Apple Watch",
            connectionStatus: .disconnected,
            lastSynced: Date().addingTimeInterval(-3600)
        )
    }
    .padding(AppSpacing.lg)
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}

#Preview("EP Settings Card") {
    EPSettingsCard(
        effortSensitivity: .constant(0.5),
        showZoneDuringRun: .constant(true),
        hapticOnZoneChange: .constant(true)
    )
    .padding(AppSpacing.screenPadding)
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}

#Preview("Pet Settings Card") {
    PetSettingsCard(
        showPetDuringRun: .constant(true),
        petAnimationsEnabled: .constant(true),
        petNotificationsEnabled: .constant(true)
    )
    .padding(AppSpacing.screenPadding)
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}

#Preview("Running Settings Card") {
    RunningSettingsCard(
        distanceUnit: .constant("Miles"),
        autoPauseEnabled: .constant(true),
        countdownEnabled: .constant(true),
        weeklyGoal: .constant(3)
    )
    .padding(AppSpacing.screenPadding)
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}

#Preview("Danger Zone") {
    SettingsDangerZone(items: [
        .init(
            icon: "arrow.counterclockwise",
            title: "Reset All Progress",
            description: "This will reset all your runs, achievements, and pets.",
            action: {}
        ),
        .init(
            icon: "trash.fill",
            title: "Delete Account",
            description: "Permanently delete your account and all data.",
            action: {}
        )
    ])
    .padding(AppSpacing.screenPadding)
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}

#Preview("Storage Row") {
    SettingsStorageRow(
        usedBytes: 2_500_000_000,
        totalBytes: 5_000_000_000,
        categories: [
            .init(name: "Runs", bytes: 1_200_000_000, color: AppColors.brandPrimary),
            .init(name: "Pets", bytes: 800_000_000, color: AppColors.brandSecondary),
            .init(name: "Cache", bytes: 500_000_000, color: AppColors.warning)
        ]
    )
    .padding(AppSpacing.screenPadding)
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}

#Preview("Account Row") {
    SettingsAccountRow(
        name: "Cruce",
        email: "cruce@example.com",
        avatarInitials: "CR",
        totalEP: 12450
    ) {
        Text("Account Details")
    }
    .padding(AppSpacing.screenPadding)
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}
