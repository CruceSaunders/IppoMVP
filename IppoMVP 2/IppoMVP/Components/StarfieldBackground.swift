import SwiftUI

/// Animated starfield background for the ability tree view
struct StarfieldBackground: View {
    @State private var stars: [Star] = []
    @State private var phase: CGFloat = 0
    
    private let starCount = 100
    private let gradientColors: [Color] = [
        Color(red: 0.05, green: 0.02, blue: 0.15), // Deep purple
        Color(red: 0.02, green: 0.05, blue: 0.20)  // Deep blue
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Stars layer
                Canvas { context, size in
                    for star in stars {
                        let twinkle = sin(phase + star.twinkleOffset) * 0.3 + 0.7
                        let opacity = star.baseOpacity * twinkle
                        
                        context.fill(
                            Circle().path(in: CGRect(
                                x: star.x * size.width - star.size / 2,
                                y: star.y * size.height - star.size / 2,
                                width: star.size,
                                height: star.size
                            )),
                            with: .color(.white.opacity(opacity))
                        )
                        
                        // Add subtle glow for larger stars
                        if star.size > 2 {
                            context.fill(
                                Circle().path(in: CGRect(
                                    x: star.x * size.width - star.size,
                                    y: star.y * size.height - star.size,
                                    width: star.size * 2,
                                    height: star.size * 2
                                )),
                                with: .color(.white.opacity(opacity * 0.1))
                            )
                        }
                    }
                }
                
                // Subtle nebula effects
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.purple.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: geometry.size.width * 0.4
                        )
                    )
                    .frame(width: geometry.size.width * 0.8)
                    .position(x: geometry.size.width * 0.3, y: geometry.size.height * 0.2)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.blue.opacity(0.03),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: geometry.size.width * 0.5
                        )
                    )
                    .frame(width: geometry.size.width)
                    .position(x: geometry.size.width * 0.7, y: geometry.size.height * 0.7)
            }
        }
        .onAppear {
            generateStars()
            startTwinkling()
        }
    }
    
    private func generateStars() {
        stars = (0..<starCount).map { _ in
            Star(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: 0...1),
                size: CGFloat.random(in: 0.5...3.5),
                baseOpacity: Double.random(in: 0.1...0.5),
                twinkleOffset: CGFloat.random(in: 0...(.pi * 2))
            )
        }
    }
    
    private func startTwinkling() {
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            phase = .pi * 2
        }
    }
}

// MARK: - Star Model

struct Star: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let baseOpacity: Double
    let twinkleOffset: CGFloat
}

// MARK: - Preview

#Preview {
    StarfieldBackground()
        .ignoresSafeArea()
}
