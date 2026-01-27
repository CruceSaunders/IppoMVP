import Foundation
import WatchKit

@MainActor
final class WatchHapticsManager {
    static let shared = WatchHapticsManager()
    
    private let device = WKInterfaceDevice.current()
    
    private init() {}
    
    // MARK: - Run Lifecycle
    func playRunStart() {
        print("🔔 HAPTIC: playRunStart (.start)")
        device.play(.start)
    }
    
    func playRunEnd() {
        print("🔔 HAPTIC: playRunEnd (.stop)")
        device.play(.stop)
    }
    
    // MARK: - Sprint Signals
    func playSprintStart() {
        print("🔔 HAPTIC: playSprintStart (3x .notification)")
        // 3 strong vibrations
        Task {
            for i in 0..<3 {
                print("🔔 HAPTIC: playSprintStart vibration \(i+1)/3")
                device.play(.notification)
                try? await Task.sleep(nanoseconds: 150_000_000) // 0.15s
            }
        }
    }
    
    func playSprintEnd() {
        print("🔔 HAPTIC: playSprintEnd (3x .notification)")
        // 3 strong vibrations
        Task {
            for i in 0..<3 {
                print("🔔 HAPTIC: playSprintEnd vibration \(i+1)/3")
                device.play(.notification)
                try? await Task.sleep(nanoseconds: 150_000_000)
            }
        }
    }
    
    func playTick() {
        print("🔔 HAPTIC: playTick (.click)")
        device.play(.click)
    }
    
    func playSprintSuccess() {
        print("🔔 HAPTIC: playSprintSuccess (.success)")
        device.play(.success)
    }
    
    func playSprintFail() {
        print("🔔 HAPTIC: playSprintFail (.failure)")
        device.play(.failure)
    }
    
    // MARK: - Pet Catch
    func playPetCatch() {
        print("🔔 HAPTIC: playPetCatch (5x .notification + .success)")
        Task {
            // Dramatic buildup
            for i in 0..<5 {
                print("🔔 HAPTIC: playPetCatch buildup \(i+1)/5")
                device.play(.notification)
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            }
            
            // Big celebration
            try? await Task.sleep(nanoseconds: 200_000_000)
            print("🔔 HAPTIC: playPetCatch celebration (.success)")
            device.play(.success)
        }
    }
    
    // MARK: - General
    func playSuccess() {
        print("🔔 HAPTIC: playSuccess (.success)")
        device.play(.success)
    }
    
    func playFailure() {
        print("🔔 HAPTIC: playFailure (.failure)")
        device.play(.failure)
    }
    
    func playNotification() {
        print("🔔 HAPTIC: playNotification (.notification)")
        device.play(.notification)
    }
}
