import SwiftUI
import MapKit

// MARK: - Route Map Overlay Components
// Adapted from: Strava route visualization, Nike Run Club live maps, AllTrails elevation profiles
// Ippo Use: WatchRunningView (live), RunDetailView (summary), HistoryView (preview)
// Adapted for Ippo Design System: AppColors, AppSpacing, AppTypography

// MARK: - Data Models

/// Represents a single point along a running route
struct RoutePoint: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date
    let pace: Double? // seconds per km
    let heartRate: Int?
    let elevation: Double? // meters
    let distanceFromStart: Double // meters
    let effortPoints: Int? // EP earned at this point (optional)
    
    var effortZone: IppoEffortZone {
        guard let hr = heartRate else { return .recovery }
        switch hr {
        case 0..<110: return .recovery
        case 110..<130: return .easy
        case 130..<150: return .moderate
        case 150..<170: return .hard
        case 170...: return .max
        default: return .recovery
        }
    }
}

/// Ippo effort zones for coloring (aligned with EffortZones.swift)
enum IppoEffortZone: Int, CaseIterable {
    case recovery = 0
    case easy = 1
    case moderate = 2
    case hard = 3
    case max = 4
    
    var color: Color {
        switch self {
        case .recovery: return AppColors.textTertiary
        case .easy: return AppColors.brandPrimary // Cyan - Ippo's signature
        case .moderate: return AppColors.success
        case .hard: return AppColors.warning
        case .max: return AppColors.danger
        }
    }
    
    var label: String {
        switch self {
        case .recovery: return "Recovery"
        case .easy: return "Easy"
        case .moderate: return "Moderate"
        case .hard: return "Hard"
        case .max: return "Max"
        }
    }
    
    var icon: String {
        switch self {
        case .recovery: return "figure.walk"
        case .easy: return "figure.run"
        case .moderate: return "flame"
        case .hard: return "flame.fill"
        case .max: return "bolt.heart.fill"
        }
    }
    
    /// EP multiplier for this zone
    var epMultiplier: Double {
        switch self {
        case .recovery: return 0.5
        case .easy: return 1.0
        case .moderate: return 1.5
        case .hard: return 2.0
        case .max: return 3.0
        }
    }
}

/// Represents a split/milestone along the route
struct RouteSplit: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let splitNumber: Int // 1, 2, 3...
    let pace: String // "5:45"
    let effortPoints: Int? // EP earned during this split
    let isKilometer: Bool // true = km, false = mile
}

// MARK: - Route Polyline

/// A gradient polyline showing pace or effort along the route
/// Pattern: Strava's colored route lines that show intensity
struct RouteGradientPolyline: View {
    let points: [RoutePoint]
    let colorMode: ColorMode
    let lineWidth: CGFloat
    
    enum ColorMode {
        case pace     // Color by pace (fast = green, slow = red)
        case effort   // Color by heart rate zone (Ippo colors)
        case solid(Color) // Single color
    }
    
    init(points: [RoutePoint], colorMode: ColorMode = .effort, lineWidth: CGFloat = 4) {
        self.points = points
        self.colorMode = colorMode
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        Canvas { context, size in
            guard points.count >= 2 else { return }
            
            // Calculate bounds for coordinate transformation
            let coordinates = points.map { $0.coordinate }
            let region = calculateRegion(for: coordinates)
            
            // Draw line segments with appropriate colors
            for i in 0..<(points.count - 1) {
                let start = projectCoordinate(points[i].coordinate, in: size, region: region)
                let end = projectCoordinate(points[i + 1].coordinate, in: size, region: region)
                
                var path = Path()
                path.move(to: start)
                path.addLine(to: end)
                
                let color = colorForSegment(points[i], points[i + 1])
                context.stroke(path, with: .color(color), lineWidth: lineWidth)
            }
        }
    }
    
    private func colorForSegment(_ start: RoutePoint, _ end: RoutePoint) -> Color {
        switch colorMode {
        case .pace:
            // Average pace of segment - faster is greener
            let avgPace = ((start.pace ?? 360) + (end.pace ?? 360)) / 2
            return paceColor(avgPace)
        case .effort:
            return start.effortZone.color
        case .solid(let color):
            return color
        }
    }
    
    private func paceColor(_ pace: Double) -> Color {
        // pace in seconds/km: 240 = very fast (4:00), 480 = slow (8:00)
        let normalized = min(max((pace - 240) / 240, 0), 1)
        // Use Ippo colors: brandPrimary (fast) to danger (slow)
        if normalized < 0.33 {
            return AppColors.brandPrimary
        } else if normalized < 0.66 {
            return AppColors.warning
        } else {
            return AppColors.danger
        }
    }
    
    private func calculateRegion(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude
        
        for coord in coordinates {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.2,
            longitudeDelta: (maxLon - minLon) * 1.2
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
    
    private func projectCoordinate(_ coordinate: CLLocationCoordinate2D, in size: CGSize, region: MKCoordinateRegion) -> CGPoint {
        let x = (coordinate.longitude - (region.center.longitude - region.span.longitudeDelta / 2)) / region.span.longitudeDelta * size.width
        let y = ((region.center.latitude + region.span.latitudeDelta / 2) - coordinate.latitude) / region.span.latitudeDelta * size.height
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Start/End Markers

/// Start and finish markers for route visualization
/// Pattern: Standard map pin styling from all fitness apps
struct StartEndMarkers: View {
    let startCoordinate: CLLocationCoordinate2D
    let endCoordinate: CLLocationCoordinate2D
    let markerSize: MarkerSize
    
    enum MarkerSize {
        case small, medium, large
        
        var size: CGFloat {
            switch self {
            case .small: return AppSpacing.xl // 24
            case .medium: return AppSpacing.xxl // 32
            case .large: return 44 // Touch target minimum
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 14
            case .large: return 18
            }
        }
    }
    
    init(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D, size: MarkerSize = .medium) {
        self.startCoordinate = start
        self.endCoordinate = end
        self.markerSize = size
    }
    
    var body: some View {
        // This is meant to be used as Annotations in Map
        EmptyView()
    }
    
    /// Start marker view - uses Ippo's success color
    static func startMarker(size: MarkerSize = .medium) -> some View {
        ZStack {
            Circle()
                .fill(AppColors.success)
                .frame(width: size.size, height: size.size)
            
            Circle()
                .stroke(AppColors.textPrimary, lineWidth: 3)
                .frame(width: size.size, height: size.size)
            
            Image(systemName: "figure.run")
                .font(.system(size: size.fontSize, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
        }
        .shadow(color: AppColors.success.opacity(0.5), radius: 4, x: 0, y: 2)
    }
    
    /// End marker view (finish flag) - uses Ippo's brand primary (cyan)
    static func endMarker(size: MarkerSize = .medium) -> some View {
        ZStack {
            Circle()
                .fill(AppColors.brandPrimary)
                .frame(width: size.size, height: size.size)
            
            Circle()
                .stroke(AppColors.textPrimary, lineWidth: 3)
                .frame(width: size.size, height: size.size)
            
            Image(systemName: "flag.checkered")
                .font(.system(size: size.fontSize, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
        }
        .shadow(color: AppColors.brandPrimary.opacity(0.5), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Split Markers

/// Kilometer/mile markers along the route with EP display
/// Pattern: Nike Run Club split indicators + Ippo EP integration
struct SplitMarker: View {
    let split: RouteSplit
    let showPace: Bool
    let showEP: Bool
    
    init(split: RouteSplit, showPace: Bool = true, showEP: Bool = true) {
        self.split = split
        self.showPace = showPace
        self.showEP = showEP
    }
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        var parts: [String] = []
        let unit = split.isKilometer ? "kilometer" : "mile"
        parts.append("\(unit) \(split.splitNumber)")
        if showPace {
            parts.append("pace \(split.pace)")
        }
        if showEP, let ep = split.effortPoints {
            parts.append("plus \(ep) Effort Points")
        }
        return parts.joined(separator: ", ")
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.xxxs) {
            // Split number bubble
            ZStack {
                Circle()
                    .fill(AppColors.surface)
                    .frame(width: 28, height: 28)
                
                Circle()
                    .stroke(AppColors.brandPrimary, lineWidth: 2)
                    .frame(width: 28, height: 28)
                
                Text("\(split.splitNumber)")
                    .font(AppTypography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.brandPrimary)
            }
            
            // Pace label (optional)
            if showPace {
                Text(split.pace)
                    .font(AppTypography.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.horizontal, AppSpacing.xs)
                    .padding(.vertical, AppSpacing.xxxs)
                    .background(AppColors.surface.opacity(0.95))
                    .cornerRadius(AppSpacing.radiusXs)
            }
            
            // EP earned (Ippo-specific)
            if showEP, let ep = split.effortPoints {
                HStack(spacing: AppSpacing.xxxs) {
                    Image(systemName: "bolt.heart.fill")
                        .font(.system(size: 8))
                        .accessibilityHidden(true)
                    Text("+\(ep)")
                        .font(AppTypography.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundColor(AppColors.brandPrimary)
                .padding(.horizontal, AppSpacing.xs)
                .padding(.vertical, AppSpacing.xxxs)
                .background(AppColors.brandPrimary.opacity(0.15))
                .cornerRadius(AppSpacing.radiusXs)
            }
        }
        .shadow(color: AppColors.background.opacity(0.3), radius: 2, x: 0, y: 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Split marker")
        .accessibilityValue(accessibilityDescription)
    }
}

// MARK: - Live Running Map

/// Real-time map view during an active run
/// Pattern: Nike Run Club live run display, Strava live tracking
struct LiveRunningMap: View {
    @Binding var currentLocation: CLLocationCoordinate2D?
    let routePoints: [RoutePoint]
    let isTracking: Bool
    let showStats: Bool
    let totalEP: Int // Current Effort Points earned
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    init(
        currentLocation: Binding<CLLocationCoordinate2D?>,
        routePoints: [RoutePoint],
        isTracking: Bool = true,
        showStats: Bool = true,
        totalEP: Int = 0
    ) {
        self._currentLocation = currentLocation
        self.routePoints = routePoints
        self.isTracking = isTracking
        self.showStats = showStats
        self.totalEP = totalEP
    }
    
    var body: some View {
        ZStack {
            // Map with route
            Map(position: $cameraPosition) {
                // Route polyline with effort colors
                if routePoints.count >= 2 {
                    MapPolyline(coordinates: routePoints.map { $0.coordinate })
                        .stroke(AppColors.brandPrimary, lineWidth: 4)
                }
                
                // Start marker
                if let first = routePoints.first {
                    Annotation("Start", coordinate: first.coordinate) {
                        StartEndMarkers.startMarker(size: .small)
                    }
                }
                
                // Current location (pulsing)
                if let current = currentLocation {
                    Annotation("You", coordinate: current) {
                        IppoCurrentLocationMarker()
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat))
            .mapControls {
                MapCompass()
            }
            
            // Live stats overlay (optional)
            if showStats && isTracking {
                VStack {
                    Spacer()
                    
                    IppoLiveStatsBar(
                        distance: totalDistance,
                        duration: totalDuration,
                        currentPace: currentPace,
                        effortPoints: totalEP
                    )
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.sm)
                }
            }
        }
        .onChange(of: currentLocation) { _, newLocation in
            if isTracking, let location = newLocation {
                withAnimation(.easeInOut(duration: 0.5)) {
                    cameraPosition = .camera(MapCamera(
                        centerCoordinate: location,
                        distance: 500,
                        heading: 0,
                        pitch: 0
                    ))
                }
            }
        }
    }
    
    private var totalDistance: Double {
        routePoints.last?.distanceFromStart ?? 0
    }
    
    private var totalDuration: TimeInterval {
        guard let first = routePoints.first?.timestamp,
              let last = routePoints.last?.timestamp else { return 0 }
        return last.timeIntervalSince(first)
    }
    
    private var currentPace: Double? {
        routePoints.last?.pace
    }
}

/// Pulsing current location marker - Ippo branded
struct IppoCurrentLocationMarker: View {
    @State private var isPulsing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        ZStack {
            // Pulse ring - Ippo cyan (only if motion allowed)
            if !reduceMotion {
                Circle()
                    .stroke(AppColors.brandPrimary.opacity(0.3), lineWidth: 2)
                    .frame(width: isPulsing ? 44 : 24, height: isPulsing ? 44 : 24)
                    .opacity(isPulsing ? 0 : 0.8)
            }
            
            // Outer ring
            Circle()
                .fill(AppColors.surface)
                .frame(width: 24, height: 24)
            
            // Inner dot - Ippo cyan
            Circle()
                .fill(AppColors.brandPrimary)
                .frame(width: 18, height: 18)
            
            // Direction indicator
            Image(systemName: "location.north.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
        }
        .shadow(color: AppColors.brandPrimary.opacity(0.4), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Current location")
        .accessibilityValue("Your position on the map")
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

/// Live stats bar overlay for running map - Ippo styled with EP display
struct IppoLiveStatsBar: View {
    let distance: Double // meters
    let duration: TimeInterval
    let currentPace: Double? // seconds per km
    let effortPoints: Int // Current EP earned
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        var parts: [String] = []
        parts.append("\(formattedDistance) kilometers")
        parts.append("time \(formattedDuration)")
        parts.append("pace \(formattedPace) per kilometer")
        parts.append("\(effortPoints) Effort Points")
        return parts.joined(separator: ", ")
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.lg) {
            // Distance
            VStack(spacing: AppSpacing.xxxs) {
                Text(formattedDistance)
                    .font(AppTypography.statNumber)
                Text("km")
                    .font(AppTypography.caption2)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // Duration
            VStack(spacing: AppSpacing.xxxs) {
                Text(formattedDuration)
                    .font(AppTypography.statNumber)
                Text("time")
                    .font(AppTypography.caption2)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // Pace
            VStack(spacing: AppSpacing.xxxs) {
                Text(formattedPace)
                    .font(AppTypography.statNumber)
                Text("/km")
                    .font(AppTypography.caption2)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // EP - Ippo's core metric
            VStack(spacing: AppSpacing.xxxs) {
                HStack(spacing: AppSpacing.xxxs) {
                    Image(systemName: "bolt.heart.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.brandPrimary)
                        .accessibilityHidden(true)
                    Text("\(effortPoints)")
                        .font(AppTypography.statNumber)
                        .foregroundColor(AppColors.brandPrimary)
                }
                Text("EP")
                    .font(AppTypography.caption2)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.vertical, AppSpacing.md)
        .background(.ultraThinMaterial)
        .cornerRadius(AppSpacing.radiusMd)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Live run stats")
        .accessibilityValue(accessibilityDescription)
    }
    
    private var formattedDistance: String {
        String(format: "%.2f", distance / 1000)
    }
    
    private var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var formattedPace: String {
        guard let pace = currentPace else { return "--:--" }
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Route Preview Card

/// Compact route preview for history/feed views with EP summary
/// Pattern: Strava activity feed card with route thumbnail
struct RoutePreviewCard: View {
    let routePoints: [RoutePoint]
    let title: String
    let date: String
    let distance: String
    let duration: String
    let effortPoints: Int? // Total EP earned
    let onTap: () -> Void
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        var parts: [String] = []
        parts.append(title)
        parts.append(date)
        parts.append(distance)
        parts.append(duration)
        if let ep = effortPoints {
            parts.append("\(ep) Effort Points")
        }
        return parts.joined(separator: ", ")
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Route thumbnail
                ZStack {
                    // Route visualization
                    RouteGradientPolyline(
                        points: routePoints,
                        colorMode: .solid(AppColors.brandPrimary),
                        lineWidth: 3
                    )
                    .frame(height: 120)
                    .background(AppColors.surface)
                    .accessibilityHidden(true)
                    
                    // Gradient overlay at bottom
                    VStack {
                        Spacer()
                        LinearGradient(
                            colors: [.clear, AppColors.background.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 40)
                    }
                    .accessibilityHidden(true)
                    
                    // EP badge in corner
                    if let ep = effortPoints {
                        VStack {
                            HStack {
                                Spacer()
                                HStack(spacing: AppSpacing.xxxs) {
                                    Image(systemName: "bolt.heart.fill")
                                        .font(.system(size: 12))
                                        .accessibilityHidden(true)
                                    Text("\(ep)")
                                        .font(AppTypography.caption)
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal, AppSpacing.sm)
                                .padding(.vertical, AppSpacing.xs)
                                .background(AppColors.brandPrimary)
                                .cornerRadius(AppSpacing.radiusSm)
                                .padding(AppSpacing.sm)
                            }
                            Spacer()
                        }
                    }
                }
                .clipped()
                
                // Info section
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(title)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(date)
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    
                    HStack(spacing: AppSpacing.md) {
                        Label(distance, systemImage: "arrow.left.and.right")
                        Label(duration, systemImage: "clock")
                    }
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                }
                .padding(AppSpacing.md)
            }
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.radiusMd)
            .shadow(color: AppColors.background.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Run activity")
        .accessibilityValue(accessibilityDescription)
        .accessibilityHint("Double tap to view run details")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Elevation Profile

/// Mini elevation chart showing elevation changes along route
/// Pattern: AllTrails elevation profiles, Strava segment elevation
struct ElevationProfile: View {
    let points: [RoutePoint]
    let height: CGFloat
    let showLabels: Bool
    let highlightGain: Bool
    
    init(points: [RoutePoint], height: CGFloat = 60, showLabels: Bool = true, highlightGain: Bool = true) {
        self.points = points
        self.height = height
        self.showLabels = showLabels
        self.highlightGain = highlightGain
    }
    
    private var elevations: [Double] {
        points.compactMap { $0.elevation }
    }
    
    private var minElevation: Double {
        elevations.min() ?? 0
    }
    
    private var maxElevation: Double {
        elevations.max() ?? 100
    }
    
    private var elevationGain: Double {
        var gain: Double = 0
        for i in 1..<elevations.count {
            let diff = elevations[i] - elevations[i-1]
            if diff > 0 { gain += diff }
        }
        return gain
    }
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        let gainStr = String(format: "%.0f", elevationGain)
        let minStr = String(format: "%.0f", minElevation)
        let maxStr = String(format: "%.0f", maxElevation)
        return "Elevation gain \(gainStr) meters, range from \(minStr) to \(maxStr) meters"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            // Labels
            if showLabels {
                HStack {
                    Text("Elevation")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    if highlightGain {
                        Label(String(format: "+%.0fm", elevationGain), systemImage: "arrow.up.right")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.success)
                    }
                }
            }
            
            // Chart
            GeometryReader { geometry in
                let width = geometry.size.width
                let chartHeight = geometry.size.height
                let range = maxElevation - minElevation
                let normalizedRange = range == 0 ? 1 : range
                
                ZStack {
                    // Fill area - using Ippo success color (green)
                    Path { path in
                        guard elevations.count >= 2 else { return }
                        
                        let stepX = width / CGFloat(elevations.count - 1)
                        
                        path.move(to: CGPoint(x: 0, y: chartHeight))
                        
                        for (index, elevation) in elevations.enumerated() {
                            let x = CGFloat(index) * stepX
                            let normalizedY = (elevation - minElevation) / normalizedRange
                            let y = chartHeight - (normalizedY * chartHeight)
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        
                        path.addLine(to: CGPoint(x: width, y: chartHeight))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [AppColors.success.opacity(0.3), AppColors.success.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Line
                    Path { path in
                        guard elevations.count >= 2 else { return }
                        
                        let stepX = width / CGFloat(elevations.count - 1)
                        
                        for (index, elevation) in elevations.enumerated() {
                            let x = CGFloat(index) * stepX
                            let normalizedY = (elevation - minElevation) / normalizedRange
                            let y = chartHeight - (normalizedY * chartHeight)
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(AppColors.success, lineWidth: 2)
                }
                .accessibilityHidden(true)
            }
            .frame(height: height)
            
            // Min/Max labels
            if showLabels {
                HStack {
                    Text(String(format: "%.0fm", minElevation))
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.textTertiary)
                    
                    Spacer()
                    
                    Text(String(format: "%.0fm", maxElevation))
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Elevation profile")
        .accessibilityValue(accessibilityDescription)
    }
}

// MARK: - EP Zone Distribution (Ippo-specific)

/// Shows EP earned in each effort zone during a run
/// Ippo-specific component for post-run analysis
struct EPZoneDistribution: View {
    let zoneEP: [IppoEffortZone: Int] // EP earned per zone
    let totalEP: Int
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        var parts: [String] = ["\(totalEP) total Effort Points"]
        for zone in IppoEffortZone.allCases {
            let ep = zoneEP[zone] ?? 0
            if ep > 0 {
                let percent = totalEP > 0 ? Int(Double(ep) / Double(totalEP) * 100) : 0
                parts.append("\(zone.label): \(ep) points, \(percent) percent")
            }
        }
        return parts.joined(separator: ", ")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            HStack {
                Text("EP by Zone")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
                
                HStack(spacing: AppSpacing.xxxs) {
                    Image(systemName: "bolt.heart.fill")
                        .font(.system(size: 14))
                        .accessibilityHidden(true)
                    Text("\(totalEP)")
                        .font(AppTypography.headline)
                }
                .foregroundColor(AppColors.brandPrimary)
            }
            
            // Zone bars
            ForEach(IppoEffortZone.allCases, id: \.rawValue) { zone in
                let ep = zoneEP[zone] ?? 0
                let progress = totalEP > 0 ? Double(ep) / Double(totalEP) : 0
                
                HStack(spacing: AppSpacing.sm) {
                    // Zone icon and label
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: zone.icon)
                            .font(.system(size: 12))
                            .foregroundColor(zone.color)
                            .frame(width: 20)
                            .accessibilityHidden(true)
                        
                        Text(zone.label)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .frame(width: 60, alignment: .leading)
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: AppSpacing.radiusXs)
                                .fill(AppColors.surface)
                            
                            RoundedRectangle(cornerRadius: AppSpacing.radiusXs)
                                .fill(zone.color)
                                .frame(width: geometry.size.width * progress)
                        }
                    }
                    .frame(height: 8)
                    .accessibilityHidden(true)
                    
                    // EP value
                    Text("+\(ep)")
                        .font(AppTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(zone.color)
                        .frame(width: 40, alignment: .trailing)
                }
            }
            
            // Multiplier info
            HStack {
                Text("Higher zones = more EP")
                    .font(AppTypography.caption2)
                    .foregroundColor(AppColors.textTertiary)
                
                Spacer()
                
                Text("Max Zone: 3x multiplier")
                    .font(AppTypography.caption2)
                    .foregroundColor(AppColors.danger)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.radiusMd)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Effort Points by zone")
        .accessibilityValue(accessibilityDescription)
    }
}

// MARK: - Complete Route Map View

/// Full route map view for post-run detail
/// Pattern: Strava activity detail, Nike Run Club run summary
struct RouteMapView: View {
    let routePoints: [RoutePoint]
    let splits: [RouteSplit]
    let showElevation: Bool
    let showEPDistribution: Bool
    let colorMode: RouteGradientPolyline.ColorMode
    let totalEP: Int
    let zoneEP: [IppoEffortZone: Int]
    
    @State private var selectedSplit: RouteSplit?
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    init(
        routePoints: [RoutePoint],
        splits: [RouteSplit] = [],
        showElevation: Bool = true,
        showEPDistribution: Bool = true,
        colorMode: RouteGradientPolyline.ColorMode = .effort,
        totalEP: Int = 0,
        zoneEP: [IppoEffortZone: Int] = [:]
    ) {
        self.routePoints = routePoints
        self.splits = splits
        self.showElevation = showElevation
        self.showEPDistribution = showEPDistribution
        self.colorMode = colorMode
        self.totalEP = totalEP
        self.zoneEP = zoneEP
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Map
            ZStack {
                Map(position: $cameraPosition) {
                    // Route line
                    if routePoints.count >= 2 {
                        MapPolyline(coordinates: routePoints.map { $0.coordinate })
                            .stroke(
                                effortGradient,
                                style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                            )
                    }
                    
                    // Start marker
                    if let first = routePoints.first {
                        Annotation("Start", coordinate: first.coordinate) {
                            StartEndMarkers.startMarker(size: .medium)
                        }
                    }
                    
                    // End marker
                    if let last = routePoints.last, routePoints.count > 1 {
                        Annotation("Finish", coordinate: last.coordinate) {
                            StartEndMarkers.endMarker(size: .medium)
                        }
                    }
                    
                    // Split markers
                    ForEach(splits) { split in
                        Annotation("Split \(split.splitNumber)", coordinate: split.coordinate) {
                            SplitMarker(split: split)
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls {
                    MapCompass()
                    MapScaleView()
                }
                
                // Color legend
                VStack {
                    HStack {
                        Spacer()
                        IppoEffortColorLegend()
                            .padding(AppSpacing.sm)
                    }
                    Spacer()
                }
            }
            .frame(height: 300)
            
            // Elevation profile
            if showElevation && routePoints.contains(where: { $0.elevation != nil }) {
                ElevationProfile(points: routePoints)
                    .padding(AppSpacing.md)
                    .background(AppColors.background)
            }
            
            // EP Zone Distribution (Ippo-specific)
            if showEPDistribution && totalEP > 0 {
                EPZoneDistribution(zoneEP: zoneEP, totalEP: totalEP)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.md)
            }
        }
        .onAppear {
            fitRouteInView()
        }
    }
    
    private var effortGradient: LinearGradient {
        // Using Ippo effort zone colors
        LinearGradient(
            colors: [AppColors.brandPrimary, AppColors.success, AppColors.warning, AppColors.danger],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private func fitRouteInView() {
        guard routePoints.count >= 2 else { return }
        
        let coordinates = routePoints.map { $0.coordinate }
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude
        
        for coord in coordinates {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        // Calculate appropriate distance based on route bounds
        let latDelta = (maxLat - minLat) * 111000 // rough meters per degree
        let lonDelta = (maxLon - minLon) * 111000 * cos(center.latitude * .pi / 180)
        let maxDelta = max(latDelta, lonDelta)
        let distance = max(maxDelta * 1.5, 500) // minimum 500m view
        
        cameraPosition = .camera(MapCamera(
            centerCoordinate: center,
            distance: distance,
            heading: 0,
            pitch: 0
        ))
    }
}

/// Compact effort color legend - Ippo styled
struct IppoEffortColorLegend: View {
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        let zones = IppoEffortZone.allCases.filter { $0 != .recovery }.map { $0.label }
        return "Effort zones: \(zones.joined(separator: ", "))"
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(IppoEffortZone.allCases.filter { $0 != .recovery }, id: \.rawValue) { zone in
                HStack(spacing: AppSpacing.xxxs) {
                    Circle()
                        .fill(zone.color)
                        .frame(width: 8, height: 8)
                        .accessibilityHidden(true)
                    Text(zone.label)
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(.ultraThinMaterial)
        .cornerRadius(AppSpacing.radiusSm)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Effort zone legend")
        .accessibilityValue(accessibilityDescription)
    }
}

// MARK: - Route Comparison View

/// Compare two routes side by side
/// Pattern: Strava segment comparison
struct RouteComparisonView: View {
    let currentRoute: [RoutePoint]
    let previousRoute: [RoutePoint]
    let currentLabel: String
    let previousLabel: String
    let currentEP: Int
    let previousEP: Int
    
    var epImprovement: Int {
        currentEP - previousEP
    }
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        var result = "\(currentLabel): \(currentEP) Effort Points. \(previousLabel): \(previousEP) Effort Points."
        if epImprovement > 0 {
            result += " Improved by \(epImprovement) points."
        } else if epImprovement < 0 {
            result += " Down \(abs(epImprovement)) points from previous."
        } else {
            result += " Same as previous."
        }
        return result
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(currentLabel)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    HStack(spacing: AppSpacing.xxxs) {
                        Image(systemName: "bolt.heart.fill")
                            .font(.system(size: 12))
                            .accessibilityHidden(true)
                        Text("\(currentEP) EP")
                            .font(AppTypography.caption)
                    }
                    .foregroundColor(AppColors.brandPrimary)
                }
                
                Spacer()
                
                // EP comparison
                if epImprovement != 0 {
                    HStack(spacing: AppSpacing.xxxs) {
                        Image(systemName: epImprovement > 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 14, weight: .bold))
                            .accessibilityHidden(true)
                        Text("\(abs(epImprovement))")
                            .font(AppTypography.headline)
                    }
                    .foregroundColor(epImprovement > 0 ? AppColors.success : AppColors.danger)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(previousLabel)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textSecondary)
                    HStack(spacing: AppSpacing.xxxs) {
                        Image(systemName: "bolt.heart.fill")
                            .font(.system(size: 12))
                            .accessibilityHidden(true)
                        Text("\(previousEP) EP")
                            .font(AppTypography.caption)
                    }
                    .foregroundColor(AppColors.textTertiary)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            
            // Overlaid routes
            ZStack {
                // Previous route (faded)
                RouteGradientPolyline(
                    points: previousRoute,
                    colorMode: .solid(AppColors.textTertiary.opacity(0.5)),
                    lineWidth: 3
                )
                
                // Current route
                RouteGradientPolyline(
                    points: currentRoute,
                    colorMode: .effort,
                    lineWidth: 4
                )
            }
            .frame(height: 200)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.radiusMd)
            .padding(.horizontal, AppSpacing.md)
            .accessibilityHidden(true)
            
            // Legend
            HStack(spacing: AppSpacing.xl) {
                HStack(spacing: AppSpacing.sm) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppColors.textTertiary.opacity(0.5))
                        .frame(width: 20, height: 4)
                        .accessibilityHidden(true)
                    Text("Previous")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                HStack(spacing: AppSpacing.sm) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppColors.brandPrimary)
                        .frame(width: 20, height: 4)
                        .accessibilityHidden(true)
                    Text("Current")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Route comparison")
        .accessibilityValue(accessibilityDescription)
    }
}

// MARK: - Mini Route Widget

/// Compact route thumbnail for home screen or widgets
/// Ippo-specific: Shows total EP prominently
struct MiniRouteWidget: View {
    let routePoints: [RoutePoint]
    let effortPoints: Int
    let distance: String
    let onTap: () -> Void
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        "\(effortPoints) Effort Points, \(distance)"
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppSpacing.sm) {
                // Mini route preview
                RouteGradientPolyline(
                    points: routePoints,
                    colorMode: .effort,
                    lineWidth: 2
                )
                .frame(height: 80)
                .background(AppColors.surface)
                .cornerRadius(AppSpacing.radiusSm)
                .accessibilityHidden(true)
                
                // Stats
                HStack {
                    // EP badge
                    HStack(spacing: AppSpacing.xxxs) {
                        Image(systemName: "bolt.heart.fill")
                            .font(.system(size: 12))
                            .accessibilityHidden(true)
                        Text("\(effortPoints)")
                            .font(AppTypography.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(AppColors.brandPrimary)
                    
                    Spacer()
                    
                    // Distance
                    Text(distance)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(AppSpacing.sm)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.radiusMd)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Run summary")
        .accessibilityValue(accessibilityDescription)
        .accessibilityHint("Double tap to view details")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Previews

#Preview("Route Map View") {
    let samplePoints = generateSampleRoute()
    let sampleSplits = [
        RouteSplit(coordinate: CLLocationCoordinate2D(latitude: 37.7855, longitude: -122.4064), splitNumber: 1, pace: "5:45", effortPoints: 42, isKilometer: true),
        RouteSplit(coordinate: CLLocationCoordinate2D(latitude: 37.7880, longitude: -122.4090), splitNumber: 2, pace: "5:52", effortPoints: 38, isKilometer: true)
    ]
    
    return RouteMapView(
        routePoints: samplePoints,
        splits: sampleSplits,
        showElevation: true,
        showEPDistribution: true,
        colorMode: .effort,
        totalEP: 245,
        zoneEP: [
            .recovery: 10,
            .easy: 45,
            .moderate: 80,
            .hard: 75,
            .max: 35
        ]
    )
}

#Preview("Route Preview Card") {
    RoutePreviewCard(
        routePoints: generateSampleRoute(),
        title: "Morning Run",
        date: "Feb 5, 2026 • 7:30 AM",
        distance: "5.02 km",
        duration: "32:14",
        effortPoints: 245
    ) {
        print("Tapped")
    }
    .padding()
}

#Preview("Elevation Profile") {
    ElevationProfile(
        points: generateSampleRoute(),
        height: 80,
        showLabels: true,
        highlightGain: true
    )
    .padding()
}

#Preview("EP Zone Distribution") {
    EPZoneDistribution(
        zoneEP: [
            .recovery: 10,
            .easy: 45,
            .moderate: 80,
            .hard: 75,
            .max: 35
        ],
        totalEP: 245
    )
    .padding()
}

#Preview("Split Marker with EP") {
    SplitMarker(
        split: RouteSplit(
            coordinate: CLLocationCoordinate2D(latitude: 37.785, longitude: -122.406),
            splitNumber: 3,
            pace: "5:48",
            effortPoints: 42,
            isKilometer: true
        ),
        showPace: true,
        showEP: true
    )
    .padding()
}

#Preview("Start/End Markers") {
    HStack(spacing: 32) {
        StartEndMarkers.startMarker(size: .small)
        StartEndMarkers.startMarker(size: .medium)
        StartEndMarkers.startMarker(size: .large)
        
        StartEndMarkers.endMarker(size: .small)
        StartEndMarkers.endMarker(size: .medium)
        StartEndMarkers.endMarker(size: .large)
    }
    .padding()
}

#Preview("Current Location Marker") {
    IppoCurrentLocationMarker()
        .padding()
}

#Preview("Live Stats Bar with EP") {
    IppoLiveStatsBar(
        distance: 3450,
        duration: 1234,
        currentPace: 348,
        effortPoints: 156
    )
    .padding()
}

#Preview("Effort Color Legend") {
    IppoEffortColorLegend()
        .padding()
}

#Preview("Route Comparison") {
    RouteComparisonView(
        currentRoute: generateSampleRoute(),
        previousRoute: generateSampleRoute(),
        currentLabel: "Today",
        previousLabel: "Last Week",
        currentEP: 245,
        previousEP: 198
    )
    .padding()
}

#Preview("Mini Route Widget") {
    MiniRouteWidget(
        routePoints: generateSampleRoute(),
        effortPoints: 245,
        distance: "5.02 km"
    ) {
        print("Tapped")
    }
    .frame(width: 150)
    .padding()
}

// Helper function to generate sample route
private func generateSampleRoute() -> [RoutePoint] {
    let baseCoord = CLLocationCoordinate2D(latitude: 37.785, longitude: -122.406)
    var points: [RoutePoint] = []
    var distance: Double = 0
    var elevation: Double = 50
    
    for i in 0..<50 {
        let progress = Double(i) / 50.0
        let coord = CLLocationCoordinate2D(
            latitude: baseCoord.latitude + progress * 0.01 + Double.random(in: -0.001...0.001),
            longitude: baseCoord.longitude + progress * 0.008 + Double.random(in: -0.001...0.001)
        )
        
        // Simulate elevation changes
        elevation += Double.random(in: -3...5)
        elevation = max(20, min(150, elevation))
        
        // Simulate varying effort
        let heartRate = 120 + Int(progress * 50) + Int.random(in: -10...10)
        let pace = 300 + Double.random(in: -30...60)
        
        distance += Double.random(in: 80...120)
        
        // Calculate EP based on effort zone
        let zone = heartRateToZone(heartRate)
        let ep = Int(Double.random(in: 3...8) * zone.epMultiplier)
        
        points.append(RoutePoint(
            coordinate: coord,
            timestamp: Date().addingTimeInterval(TimeInterval(i * 30)),
            pace: pace,
            heartRate: heartRate,
            elevation: elevation,
            distanceFromStart: distance,
            effortPoints: ep
        ))
    }
    
    return points
}

private func heartRateToZone(_ hr: Int) -> IppoEffortZone {
    switch hr {
    case 0..<110: return .recovery
    case 110..<130: return .easy
    case 130..<150: return .moderate
    case 150..<170: return .hard
    case 170...: return .max
    default: return .recovery
    }
}
