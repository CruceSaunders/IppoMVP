import SwiftUI

struct RanksView: View {
    @EnvironmentObject var userData: UserData
    
    private var currentRank: GameRank {
        userData.profile.gameRank
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Current Rank Card
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: currentRank.iconName)
                            .font(.system(size: 60))
                            .foregroundStyle(currentRank.color)
                        
                        Text(currentRank.name)
                            .font(AppTypography.largeTitle)
                            .foregroundStyle(currentRank.color)
                        
                        Text("Tier \(currentRank.tier)")
                            .font(AppTypography.headline)
                            .foregroundStyle(AppColors.textSecondary)
                        
                        // RP Progress
                        VStack(spacing: AppSpacing.xs) {
                            Text("\(userData.profile.rp) RP")
                                .font(AppTypography.body)
                                .foregroundStyle(AppColors.textSecondary)
                            
                            if let nextRank = userData.profile.nextGameRank {
                                ProgressView(value: userData.profile.rankProgress)
                                    .tint(currentRank.color)
                                    .frame(maxWidth: 200)
                                
                                Text("\(nextRank.rpRequired - userData.profile.rp) RP to \(nextRank.name)")
                                    .font(AppTypography.caption1)
                                    .foregroundStyle(AppColors.textSecondary)
                            } else {
                                Text("Max Rank Achieved!")
                                    .font(AppTypography.caption1)
                                    .foregroundStyle(AppColors.brandPrimary)
                            }
                        }
                    }
                    .padding(AppSpacing.lg)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                    
                    // Current Perks
                    if !currentRank.perks.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Active Perks")
                                .font(AppTypography.headline)
                            
                            ForEach(currentRank.perks) { perk in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppColors.success)
                                    Text(perk.description)
                                        .font(AppTypography.body)
                                }
                            }
                        }
                        .padding(AppSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                    }
                    
                    // Stats
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Stats")
                            .font(AppTypography.headline)
                        
                        HStack(spacing: AppSpacing.lg) {
                            StatItem(title: "Runs", value: "\(userData.profile.totalRuns)")
                            StatItem(title: "Sprints", value: "\(userData.profile.totalSprintsValid)")
                            StatItem(title: "Streak", value: "\(userData.profile.currentStreak)")
                        }
                    }
                    .padding(AppSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                }
                .padding(AppSpacing.md)
            }
            .background(AppColors.background)
            .navigationTitle("Ranks")
        }
    }
}

private struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(value)
                .font(AppTypography.title2)
                .foregroundStyle(AppColors.textPrimary)
            Text(title)
                .font(AppTypography.caption1)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    RanksView()
        .environmentObject(UserData.shared)
}
