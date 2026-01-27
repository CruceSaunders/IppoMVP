import SwiftUI

struct HomeView: View {
    @EnvironmentObject var userData: UserData
    @State private var showingRunPrompt = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Welcome & Currency
                    welcomeSection
                    
                    // Rank Progress
                    rankSection
                    
                    // Start Run CTA
                    startRunSection
                    
                    // Equipped Pet
                    if let pet = userData.equippedPet {
                        equippedPetSection(pet)
                    }
                    
                    // Pet Collection Preview
                    petCollectionPreview
                    
                    // Recent Runs
                    recentRunsSection
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.bottom, AppSpacing.xxl)
            }
            .background(AppColors.background)
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    currencyDisplay
                }
            }
        }
    }
    
    // MARK: - Welcome Section
    private var welcomeSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("Welcome back,")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                Text(userData.profile.displayName)
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.textPrimary)
            }
            Spacer()
        }
        .padding(.top, AppSpacing.sm)
    }
    
    // MARK: - Currency Display
    private var currencyDisplay: some View {
        HStack(spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.xxs) {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(AppColors.gold)
                Text("\(userData.coins)")
                    .font(AppTypography.currency)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            HStack(spacing: AppSpacing.xxs) {
                Image(systemName: "diamond.fill")
                    .foregroundColor(AppColors.gems)
                Text("\(userData.gems)")
                    .font(AppTypography.currency)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
    }
    
    // MARK: - Rank Section
    private var rankSection: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: userData.profile.rank.iconName)
                    .foregroundColor(AppColors.brandPrimary)
                    .font(.title2)
                Text(userData.profile.rank.displayName)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("\(userData.profile.rp) RP")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            if let nextRank = userData.profile.rank.nextRank {
                let rpNeeded = nextRank.rpRequired - userData.profile.rp
                let progress = Double(userData.profile.rp - userData.profile.rank.rpRequired) /
                              Double(nextRank.rpRequired - userData.profile.rank.rpRequired)
                
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    ProgressView(value: max(0, min(1, progress)))
                        .tint(AppColors.brandPrimary)
                    Text("\(rpNeeded) RP to \(nextRank.displayName)")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            // Streak
            if userData.profile.currentStreak > 0 {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(AppColors.warning)
                    Text("\(userData.profile.currentStreak) day streak")
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textSecondary)
                    Text("(+\(Int(userData.profile.streakBonus * 100))% rewards)")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.success)
                    Spacer()
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Start Run Section
    private var startRunSection: some View {
        Button {
            showingRunPrompt = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Start Run on Watch")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Text(userData.equippedPet != nil ? "1 pet equipped" : "No pet equipped")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                Image(systemName: "applewatch")
                    .font(.largeTitle)
                    .foregroundColor(AppColors.brandPrimary)
            }
            .padding(AppSpacing.lg)
            .background(
                LinearGradient(
                    colors: [AppColors.brandPrimary.opacity(0.2), AppColors.surface],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(AppSpacing.radiusMd)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                    .stroke(AppColors.brandPrimary.opacity(0.3), lineWidth: 1)
            )
        }
        .alert("Start Run", isPresented: $showingRunPrompt) {
            Button("OK") {}
        } message: {
            Text("Open the Ippo app on your Apple Watch to start a run.")
        }
    }
    
    // MARK: - Equipped Pet Section
    private func equippedPetSection(_ pet: OwnedPet) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Equipped Pet")
                .font(AppTypography.footnote)
                .foregroundColor(AppColors.textTertiary)
            
            HStack(spacing: AppSpacing.md) {
                // Pet Image
                Image(pet.currentImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(AppColors.forPet(pet.petDefinitionId), lineWidth: 2)
                    )
                
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(pet.definition?.name ?? "Unknown")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Text("\(pet.stageName) (Stage \(pet.evolutionStage))")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.textSecondary)
                    
                    // XP Progress
                    ProgressView(value: pet.xpProgress)
                        .tint(AppColors.forPet(pet.petDefinitionId))
                }
                
                Spacer()
                
                Text(pet.moodEmoji)
                    .font(.title)
            }
        }
        .cardStyle()
    }
    
    // MARK: - Pet Collection Preview
    private var petCollectionPreview: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Your Pets")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("\(userData.ownedPets.count)/10")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            if userData.ownedPets.isEmpty {
                Text("Complete your first run to catch a pet!")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.lg)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(userData.ownedPets) { pet in
                            VStack(spacing: AppSpacing.xxs) {
                                Image(pet.currentImageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(pet.isEquipped ? AppColors.brandPrimary : AppColors.forPet(pet.petDefinitionId).opacity(0.5), lineWidth: pet.isEquipped ? 2 : 1)
                                    )
                                
                                Text(pet.definition?.name ?? "?")
                                    .font(AppTypography.caption2)
                                    .foregroundColor(AppColors.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        // Undiscovered slots (only show if we have fewer than 10 pets)
                        ForEach(0..<max(0, 10 - userData.ownedPets.count), id: \.self) { _ in
                            VStack(spacing: AppSpacing.xxs) {
                                Circle()
                                    .fill(AppColors.surfaceElevated)
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Text("?")
                                            .font(.title2)
                                            .foregroundColor(AppColors.textTertiary)
                                    )
                                Text("???")
                                    .font(AppTypography.caption2)
                                    .foregroundColor(AppColors.textTertiary)
                            }
                        }
                    }
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Recent Runs
    private var recentRunsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Recent Runs")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            
            if userData.runHistory.isEmpty {
                Text("No runs yet. Start your first run!")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.lg)
            } else {
                ForEach(userData.runHistory.prefix(3)) { run in
                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                            Text(run.date, style: .relative)
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.textPrimary)
                            Text("\(run.formattedDuration) • \(run.sprintsCompleted)/\(run.sprintsTotal) sprints")
                                .font(AppTypography.caption1)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        Spacer()
                        Text("+\(run.rpEarned) RP")
                            .font(AppTypography.callout)
                            .foregroundColor(AppColors.success)
                    }
                    .padding(.vertical, AppSpacing.xs)
                    
                    if run.id != userData.runHistory.prefix(3).last?.id {
                        Divider()
                            .background(AppColors.surfaceElevated)
                    }
                }
            }
        }
        .cardStyle()
    }
}

#Preview {
    HomeView()
        .environmentObject(UserData.shared)
}
