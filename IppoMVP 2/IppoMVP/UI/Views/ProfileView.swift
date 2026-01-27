import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userData: UserData
    @State private var showingSettings = false
    @State private var showingRunHistory = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Profile Header
                    profileHeader
                    
                    // Stats Grid
                    statsGrid
                    
                    // Points
                    pointsSection
                    
                    // Recent Runs
                    recentRunsSection
                    
                    // Quick Settings
                    quickSettings
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.bottom, AppSpacing.xxl)
            }
            .background(AppColors.background)
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsSheet()
            }
            .sheet(isPresented: $showingRunHistory) {
                RunHistorySheet()
            }
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: AppSpacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(AppColors.brandPrimary.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Text(String(userData.profile.displayName.prefix(2)).uppercased())
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.brandPrimary)
            }
            
            // Name & Level
            VStack(spacing: AppSpacing.xxs) {
                Text(userData.profile.displayName)
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: AppSpacing.sm) {
                    Text("Level \(userData.profile.level)")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("•")
                        .foregroundColor(AppColors.textTertiary)
                    
                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: userData.profile.rank.iconName)
                            .foregroundColor(AppColors.brandPrimary)
                        Text(userData.profile.rank.displayName)
                            .foregroundColor(AppColors.brandPrimary)
                    }
                    .font(AppTypography.subheadline)
                }
                
                // Streak
                if userData.profile.currentStreak > 0 {
                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(AppColors.warning)
                        Text("\(userData.profile.currentStreak) day streak")
                            .foregroundColor(AppColors.warning)
                    }
                    .font(AppTypography.caption1)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.radiusMd)
    }
    
    // MARK: - Stats Grid
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
            statCard("Runs", value: "\(userData.profile.totalRuns)", icon: "figure.run")
            statCard("Sprints", value: "\(userData.profile.totalSprintsValid)/\(userData.profile.totalSprints)", icon: "bolt.fill")
            statCard("Pets", value: "\(userData.ownedPets.count)/10", icon: "pawprint.fill")
            statCard("RP", value: "\(userData.profile.rp)", icon: "star.fill")
        }
    }
    
    private func statCard(_ title: String, value: String, icon: String) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AppColors.brandPrimary)
            
            Text(value)
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            Text(title)
                .font(AppTypography.caption1)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.radiusMd)
    }
    
    // MARK: - Points Section
    private var pointsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Points")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: AppSpacing.lg) {
                pointRow("Ability Points", value: userData.abilities.abilityPoints, icon: "star.circle.fill", color: AppColors.brandPrimary)
                pointRow("Pet Points", value: userData.abilities.petPoints, icon: "pawprint.circle.fill", color: AppColors.gems)
            }
            
            // XP Progress
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack {
                    Text("Level \(userData.profile.level)")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text("\(userData.profile.xp) / \(userData.profile.xpForNextLevel) XP")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                ProgressView(value: userData.profile.xpProgress)
                    .tint(AppColors.brandPrimary)
            }
        }
        .cardStyle()
    }
    
    private func pointRow(_ title: String, value: Int, icon: String, color: Color) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 0) {
                Text("\(value)")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                Text(title)
                    .font(AppTypography.caption2)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Recent Runs Section
    private var recentRunsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Run History")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Button("See All") {
                    showingRunHistory = true
                }
                .font(AppTypography.caption1)
                .foregroundColor(AppColors.brandPrimary)
            }
            
            if userData.runHistory.isEmpty {
                Text("No runs yet")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.lg)
            } else {
                ForEach(userData.runHistory.prefix(3)) { run in
                    runRow(run)
                    
                    if run.id != userData.runHistory.prefix(3).last?.id {
                        Divider()
                            .background(AppColors.surfaceElevated)
                    }
                }
            }
        }
        .cardStyle()
    }
    
    private func runRow(_ run: CompletedRun) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(run.date.formatted(date: .abbreviated, time: .shortened))
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textPrimary)
                Text("\(run.formattedDuration) • \(run.sprintsCompleted) sprints")
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                Text("+\(run.rpEarned) RP")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.success)
                
                if run.petCaught != nil {
                    HStack(spacing: AppSpacing.xxxs) {
                        Image(systemName: "sparkles")
                        Text("Pet!")
                    }
                    .font(AppTypography.caption2)
                    .foregroundColor(AppColors.brandPrimary)
                }
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
    
    // MARK: - Quick Settings
    private var quickSettings: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Settings")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)
            
            settingsRow("Notifications", icon: "bell.fill")
            settingsRow("Health Permissions", icon: "heart.fill")
            settingsRow("Privacy", icon: "lock.fill")
            settingsRow("Help & Support", icon: "questionmark.circle.fill")
        }
        .cardStyle()
    }
    
    private func settingsRow(_ title: String, icon: String) -> some View {
        Button {
            // Navigate to settings
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 24)
                
                Text(title)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(.vertical, AppSpacing.sm)
        }
    }
}

// MARK: - Settings Sheet
struct SettingsSheet: View {
    @EnvironmentObject var userData: UserData
    @Environment(\.dismiss) var dismiss
    @State private var displayName: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Display Name", text: $displayName)
                        .onAppear {
                            displayName = userData.profile.displayName
                        }
                }
                
                Section("App") {
                    Button("Request Health Permissions") {
                        // Would request HealthKit permissions
                    }
                }
                
                Section("Debug") {
                    #if DEBUG
                    Button("Load Test Data") {
                        userData.loadTestData()
                    }
                    
                    Button("Reset All Data") {
                        userData.logout()
                    }
                    .foregroundColor(AppColors.danger)
                    #endif
                }
                
                Section("Account") {
                    Button("Sign Out") {
                        userData.logout()
                        dismiss()
                    }
                    .foregroundColor(AppColors.danger)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        userData.profile.displayName = displayName
                        userData.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Run History Sheet
struct RunHistorySheet: View {
    @EnvironmentObject var userData: UserData
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                if userData.runHistory.isEmpty {
                    Text("No runs yet")
                        .foregroundColor(AppColors.textSecondary)
                } else {
                    ForEach(userData.runHistory) { run in
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            HStack {
                                Text(run.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(AppTypography.headline)
                                Spacer()
                                Text("+\(run.rpEarned) RP")
                                    .foregroundColor(AppColors.success)
                            }
                            
                            HStack(spacing: AppSpacing.md) {
                                Label(run.formattedDuration, systemImage: "clock")
                                Label("\(run.sprintsCompleted)/\(run.sprintsTotal)", systemImage: "bolt.fill")
                                Label("+\(run.coinsEarned)", systemImage: "dollarsign.circle.fill")
                            }
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textSecondary)
                            
                            if let pet = run.petCaught,
                               let def = GameData.shared.pet(byId: pet) {
                                HStack {
                                    Image(systemName: "sparkles")
                                    Text("Caught \(def.name)!")
                                }
                                .font(AppTypography.caption1)
                                .foregroundColor(AppColors.brandPrimary)
                            }
                        }
                        .padding(.vertical, AppSpacing.xs)
                    }
                }
            }
            .navigationTitle("Run History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(UserData.shared)
}
