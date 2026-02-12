import SwiftUI

struct AbilitiesView: View {
    @EnvironmentObject var userData: UserData
    @State private var selectedTab = 0
    @State private var selectedNode: AbilityNode?
    
    // Zoom state
    @State private var currentScale: CGFloat = 1.0
    @GestureState private var gestureScale: CGFloat = 1.0
    
    // Pan state
    @State private var currentOffset: CGSize = .zero
    @GestureState private var gestureOffset: CGSize = .zero
    
    // Zoom limits
    private let minScale: CGFloat = 0.6
    private let maxScale: CGFloat = 2.0
    
    // Computed combined values
    private var scale: CGFloat {
        let combined = currentScale * gestureScale
        return min(max(combined, minScale), maxScale)
    }
    
    private var offset: CGSize {
        CGSize(
            width: currentOffset.width + gestureOffset.width,
            height: currentOffset.height + gestureOffset.height
        )
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Points Display
                pointsDisplay
                
                // Tab Selector
                Picker("", selection: $selectedTab) {
                    Text("Player").tag(0)
                    Text("Pets").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.vertical, AppSpacing.sm)
                
                // Content
                if selectedTab == 0 {
                    playerAbilityTree
                } else {
                    petAbilitiesView
                }
            }
            .background(AppColors.background)
            .navigationTitle("Abilities")
            .sheet(item: $selectedNode) { node in
                AbilityNodeSheet(node: node)
            }
        }
    }
    
    // MARK: - Points Display
    private var pointsDisplay: some View {
        HStack(spacing: AppSpacing.xl) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "star.circle.fill")
                    .foregroundColor(AppColors.brandPrimary)
                Text("AP: \(userData.abilities.abilityPoints)")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "pawprint.circle.fill")
                    .foregroundColor(AppColors.gems)
                Text("PP: \(userData.abilities.petPoints)")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
    }
    
    // MARK: - Player Ability Tree
    private var playerAbilityTree: some View {
        GeometryReader { geo in
            let treeSize = CGSize(
                width: geo.size.width * 1.8,
                height: geo.size.height * 1.5
            )
            
            ZStack {
                // Draw edges (using unique edge IDs to ensure all edges render)
                ForEach(AbilityTreeData.edges) { edge in
                    if let fromNode = AbilityTreeData.node(byId: edge.from),
                       let toNode = AbilityTreeData.node(byId: edge.to) {
                        edgeLine(from: fromNode, to: toNode, in: treeSize)
                    }
                }
                
                // Draw nodes
                ForEach(AbilityTreeData.playerNodes) { node in
                    nodeView(node, in: treeSize)
                }
            }
            .frame(width: treeSize.width, height: treeSize.height)
            .scaleEffect(scale)
            .offset(offset)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
            .clipped()
            .contentShape(Rectangle())
            .gesture(
                SimultaneousGesture(
                    // Pinch to zoom
                    MagnificationGesture()
                        .updating($gestureScale) { value, state, _ in
                            state = value
                        }
                        .onEnded { value in
                            let newScale = currentScale * value
                            currentScale = min(max(newScale, minScale), maxScale)
                        },
                    // Drag to pan
                    DragGesture()
                        .updating($gestureOffset) { value, state, _ in
                            state = value.translation
                        }
                        .onEnded { value in
                            let maxOffset = calculateMaxOffset(geoSize: geo.size, treeSize: treeSize)
                            var newOffset = CGSize(
                                width: currentOffset.width + value.translation.width,
                                height: currentOffset.height + value.translation.height
                            )
                            // Clamp offset to prevent going too far
                            newOffset.width = min(max(newOffset.width, -maxOffset.width), maxOffset.width)
                            newOffset.height = min(max(newOffset.height, -maxOffset.height), maxOffset.height)
                            currentOffset = newOffset
                        }
                )
            )
            .onTapGesture(count: 2) {
                // Double tap to reset
                withAnimation(.spring(response: 0.3)) {
                    currentScale = 1.0
                    currentOffset = .zero
                }
            }
        }
    }
    
    private func calculateMaxOffset(geoSize: CGSize, treeSize: CGSize) -> CGSize {
        let scaledWidth = treeSize.width * scale
        let scaledHeight = treeSize.height * scale
        return CGSize(
            width: max(0, (scaledWidth - geoSize.width) / 2 + 100),
            height: max(0, (scaledHeight - geoSize.height) / 2 + 100)
        )
    }
    
    private func edgeLine(from: AbilityNode, to: AbilityNode, in size: CGSize) -> some View {
        let fromPoint = CGPoint(
            x: from.treeX * size.width,
            y: from.treeY * size.height
        )
        let toPoint = CGPoint(
            x: to.treeX * size.width,
            y: to.treeY * size.height
        )
        
        let isUnlocked = userData.abilities.unlockedPlayerAbilities.contains(from.id)
        
        return Path { path in
            path.move(to: fromPoint)
            path.addLine(to: toPoint)
        }
        .stroke(
            isUnlocked ? AppColors.brandPrimary : AppColors.surfaceElevated,
            lineWidth: 2
        )
    }
    
    private func nodeView(_ node: AbilityNode, in size: CGSize) -> some View {
        let isUnlocked = userData.abilities.unlockedPlayerAbilities.contains(node.id)
        let canUnlock = AbilityTreeSystem.shared.canUnlockAbility(node.id).canUnlock
        
        // Use plain view with onTapGesture instead of Button to allow pinch gestures to pass through
        return VStack(spacing: AppSpacing.xxs) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? AppColors.brandPrimary : 
                          canUnlock ? AppColors.surface : AppColors.surfaceElevated)
                    .frame(width: 50, height: 50)
                
                if isUnlocked {
                    Circle()
                        .stroke(AppColors.brandPrimary, lineWidth: 3)
                        .frame(width: 56, height: 56)
                } else if canUnlock {
                    Circle()
                        .stroke(AppColors.brandPrimary.opacity(0.5), lineWidth: 2)
                        .frame(width: 56, height: 56)
                }
                
                Image(systemName: node.iconName)
                    .font(.title3)
                    .foregroundColor(isUnlocked ? AppColors.background : 
                                    canUnlock ? AppColors.brandPrimary : AppColors.textTertiary)
            }
            
            Text(node.name)
                .font(AppTypography.caption2)
                .foregroundColor(isUnlocked ? AppColors.textPrimary : AppColors.textSecondary)
                .lineLimit(1)
                .frame(width: 70)
            
            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(AppColors.success)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedNode = node
        }
        .position(
            x: node.treeX * size.width,
            y: node.treeY * size.height
        )
    }
    
    // MARK: - Pet Abilities View
    private var petAbilitiesView: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                if userData.ownedPets.isEmpty {
                    emptyPetsState
                } else {
                    ForEach(userData.ownedPets) { pet in
                        petAbilityCard(pet)
                    }
                }
            }
            .padding(AppSpacing.screenPadding)
        }
    }
    
    private var emptyPetsState: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "pawprint")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textTertiary)
            Text("No pets yet")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textSecondary)
            Text("Catch pets during runs to upgrade their abilities")
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.xxl)
    }
    
    private func petAbilityCard(_ pet: OwnedPet) -> some View {
        let currentLevel = userData.abilities.getPetAbilityLevel(for: pet.id)
        let status = AbilityTreeSystem.shared.canUpgradePetAbility(pet.id)
        
        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(AppColors.forPet(pet.petDefinitionId).opacity(0.2))
                        .frame(width: 50, height: 50)
                    Text(pet.definition?.emoji ?? "🐾")
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(pet.definition?.name ?? "Unknown")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(pet.definition?.abilityName ?? "")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.brandPrimary)
                    
                    Text(pet.definition?.abilityDescription ?? "")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
            }
            
            // Level Display
            HStack {
                Text("Level:")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)
                
                ForEach(1...5, id: \.self) { level in
                    Image(systemName: level <= currentLevel ? "star.fill" : "star")
                        .foregroundColor(level <= currentLevel ? AppColors.gold : AppColors.textTertiary)
                        .font(.caption)
                }
                
                Spacer()
                
                let multiplier = AbilityConfig.shared.abilityMultiplier(forLevel: currentLevel)
                Text("\(Int(multiplier * 100))%")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.brandPrimary)
            }
            
            // Upgrade Button
            if currentLevel < 5 {
                Button {
                    if AbilityTreeSystem.shared.upgradePetAbility(pet.id) {
                        HapticsManager.shared.playAbilityUnlock()
                    }
                } label: {
                    HStack {
                        Text("Upgrade to Level \(currentLevel + 1)")
                        Spacer()
                        Text("\(status.cost) PP")
                            .foregroundColor(status.canUpgrade ? AppColors.textPrimary : AppColors.textTertiary)
                    }
                    .font(AppTypography.callout)
                    .foregroundColor(status.canUpgrade ? AppColors.textPrimary : AppColors.textTertiary)
                    .padding(AppSpacing.sm)
                    .background(status.canUpgrade ? AppColors.gems.opacity(0.2) : AppColors.surfaceElevated)
                    .cornerRadius(AppSpacing.radiusSm)
                }
                .disabled(!status.canUpgrade)
            } else {
                Text("MAX LEVEL")
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.success)
                    .frame(maxWidth: .infinity)
                    .padding(AppSpacing.sm)
                    .background(AppColors.success.opacity(0.1))
                    .cornerRadius(AppSpacing.radiusSm)
            }
        }
        .cardStyle()
    }
}

// MARK: - Ability Node Sheet
struct AbilityNodeSheet: View {
    @EnvironmentObject var userData: UserData
    @Environment(\.dismiss) var dismiss
    let node: AbilityNode
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.xl) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isUnlocked ? AppColors.brandPrimary : AppColors.surface)
                        .frame(width: 80, height: 80)
                    Image(systemName: node.iconName)
                        .font(.largeTitle)
                        .foregroundColor(isUnlocked ? AppColors.background : AppColors.brandPrimary)
                }
                
                // Info
                VStack(spacing: AppSpacing.sm) {
                    Text(node.name)
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(node.description)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    Text("Tier \(node.tier) • Cost: \(node.cost) AP")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                // Prerequisites
                if !node.prerequisites.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Requires:")
                            .font(AppTypography.footnote)
                            .foregroundColor(AppColors.textTertiary)
                        
                        ForEach(node.prerequisites, id: \.self) { prereqId in
                            if let prereq = AbilityTreeData.node(byId: prereqId) {
                                HStack {
                                    Image(systemName: userData.abilities.unlockedPlayerAbilities.contains(prereqId) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(userData.abilities.unlockedPlayerAbilities.contains(prereqId) ? AppColors.success : AppColors.textTertiary)
                                    Text(prereq.name)
                                        .font(AppTypography.subheadline)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.radiusMd)
                }
                
                Spacer()
                
                // Action Button
                if isUnlocked {
                    Label("Unlocked", systemImage: "checkmark.circle.fill")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.success)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.success.opacity(0.1))
                        .cornerRadius(AppSpacing.radiusMd)
                } else {
                    let status = AbilityTreeSystem.shared.canUnlockAbility(node.id)
                    
                    Button {
                        if AbilityTreeSystem.shared.unlockAbility(node.id) {
                            HapticsManager.shared.playAbilityUnlock()
                            dismiss()
                        }
                    } label: {
                        Text(status.canUnlock ? "Unlock (\(node.cost) AP)" : (status.reason ?? "Cannot unlock"))
                            .font(AppTypography.headline)
                            .foregroundColor(status.canUnlock ? AppColors.textPrimary : AppColors.textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(status.canUnlock ? AppColors.brandPrimary : AppColors.surfaceElevated)
                            .cornerRadius(AppSpacing.radiusMd)
                    }
                    .disabled(!status.canUnlock)
                }
            }
            .padding(AppSpacing.screenPadding)
            .background(AppColors.background)
            .navigationTitle(node.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var isUnlocked: Bool {
        userData.abilities.unlockedPlayerAbilities.contains(node.id)
    }
}

#Preview {
    AbilitiesView()
        .environmentObject(UserData.shared)
}
