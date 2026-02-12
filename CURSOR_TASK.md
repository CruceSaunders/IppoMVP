# IppoMVP Implementation Tasks

## Project Location
`~/Projects/IppoMVP/IppoMVP 2/IppoMVP/`

## Task 1: Add Firebase Swift Package

Add Firebase to the Xcode project using Swift Package Manager:
- Package URL: https://github.com/firebase/firebase-ios-sdk
- Products needed: FirebaseAuth, FirebaseFirestore
- Update IppoMVPApp.swift to call FirebaseApp.configure()

Update Services/FirebaseService.swift to use REAL Firestore instead of UserDefaults fallback:
- Properly initialize Firestore
- Save user data to Firestore document (users/{userId}/data)
- Load user data from Firestore
- Handle offline persistence

## Task 2: Create Pet Ability Trees

Currently pets have a simple level 1-5 system. We need BRANCHING ability trees for each pet.

Structure per pet (6 abilities each, branching):
```
Origin (free unlock)
    ├── Branch A (Tier 1) → A2 (Tier 2)
    └── Branch B (Tier 1) → B2 (Tier 2) → B3 (Tier 3)
```

Create unique trees for each of the 10 pets in GameData.swift:
1. **Astravyrn** (dragon) - Sprint/burst focus
2. **Solarok** (aquatic) - Steady effort focus
3. **Azyrith** (verdant) - Pet evolution focus
4. **Cosmoose** (cosmic) - Encounter focus
5. **Nebulyth** (abyssal) - Mood/preservation focus
6. **Lumirith** (radiant) - Reward amplification focus
7. **Kryonith** (beast) - Care/feeding focus
8. **Flitfoal** (stealth) - Catch rate focus
9. **Emberhart** (infernal) - Sustained effort focus
10. **Aurivern** (phoenix) - Universal boost focus

Each pet's tree should:
- Have 6 nodes total (1 origin + 5 abilities)
- Branch into 2 paths from origin
- Build on the pet's base ability theme
- Use cost progression: 0 → 1 → 2 → 3 → 3

## Task 3: Update Pet Abilities UI

Update AbilitiesView.swift pet tab to show:
- Visual ability tree (like player tree) instead of level bar
- Nodes connected with lines (no crossing)
- Unlock mechanics using petPoints
- Show which abilities are unlocked

## Task 4: Fix Data Model

Update Core/Types/AbilityTypes.swift:
- Change petAbilityLevels: [String: Int] to unlockedPetAbilities: [String: Set<String>]
- Add canUnlockPetAbility and unlockPetAbility methods
- Pet point costs for unlocking

Update AbilityTreeSystem.swift to handle pet ability trees.

## Task 5: Verify Compilation

After changes, verify project compiles without errors.

## Files to Modify
1. IppoMVP.xcodeproj/project.pbxproj (add Firebase package)
2. IppoMVPApp.swift (FirebaseApp.configure())
3. Services/FirebaseService.swift (real Firestore)
4. Data/GameData.swift (pet ability trees)
5. Core/Types/AbilityTypes.swift (pet ability data model)
6. UI/Views/AbilitiesView.swift (pet tree UI)
7. Systems/AbilityTreeSystem.swift (pet tree logic)
