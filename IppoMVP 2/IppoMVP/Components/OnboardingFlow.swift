// OnboardingFlow.swift
// Adapted for Ippo - First Launch Experience
// Source: ~/clawd/tools/ui-ux/swiftui-components/OnboardingFlow.swift
// Patterns from: Duolingo onboarding, Nike Run Club setup, Apple Fitness+ intro
//
// Usage:
// - First launch: IppoWelcomeView → IppoOnboardingCarousel → WatchPairingView → PermissionFlowView → IppoReadyView
// - Settings > Setup Watch: IppoWatchPairingView

import SwiftUI
import HealthKit

// MARK: - Onboarding Page Model

struct OnboardingPage: Identifiable {
    let id = UUID()
    let image: OnboardingImage
    let title: String
    let subtitle: String
    let accentColor: Color
    
    enum OnboardingImage {
        case systemName(String)      // SF Symbol
        case assetName(String)       // Asset catalog image
        case custom(AnyView)         // Custom view
    }
}

// MARK: - Page Carousel Onboarding

struct IppoOnboardingCarousel: View {
    let pages: [OnboardingPage]
    var onComplete: () -> Void
    
    @State private var currentPage = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    // MARK: - Accessibility
    private var carouselAccessibilityLabel: String {
        "Onboarding, page \(currentPage + 1) of \(pages.count)"
    }
    
    private var carouselAccessibilityValue: String {
        pages[currentPage].title
    }
    
    var body: some View {
        ZStack {
            // Background
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        IppoOnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Bottom controls
                VStack(spacing: AppSpacing.xl) {
                    // Page indicators
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage ? pages[currentPage].accentColor : AppColors.textTertiary.opacity(0.3))
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                                .animation(reduceMotion ? .none : .spring(response: 0.3), value: currentPage)
                        }
                    }
                    .accessibilityHidden(true) // Decorative - page info in main label
                    
                    // Buttons
                    HStack(spacing: AppSpacing.lg) {
                        // Skip button (not on last page)
                        if currentPage < pages.count - 1 {
                            Button("Skip") {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                onComplete()
                            }
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .accessibilityLabel("Skip onboarding")
                            .accessibilityHint("Skip to the main app")
                        }
                        
                        // Continue/Get Started button
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            
                            if currentPage < pages.count - 1 {
                                if reduceMotion {
                                    currentPage += 1
                                } else {
                                    withAnimation(.spring(response: 0.4)) {
                                        currentPage += 1
                                    }
                                }
                            } else {
                                onComplete()
                            }
                        }) {
                            Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.background)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(pages[currentPage].accentColor)
                                .cornerRadius(25)
                        }
                        .accessibilityLabel(currentPage == pages.count - 1 ? "Get Started" : "Continue to next page")
                        .accessibilityHint(currentPage == pages.count - 1 ? "Complete onboarding and start using Ippo" : "Go to page \(currentPage + 2) of \(pages.count)")
                    }
                    .padding(.horizontal, AppSpacing.xl)
                }
                .padding(.bottom, AppSpacing.xxxl)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(carouselAccessibilityLabel)
        .accessibilityValue(carouselAccessibilityValue)
    }
}

// MARK: - Single Onboarding Page

struct IppoOnboardingPageView: View {
    let page: OnboardingPage
    
    // MARK: - Accessibility
    private var pageAccessibilityDescription: String {
        "\(page.title). \(page.subtitle)"
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.xxl) {
            Spacer()
            
            // Image/illustration
            Group {
                switch page.image {
                case .systemName(let name):
                    ZStack {
                        Circle()
                            .fill(page.accentColor.opacity(0.15))
                            .frame(width: 180, height: 180)
                        
                        Circle()
                            .fill(page.accentColor.opacity(0.3))
                            .frame(width: 140, height: 140)
                        
                        Image(systemName: name)
                            .font(.system(size: 70, weight: .medium))
                            .foregroundColor(page.accentColor)
                    }
                    .frame(height: 200)
                        
                case .assetName(let name):
                    Image(name)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        
                case .custom(let view):
                    view
                        .frame(height: 200)
                }
            }
            .padding(.bottom, AppSpacing.xl)
            .accessibilityHidden(true) // Decorative - content described by text
            
            // Text content
            VStack(spacing: AppSpacing.lg) {
                Text(page.title)
                    .font(AppTypography.title1)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, AppSpacing.xxl)
            }
            
            Spacer()
            Spacer()
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(pageAccessibilityDescription)
    }
}

// MARK: - Permission Types & Status

enum IppoPermissionType {
    case health
    case notifications
    case location
    case motion
    
    var icon: String {
        switch self {
        case .health: return "heart.fill"
        case .notifications: return "bell.fill"
        case .location: return "location.fill"
        case .motion: return "figure.walk.motion"
        }
    }
    
    var color: Color {
        switch self {
        case .health: return AppColors.danger       // Red for health/heart
        case .notifications: return AppColors.warning  // Orange for notifications
        case .location: return AppColors.brandPrimary  // Ippo cyan for location
        case .motion: return AppColors.success        // Green for motion
        }
    }
    
    var title: String {
        switch self {
        case .health: return "Health Access"
        case .notifications: return "Notifications"
        case .location: return "Location"
        case .motion: return "Motion & Fitness"
        }
    }
    
    var description: String {
        switch self {
        case .health: return "Track your heart rate to calculate Effort Points. The harder you work, the more EP you earn!"
        case .notifications: return "Get reminded to run, celebrate achievements, and keep your streak alive."
        case .location: return "Map your runs and track your routes."
        case .motion: return "Detect when you're running and automatically track your activity."
        }
    }
    
    var benefits: [String] {
        switch self {
        case .health:
            return [
                "Calculate Effort Points from heart rate",
                "Track effort zones in real-time",
                "Sync Apple Watch workouts"
            ]
        case .notifications:
            return [
                "Daily run reminders",
                "Achievement celebrations",
                "Streak warnings before you lose them"
            ]
        case .location:
            return [
                "Map your running routes",
                "See distance traveled",
                "Share route screenshots"
            ]
        case .motion:
            return [
                "Auto-detect runs",
                "Step counting",
                "Activity recognition"
            ]
        }
    }
}

enum IppoPermissionStatus {
    case notDetermined
    case granted
    case denied
}

// MARK: - Permission Request View

struct IppoPermissionRequestView: View {
    let permission: IppoPermissionType
    let status: IppoPermissionStatus
    var onRequest: () -> Void
    var onSkip: (() -> Void)? = nil
    
    // MARK: - Accessibility
    private var permissionAccessibilityDescription: String {
        var desc = "\(permission.title). \(permission.description)"
        desc += " Benefits: \(permission.benefits.joined(separator: ". "))"
        return desc
    }
    
    private var statusAccessibilityDescription: String {
        switch status {
        case .notDetermined: return "Permission not yet requested"
        case .granted: return "Permission granted"
        case .denied: return "Permission denied"
        }
    }
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.xxl) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(permission.color.opacity(0.15))
                        .frame(width: 140, height: 140)
                    
                    Circle()
                        .fill(permission.color.opacity(0.3))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: permission.icon)
                        .font(.system(size: 44, weight: .medium))
                        .foregroundColor(permission.color)
                }
                .accessibilityHidden(true) // Decorative
                
                // Title and description
                VStack(spacing: AppSpacing.md) {
                    Text(permission.title)
                        .font(AppTypography.title1)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(permission.description)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xl)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(permission.title). \(permission.description)")
                
                // Benefits list
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    ForEach(permission.benefits, id: \.self) { benefit in
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(permission.color)
                                .accessibilityHidden(true)
                            
                            Text(benefit)
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Spacer()
                        }
                    }
                }
                .padding(AppSpacing.xl)
                .background(AppColors.surface)
                .cornerRadius(AppSpacing.radiusLg)
                .padding(.horizontal, AppSpacing.xl)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Benefits")
                .accessibilityValue(permission.benefits.joined(separator: ". "))
                
                Spacer()
                
                // Buttons
                VStack(spacing: AppSpacing.md) {
                    switch status {
                    case .notDetermined:
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            onRequest()
                        }) {
                            Text("Allow \(permission.title)")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.background)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(permission.color)
                                .cornerRadius(25)
                        }
                        .accessibilityLabel("Allow \(permission.title)")
                        .accessibilityHint("Grant \(permission.title) permission to Ippo")
                        
                        if let onSkip = onSkip {
                            Button("Maybe Later") {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                onSkip()
                            }
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                            .accessibilityLabel("Maybe Later")
                            .accessibilityHint("Skip this permission for now. You can enable it later in Settings.")
                        }
                        
                    case .granted:
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .accessibilityHidden(true)
                            Text("Permission Granted")
                                .font(AppTypography.headline)
                        }
                        .foregroundColor(AppColors.success)
                        .frame(height: 50)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(permission.title) permission granted")
                        
                    case .denied:
                        VStack(spacing: AppSpacing.sm) {
                            Text("Permission Denied")
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.danger)
                            
                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.brandPrimary)
                            .accessibilityLabel("Open Settings")
                            .accessibilityHint("Open iOS Settings to manually enable \(permission.title) permission")
                        }
                        .accessibilityElement(children: .contain)
                    }
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.xxxl)
            }
        }
    }
}

// MARK: - Multi-Permission Flow

struct IppoPermissionFlowView: View {
    let permissions: [IppoPermissionType]
    @State private var permissionStatuses: [IppoPermissionType: IppoPermissionStatus]
    @State private var currentIndex = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onComplete: () -> Void
    
    // MARK: - Accessibility
    private var flowAccessibilityLabel: String {
        "Permission setup, step \(currentIndex + 1) of \(permissions.count)"
    }
    
    init(permissions: [IppoPermissionType], onComplete: @escaping () -> Void) {
        self.permissions = permissions
        self.onComplete = onComplete
        
        var statuses: [IppoPermissionType: IppoPermissionStatus] = [:]
        for permission in permissions {
            statuses[permission] = .notDetermined
        }
        self._permissionStatuses = State(initialValue: statuses)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(AppColors.surface)
                    
                    Rectangle()
                        .fill(permissions[currentIndex].color)
                        .frame(width: geo.size.width * (Double(currentIndex + 1) / Double(permissions.count)))
                        .animation(reduceMotion ? .none : .spring(response: 0.4), value: currentIndex)
                }
            }
            .frame(height: 4)
            .accessibilityHidden(true) // Decorative - progress announced in label
            
            // Current permission view
            IppoPermissionRequestView(
                permission: permissions[currentIndex],
                status: permissionStatuses[permissions[currentIndex]] ?? .notDetermined,
                onRequest: {
                    requestPermission(permissions[currentIndex])
                },
                onSkip: {
                    moveToNext()
                }
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(flowAccessibilityLabel)
    }
    
    private func requestPermission(_ permission: IppoPermissionType) {
        // Simulate permission request
        permissionStatuses[permission] = .granted
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            moveToNext()
        }
    }
    
    private func moveToNext() {
        if currentIndex < permissions.count - 1 {
            if reduceMotion {
                currentIndex += 1
            } else {
                withAnimation(.spring(response: 0.4)) {
                    currentIndex += 1
                }
            }
        } else {
            onComplete()
        }
    }
}

// MARK: - Watch Pairing View

struct IppoWatchPairingView: View {
    @State private var isPairing = false
    @State private var isPaired = false
    @State private var showError = false
    @State private var pulseScale: CGFloat = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onComplete: () -> Void
    var onSkip: () -> Void
    
    // MARK: - Accessibility
    private var statusAccessibilityDescription: String {
        if isPaired {
            return "Watch connected. Your Apple Watch is ready to track your effort in real-time."
        } else if isPairing {
            return "Searching for Apple Watch. Please wait."
        } else {
            return "Connect your Apple Watch to track heart rate and earn Effort Points in real-time during runs."
        }
    }
    
    private var benefitsAccessibilityDescription: String {
        "Benefits: Real-time heart rate monitoring, Effort-based EP calculation, Accurate workout data, Haptic milestone alerts"
    }
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.xxl) {
                Spacer()
                
                // Watch illustration
                ZStack {
                    // Pulse animation when pairing (respects reduceMotion)
                    if isPairing && !reduceMotion {
                        Circle()
                            .stroke(AppColors.brandPrimary.opacity(0.3), lineWidth: 2)
                            .frame(width: 180, height: 180)
                            .scaleEffect(pulseScale)
                            .opacity(2.0 - pulseScale)
                    }
                    
                    Circle()
                        .fill(isPaired ? AppColors.success.opacity(0.15) : AppColors.surface)
                        .frame(width: 140, height: 140)
                    
                    if isPaired {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60, weight: .medium))
                            .foregroundColor(AppColors.success)
                    } else {
                        Image(systemName: "applewatch")
                            .font(.system(size: 70, weight: .light))
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                .frame(height: 200)
                .accessibilityHidden(true) // Decorative - status announced in text
                
                // Title and status
                VStack(spacing: AppSpacing.md) {
                    Text(isPaired ? "Watch Connected!" : "Connect Your Apple Watch")
                        .font(AppTypography.title1)
                        .foregroundColor(AppColors.textPrimary)
                    
                    if isPairing {
                        HStack(spacing: AppSpacing.sm) {
                            ProgressView()
                                .tint(AppColors.brandPrimary)
                            Text("Searching for watch...")
                                .font(AppTypography.body)
                        }
                        .foregroundColor(AppColors.textSecondary)
                    } else if isPaired {
                        Text("Your Apple Watch is ready to track your effort in real-time.")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.xl)
                    } else {
                        Text("Track your heart rate and earn Effort Points in real-time during runs.")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.xl)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(statusAccessibilityDescription)
                
                // Benefits
                if !isPaired && !isPairing {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        IppoBenefitRow(icon: "heart.fill", color: AppColors.danger, text: "Real-time heart rate monitoring")
                        IppoBenefitRow(icon: "bolt.heart.fill", color: AppColors.brandPrimary, text: "Effort-based EP calculation")
                        IppoBenefitRow(icon: "waveform.path.ecg", color: AppColors.success, text: "Accurate workout data")
                        IppoBenefitRow(icon: "applewatch.radiowaves.left.and.right", color: AppColors.brandSecondary, text: "Haptic milestone alerts")
                    }
                    .padding(AppSpacing.xl)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.radiusLg)
                    .padding(.horizontal, AppSpacing.xl)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(benefitsAccessibilityDescription)
                }
                
                if showError {
                    Text("No Apple Watch found. Make sure your watch is nearby and awake.")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.danger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xl)
                        .accessibilityLabel("Error: No Apple Watch found. Make sure your watch is nearby and awake.")
                }
                
                Spacer()
                
                // Buttons
                VStack(spacing: AppSpacing.md) {
                    if isPaired {
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            onComplete()
                        }) {
                            Text("Continue")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.background)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(AppColors.success)
                                .cornerRadius(25)
                        }
                        .accessibilityLabel("Continue")
                        .accessibilityHint("Proceed to the next step with your watch connected")
                    } else if isPairing {
                        Button("Cancel") {
                            isPairing = false
                        }
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .accessibilityLabel("Cancel pairing")
                        .accessibilityHint("Stop searching for Apple Watch")
                    } else {
                        Button(action: startPairing) {
                            Text("Connect Watch")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.background)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(AppColors.brandPrimary)
                                .cornerRadius(25)
                        }
                        .accessibilityLabel("Connect Watch")
                        .accessibilityHint("Start searching for your Apple Watch")
                        
                        Button("Skip for Now") {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            onSkip()
                        }
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .accessibilityLabel("Skip for Now")
                        .accessibilityHint("Continue without connecting an Apple Watch. You can connect later in Settings.")
                    }
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.xxxl)
            }
        }
        .onChange(of: isPairing) { newValue in
            if newValue && !reduceMotion {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                    pulseScale = 1.5
                }
            } else {
                pulseScale = 1.0
            }
        }
    }
    
    private func startPairing() {
        isPairing = true
        showError = false
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Simulate pairing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            isPairing = false
            isPaired = true
            
            let successGenerator = UINotificationFeedbackGenerator()
            successGenerator.notificationOccurred(.success)
        }
    }
}

private struct IppoBenefitRow: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
                .accessibilityHidden(true) // Decorative
            
            Text(text)
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
        }
    }
}

// MARK: - Welcome View (First Screen)

struct IppoWelcomeView: View {
    var onStart: () -> Void
    
    @State private var showContent = false
    @State private var logoScale: CGFloat = 0.5
    @State private var logoRotation: Double = -20
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [AppColors.background, AppColors.surface],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.xxl) {
                Spacer()
                
                // Logo/App icon with animated runner
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [AppColors.brandPrimary.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 50,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                        .scaleEffect(reduceMotion ? 1.0 : logoScale)
                    
                    // Main circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.brandPrimary, AppColors.brandSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(reduceMotion ? 1.0 : logoScale)
                        .shadow(color: AppColors.brandPrimary.opacity(0.5), radius: 20)
                    
                    // Runner icon
                    Image(systemName: "figure.run")
                        .font(.system(size: 60, weight: .semibold))
                        .foregroundColor(.white)
                        .scaleEffect(reduceMotion ? 1.0 : logoScale)
                        .rotationEffect(.degrees(reduceMotion ? 0 : logoRotation))
                }
                .accessibilityHidden(true) // Decorative logo
                
                // Welcome text (always show immediately for reduceMotion)
                if showContent || reduceMotion {
                    VStack(spacing: AppSpacing.lg) {
                        Text("Welcome to Ippo")
                            .font(AppTypography.largeTitle)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Running reimagined. Earn Effort Points based on how hard you push—not how fast you go.")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, AppSpacing.xxl)
                    }
                    .transition(reduceMotion ? .identity : .opacity.combined(with: .move(edge: .bottom)))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Welcome to Ippo. Running reimagined. Earn Effort Points based on how hard you push—not how fast you go.")
                }
                
                Spacer()
                
                // Start button (always show immediately for reduceMotion)
                if showContent || reduceMotion {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        onStart()
                    }) {
                        Text("Let's Go")
                            .font(AppTypography.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: [AppColors.brandPrimary, AppColors.brandSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                            .shadow(color: AppColors.brandPrimary.opacity(0.4), radius: 10, y: 5)
                    }
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.bottom, AppSpacing.xxxl)
                    .transition(reduceMotion ? .identity : .opacity.combined(with: .move(edge: .bottom)))
                    .accessibilityLabel("Let's Go")
                    .accessibilityHint("Start onboarding and learn about Ippo")
                }
            }
        }
        .onAppear {
            guard !reduceMotion else {
                // For reduceMotion, immediately show final state
                logoScale = 1.0
                logoRotation = 0
                showContent = true
                return
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                logoScale = 1.0
                logoRotation = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showContent = true
                }
            }
        }
    }
}

// MARK: - Complete Onboarding Flow

struct IppoCompleteOnboardingFlow: View {
    @State private var currentStep: IppoOnboardingStep = .welcome
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onComplete: () -> Void
    
    enum IppoOnboardingStep: CaseIterable {
        case welcome
        case features
        case watchPairing
        case permissions
        case ready
        
        var stepNumber: Int {
            switch self {
            case .welcome: return 1
            case .features: return 2
            case .watchPairing: return 3
            case .permissions: return 4
            case .ready: return 5
            }
        }
        
        var stepName: String {
            switch self {
            case .welcome: return "Welcome"
            case .features: return "Features"
            case .watchPairing: return "Watch Setup"
            case .permissions: return "Permissions"
            case .ready: return "Ready"
            }
        }
    }
    
    // Ippo-specific feature pages
    private let featurePages: [OnboardingPage] = [
        OnboardingPage(
            image: .systemName("bolt.heart.fill"),
            title: "Earn Effort Points",
            subtitle: "Your effort matters, not your pace. Push yourself and earn more EP—regardless of your speed. Every drop of sweat counts.",
            accentColor: AppColors.brandPrimary
        ),
        OnboardingPage(
            image: .systemName("pawprint.fill"),
            title: "Collect Companions",
            subtitle: "Hatch and evolve adorable pets that grow stronger as you run. Your runs power their evolution!",
            accentColor: AppColors.brandSecondary
        ),
        OnboardingPage(
            image: .systemName("trophy.fill"),
            title: "Unlock Achievements",
            subtitle: "Earn badges, break personal records, and build your running legacy. Every milestone gets celebrated.",
            accentColor: AppColors.gold
        ),
        OnboardingPage(
            image: .systemName("flame.fill"),
            title: "Build Streaks",
            subtitle: "Run consistently and watch your streak grow. Keep the flame alive and earn bonus EP!",
            accentColor: AppColors.warning
        )
    ]
    
    var body: some View {
        ZStack {
            switch currentStep {
            case .welcome:
                IppoWelcomeView {
                    transitionTo(.features)
                }
                
            case .features:
                IppoOnboardingCarousel(pages: featurePages) {
                    transitionTo(.watchPairing)
                }
                
            case .watchPairing:
                IppoWatchPairingView {
                    transitionTo(.permissions)
                } onSkip: {
                    transitionTo(.permissions)
                }
                
            case .permissions:
                IppoPermissionFlowView(permissions: [.health, .notifications]) {
                    transitionTo(.ready)
                }
                
            case .ready:
                IppoReadyView {
                    onComplete()
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Ippo onboarding, step \(currentStep.stepNumber) of 5, \(currentStep.stepName)")
    }
    
    private func transitionTo(_ step: IppoOnboardingStep) {
        if reduceMotion {
            currentStep = step
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = step
            }
        }
    }
}

// MARK: - Ready View (Final Screen)

struct IppoReadyView: View {
    var onStart: () -> Void
    
    @State private var showContent = false
    @State private var showConfetti = false
    @State private var checkmarkScale: CGFloat = 0.5
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.xxl) {
                Spacer()
                
                // Checkmark with glow
                ZStack {
                    Circle()
                        .fill(AppColors.success.opacity(0.15))
                        .frame(width: 160, height: 160)
                    
                    Circle()
                        .fill(AppColors.success.opacity(0.3))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(AppColors.success)
                        .scaleEffect(reduceMotion ? 1.0 : checkmarkScale)
                }
                .accessibilityHidden(true) // Decorative - status announced in text
                
                // Always show content immediately for reduceMotion
                if showContent || reduceMotion {
                    VStack(spacing: AppSpacing.lg) {
                        Text("You're All Set!")
                            .font(AppTypography.largeTitle)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Time to start your running journey. Your first pet is waiting to be hatched—go earn some Effort Points!")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, AppSpacing.xxl)
                    }
                    .transition(reduceMotion ? .identity : .opacity.combined(with: .move(edge: .bottom)))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("You're All Set! Time to start your running journey. Your first pet is waiting to be hatched—go earn some Effort Points!")
                }
                
                Spacer()
                
                if showContent || reduceMotion {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        onStart()
                    }) {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "figure.run")
                                .accessibilityHidden(true)
                            Text("Start Running")
                        }
                        .font(AppTypography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppColors.success)
                        .cornerRadius(25)
                        .shadow(color: AppColors.success.opacity(0.4), radius: 10, y: 5)
                    }
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.bottom, AppSpacing.xxxl)
                    .transition(reduceMotion ? .identity : .opacity)
                    .accessibilityLabel("Start Running")
                    .accessibilityHint("Complete onboarding and start using Ippo")
                }
            }
            
            // Confetti (skip for reduceMotion)
            if showConfetti && !reduceMotion {
                IppoConfettiOverlay(reduceMotion: false)
            }
        }
        .onAppear {
            guard !reduceMotion else {
                // For reduceMotion, immediately show final state (no animations, no confetti)
                checkmarkScale = 1.0
                showContent = true
                // Still fire haptic (tactile, not visual)
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                return
            }
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                checkmarkScale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
                
                withAnimation(.easeOut(duration: 0.5)) {
                    showContent = true
                }
                
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }
}

// MARK: - Ippo Confetti Overlay

private struct IppoConfettiOverlay: View {
    let reduceMotion: Bool
    
    @State private var particles: [IppoConfettiParticle] = []
    
    // Ippo brand colors for confetti
    private let confettiColors: [Color] = [
        AppColors.brandPrimary,
        AppColors.brandSecondary,
        AppColors.success,
        AppColors.gold,
        AppColors.gems,
        AppColors.warning,
        AppColors.danger
    ]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(particle.color)
                        .frame(width: particle.width, height: particle.height)
                        .rotationEffect(.degrees(particle.rotation))
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geo.size)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true) // Decorative animation
    }
    
    private func createParticles(in size: CGSize) {
        // For reduceMotion, show brief static fade
        if reduceMotion {
            for i in 0..<40 {
                let particle = IppoConfettiParticle(
                    id: i,
                    color: confettiColors.randomElement()!,
                    width: CGFloat.random(in: 8...14),
                    height: CGFloat.random(in: 4...8),
                    rotation: Double.random(in: 0...360),
                    // Static random positions
                    position: CGPoint(
                        x: CGFloat.random(in: 0...size.width),
                        y: CGFloat.random(in: 0...size.height)
                    ),
                    opacity: 1.0
                )
                particles.append(particle)
            }
            
            // Fade out after 1 second (no motion, just opacity change)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    for i in 0..<particles.count {
                        particles[i].opacity = 0
                    }
                }
            }
            return
        }
        
        // Full animation for non-reduceMotion
        for i in 0..<80 {
            let particle = IppoConfettiParticle(
                id: i,
                color: confettiColors.randomElement()!,
                width: CGFloat.random(in: 8...14),
                height: CGFloat.random(in: 4...8),
                rotation: Double.random(in: 0...360),
                position: CGPoint(x: CGFloat.random(in: 0...size.width), y: -20),
                opacity: 1.0
            )
            particles.append(particle)
            
            let delay = Double(i) * 0.012
            let endX = particle.position.x + CGFloat.random(in: -80...80)
            let endY = size.height + 50
            let endRotation = particle.rotation + Double.random(in: 360...720)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: Double.random(in: 2.0...3.2))) {
                    if let index = particles.firstIndex(where: { $0.id == i }) {
                        particles[index].position = CGPoint(x: endX, y: endY)
                        particles[index].rotation = endRotation
                        particles[index].opacity = 0
                    }
                }
            }
        }
    }
}

private struct IppoConfettiParticle: Identifiable {
    let id: Int
    let color: Color
    let width: CGFloat
    let height: CGFloat
    var rotation: Double
    var position: CGPoint
    var opacity: Double
}

// MARK: - Previews

#Preview("Welcome View") {
    IppoWelcomeView {
        print("Start tapped")
    }
}

#Preview("Feature Carousel") {
    IppoOnboardingCarousel(pages: [
        OnboardingPage(
            image: .systemName("bolt.heart.fill"),
            title: "Earn Effort Points",
            subtitle: "Your effort matters, not your pace. Push yourself and earn more EP.",
            accentColor: AppColors.brandPrimary
        ),
        OnboardingPage(
            image: .systemName("pawprint.fill"),
            title: "Collect Companions",
            subtitle: "Hatch and evolve adorable pets that grow stronger as you run.",
            accentColor: AppColors.brandSecondary
        ),
        OnboardingPage(
            image: .systemName("trophy.fill"),
            title: "Unlock Achievements",
            subtitle: "Earn badges and break personal records.",
            accentColor: AppColors.gold
        )
    ]) {
        print("Complete")
    }
}

#Preview("Permission Request - Health") {
    IppoPermissionRequestView(
        permission: .health,
        status: .notDetermined,
        onRequest: { print("Request") },
        onSkip: { print("Skip") }
    )
}

#Preview("Permission Request - Notifications") {
    IppoPermissionRequestView(
        permission: .notifications,
        status: .notDetermined,
        onRequest: { print("Request") },
        onSkip: { print("Skip") }
    )
}

#Preview("Watch Pairing") {
    IppoWatchPairingView(
        onComplete: { print("Complete") },
        onSkip: { print("Skip") }
    )
}

#Preview("Ready View") {
    IppoReadyView {
        print("Start")
    }
}

#Preview("Complete Flow") {
    IppoCompleteOnboardingFlow {
        print("Onboarding complete")
    }
}
