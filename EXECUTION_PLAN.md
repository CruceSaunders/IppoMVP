# IppoMVP Comprehensive Overhaul Plan

## Critical Discovery
**The app currently uses UserDefaults for data persistence, NOT Firebase!**
This is why data doesn't persist across TestFlight updates.

---

## Phase 1: Firebase Integration (CRITICAL)

### 1.1 Add Firebase SDK
- Add Firebase Swift Package (FirebaseAuth, FirebaseFirestore)
- Configure `GoogleService-Info.plist`
- Initialize Firebase in `IppoMVPApp.swift`

### 1.2 Create FirebaseService.swift
Replace `DataPersistence.swift` with proper Firebase persistence:
```swift
// Store user data in Firestore under users/{userId}/
// - profile document
// - pets subcollection
// - abilities document
// - inventory document
// - runHistory subcollection
```

### 1.3 Auth Flow
- Sign in with Apple or Anonymous auth
- Link user data to Firebase user ID
- Sync on app launch, save on changes

---

## Phase 2: Daily Rewards Fix

### 2.1 Current Bug Analysis
The daily rewards isn't tracking properly because:
1. Streak data stored in UserDefaults (gets wiped)
2. Day calculation may have timezone issues

### 2.2 Fix Implementation
- Store daily rewards state in Firebase
- Add proper date comparison with timezone handling
- Track: `lastClaimDate`, `currentDay`, `streakCount`

---

## Phase 3: Home Page Overhaul

### 3.1 REMOVE from HomeView.swift:
- `rankSection` - Remove entirely (will have Ranks tab)
- `petCollectionPreview` - Remove entirely
- Any Training Load / Effort Records (if present)
- Any Achievements section (move to profile)

### 3.2 KEEP/MODIFY:
- `welcomeSection` - Keep
- `startRunSection` - Keep  
- `equippedPetSection` - Keep
- `recentRunsSection` - Keep

### 3.3 ADD to HomeView:
- **Challenges Section** - Combine weekly + monthly challenges together
  - February Challenge card
  - Weekly Challenge card
  - Place them adjacent
- **Daily Rewards Card** - Compact view showing streak + collect button
- **Start Your Streak** - If no streak active

### 3.4 New Home Layout Order:
1. Welcome Section
2. Start Run CTA
3. Daily Reward Card (compact)
4. Challenges (Weekly + Monthly together)
5. Equipped Pet (if any)
6. Recent Runs

---

## Phase 4: Profile Page Overhaul

### 4.1 ProfileView.swift Changes:

**KEEP:**
- Profile header (avatar, name, level, streak)
- XP Progress with level-up rewards

**MODIFY:**
- Stats Grid: Change "Sprints" to show total completed (not X/Y)
- Remove "Runner Points" or rename to "Reputation Points"
- Add visible "Reputation Points" display

**REMOVE:**
- Daily Goals notification toggle in settings
- "Ability Tree" link under Game section
- Rename "Game" section to "Items" - show first 3 inventory items

**ADD:**
- Achievements section (moved from home)
- Milestones section (combine with achievements as one unified system)
- Reputation Points display in header or stats

### 4.2 Unified Achievement System
Combine "Run Milestones" and "Achievements" into one system:
- All tracked as achievements
- Categories: Distance, Sprints, Streaks, Pets, etc.

---

## Phase 5: NEW Ranks Tab

### 5.1 Create RanksView.swift

**5 Ranks defined:**
1. **Bronze** (0-999 RP) - Icon: shield.fill
   - Perks: Base rewards
2. **Silver** (1000-2999 RP) - Icon: shield.lefthalf.filled
   - Perks: +5% coin bonus
3. **Gold** (3000-6999 RP) - Icon: shield.fill (gold)
   - Perks: +10% coin bonus, +5% XP bonus
4. **Platinum** (7000-14999 RP) - Icon: crown.fill
   - Perks: +15% coin bonus, +10% XP bonus, +5% catch rate
5. **Diamond** (15000+ RP) - Icon: diamond.fill
   - Perks: +25% coin bonus, +15% XP bonus, +10% catch rate

### 5.2 Ranks UI:
- Current rank display (large, prominent)
- Progress bar to next rank
- RP needed for next rank
- Perks for current rank
- Preview of next rank perks
- NOT a leaderboard (personal progression only)

### 5.3 Add to Tab Bar:
Update ContentView.swift to add Ranks tab (or integrate into existing tab structure)

---

## Phase 6: Ability Tree Redesign

### 6.1 Player Ability Tree - Complete Redesign

**Structure: 1 Origin → 5 Branches**

```
                    [ORIGIN: Runner's Heart]
                           |
         ┌─────────┬──────┴──────┬─────────┐─────────┐
         ▼         ▼             ▼         ▼         ▼
      [POWER]   [WEALTH]     [SPIRIT]   [BOND]   [FORTUNE]
         │         │             │         │         │
         ▼         ▼             ▼         ▼         ▼
       Tier 2    Tier 2       Tier 2    Tier 2    Tier 2
         │         │             │         │         │
         ▼         ▼             ▼         ▼         ▼
       Tier 3    Tier 3       Tier 3    Tier 3    Tier 3
```

**Branches:**

1. **POWER Branch** (RP/XP Focus)
   - Tier 1: XP Boost I (+10% XP)
   - Tier 2: XP Boost II (+15% XP)
   - Tier 3: RP Surge (+20% RP)
   - Tier 4: Effort Mastery (+25% RP from high effort)

2. **WEALTH Branch** (Coins/Rewards)
   - Tier 1: Coin Finder (+10% coins)
   - Tier 2: Lucky Loot (+15% loot box rewards)
   - Tier 3: Coin Boost II (+20% coins)
   - Tier 4: Treasure Hunter (rare item chance)

3. **SPIRIT Branch** (Streak/Consistency)
   - Tier 1: Streak Shield (1 day grace period)
   - Tier 2: Streak Bonus (+15% rewards per streak day)
   - Tier 3: Consistency (+10% all stats if 7+ streak)
   - Tier 4: Iron Will (streak bonus caps at 50%)

4. **BOND Branch** (Pet focused)
   - Tier 1: Quick Bond (+20% pet XP)
   - Tier 2: Mood Master (+1 max mood)
   - Tier 3: Evolution Boost (-15% pet XP needed)
   - Tier 4: Soul Link (pet ability +25% effectiveness)

5. **FORTUNE Branch** (Catch rate/Luck)
   - Tier 1: Sharp Eye (+5% catch rate)
   - Tier 2: Lucky Runner (+8% catch rate)
   - Tier 3: Pet Magnet (+12% catch rate)
   - Tier 4: Master Catcher (guaranteed rare encounters)

### 6.2 Visual Design Requirements:
- **NO crossing lines** - branches spread cleanly
- **Background**: Subtle animated starfield/universe effect
  - Very soft gradient (dark purple → deep blue)
  - Faint twinkling stars (opacity 0.1-0.3)
  - Slight parallax depth effect on pan
- Clean node connections with smooth curves (not straight lines)
- Glow effect on unlocked abilities
- Clear visual distinction between: Unlocked, Available, Locked

### 6.3 Pet Ability Trees - Full Redesign

Each of the 10 pets gets their own mini ability tree (not just levels 1-5).

**Pet Tree Structure:**
```
          [Core Ability]
               │
        ┌──────┴──────┐
        ▼             ▼
   [Enhance A]    [Enhance B]
        │             │
        ▼             ▼
   [Mastery A]    [Mastery B]
        │             │
        └──────┬──────┘
               ▼
          [Ultimate]
```

Each pet has 6 abilities total:
- 1 Core (free)
- 2 Enhance paths (cost 1 PP each)
- 2 Mastery (cost 2 PP each)
- 1 Ultimate (cost 3 PP, requires both masteries)

### 6.4 10 Pet Ability Trees:

**pet_01 - Ember (Fire)**
- Core: Spark (+10% XP)
- Enhance A: Flame (+15% XP) | Enhance B: Heat (+10% RP)
- Mastery A: Inferno (+25% XP) | Mastery B: Blaze (+20% RP)
- Ultimate: Phoenix Heart (+30% XP, +25% RP)

**pet_02 - Splash (Water)**
- Core: Ripple (+10% coins)
- Enhance A: Wave (+15% coins) | Enhance B: Current (+5% all stats)
- Mastery A: Tsunami (+25% coins) | Mastery B: Flow (+10% all stats)
- Ultimate: Ocean's Blessing (+30% coins, +15% all stats)

**pet_03 - Sprout (Nature)**
- Core: Growth (+15% pet XP)
- Enhance A: Bloom (+20% pet XP) | Enhance B: Root (+1 feeding/day)
- Mastery A: Forest (+30% pet XP) | Mastery B: Nature's Gift (+2 feeding)
- Ultimate: World Tree (+40% pet XP, unlimited feeding)

**pet_04 - Bolt (Electric)**
- Core: Zap (+8% sprint completion bonus)
- Enhance A: Shock (+12% sprint) | Enhance B: Static (+5% catch)
- Mastery A: Thunder (+18% sprint) | Mastery B: Lightning (+10% catch)
- Ultimate: Storm Lord (+25% sprint, +15% catch)

**pet_05 - Rocky (Earth)**
- Core: Foundation (streak grace +1 day)
- Enhance A: Boulder (grace +2) | Enhance B: Mountain (+10% streak bonus)
- Mastery A: Bedrock (grace +3) | Mastery B: Summit (+20% streak bonus)
- Ultimate: Eternal Stone (streak never breaks, +30% bonus)

**pet_06 - Spark (Light)**
- Core: Glimmer (+15% loot box rewards)
- Enhance A: Shine (+20% loot) | Enhance B: Ray (+5% rare item chance)
- Mastery A: Radiance (+30% loot) | Mastery B: Brilliance (+10% rare)
- Ultimate: Supernova (+50% loot, +20% rare items)

**pet_07 - Shadow (Dark)**
- Core: Stealth (+10% effort efficiency)
- Enhance A: Darkness (+15% effort) | Enhance B: Night (+10% RP after sunset)
- Mastery A: Void (+25% effort) | Mastery B: Midnight (+25% RP night runs)
- Ultimate: Eclipse (+35% effort, +40% night RP)

**pet_08 - Frost (Ice)**
- Core: Chill (preserve mood longer)
- Enhance A: Freeze (mood -50% decay) | Enhance B: Snow (+10% winter bonus)
- Mastery A: Glacier (mood no decay) | Mastery B: Blizzard (+25% winter)
- Ultimate: Absolute Zero (max mood always, +40% winter bonus)

**pet_09 - Breeze (Air)**
- Core: Gust (+5% speed bonus)
- Enhance A: Wind (+8% speed) | Enhance B: Draft (+5% all outdoor bonuses)
- Mastery A: Cyclone (+12% speed) | Mastery B: Tempest (+15% outdoor)
- Ultimate: Eternal Wind (+20% speed, +25% outdoor bonuses)

**pet_10 - Crystal (Gem)**
- Core: Facet (+5% all currencies)
- Enhance A: Gem (+8% currencies) | Enhance B: Prism (+5% ability points)
- Mastery A: Diamond (+12% currencies) | Mastery B: Jewel (+10% AP)
- Ultimate: Philosopher's Stone (+20% all currencies, +15% AP gain)

---

## Phase 7: Backend Verification Checklist

### Data That MUST Track Properly:
- [ ] Total runs completed
- [ ] Total sprints completed
- [ ] Pets caught/owned
- [ ] Daily rewards streak
- [ ] Reputation points
- [ ] XP and Level
- [ ] Coins and Gems
- [ ] Ability unlocks
- [ ] Pet evolution stages
- [ ] Run history

### Verification Steps:
1. Complete a run → verify all stats update
2. Catch a pet → verify pet collection updates
3. Claim daily reward → verify streak tracks
4. Level up → verify XP and AP update
5. Unlock ability → verify persists after app restart

---

## Phase 8: UI Polish

### 8.1 AbilitiesView Background Animation
```swift
// Animated starfield background
struct StarfieldBackground: View {
    @State private var stars: [Star] = []
    
    var body: some View {
        Canvas { context, size in
            for star in stars {
                context.fill(
                    Circle().path(in: CGRect(x: star.x, y: star.y, width: star.size, height: star.size)),
                    with: .color(.white.opacity(star.opacity))
                )
            }
        }
        .onAppear { generateStars() }
    }
}
```

### 8.2 Clean Ability Tree Lines
- Use QuadCurve for smooth connections
- No line crossings
- Glow effect on active connections

---

## Implementation Order:

1. **Firebase Integration** (fixes core data issue)
2. **Home Page Cleanup** (removes unwanted elements)
3. **Profile Page Overhaul** (achievements, stats fixes)
4. **Ranks Tab** (new feature)
5. **Player Ability Tree Redesign** (visual + structure)
6. **Pet Ability Trees** (full tree per pet)
7. **Daily Rewards Fix** (Firebase-backed)
8. **Backend Verification** (ensure all tracking works)
9. **UI Polish** (animations, backgrounds)

---

## Files to Create/Modify:

### NEW Files:
- `Services/FirebaseService.swift`
- `UI/Views/RanksView.swift`
- `UI/Components/StarfieldBackground.swift`
- `Config/RankConfig.swift`
- `Config/PetAbilityTreeData.swift`
- `Core/Types/RankTypes.swift`
- `Core/Types/AchievementTypes.swift`

### MODIFY Files:
- `IppoMVPApp.swift` - Firebase init
- `ContentView.swift` - Add Ranks tab or Abilities tab
- `UI/Views/HomeView.swift` - Remove rank, pets preview; add challenges
- `UI/Views/ProfileView.swift` - Add achievements, fix stats
- `UI/Views/AbilitiesView.swift` - Complete redesign with starfield
- `Config/AbilityConfig.swift` - New tree structure
- `Systems/AbilityTreeSystem.swift` - Support new structure
- `Data/UserData.swift` - Firebase integration
- `Services/DataPersistence.swift` - Replace with Firebase calls

---

## Pet Images Verification:
Current pet images should be in Assets.xcassets. Verify:
- pet_01_stage1 through pet_01_stage10 (and all 10 pets)
- Or using AI-generated images stored somewhere

Check: `~/Projects/IppoMVP/IppoMVP 2/IppoMVP/Assets.xcassets/`
