import Foundation
import WatchConnectivity
import Combine

// MARK: - Message Types
enum WatchMessageType: String, Codable {
    case runStarted
    case runEnded
    case sprintResult
    case petCaught
    case syncRequest
    case syncResponse
    case profileUpdate
}

struct WatchMessage: Codable {
    let type: WatchMessageType
    let payload: Data?
    let timestamp: Date
    
    init(type: WatchMessageType, payload: Data? = nil) {
        self.type = type
        self.payload = payload
        self.timestamp = Date()
    }
}

// MARK: - Run Summary (from Watch)
struct RunSummaryPayload: Codable {
    let durationSeconds: Int
    let distanceMeters: Double
    let sprintsCompleted: Int
    let sprintsTotal: Int
    let rpEarned: Int
    let xpEarned: Int
    let coinsEarned: Int
    let petCaught: String?
    let lootBoxesEarned: [String]  // Rarity raw values
}

// MARK: - Watch Connectivity Service
@MainActor
final class WatchConnectivityService: NSObject, ObservableObject {
    static let shared = WatchConnectivityService()
    
    @Published var isReachable: Bool = false
    @Published var lastSyncDate: Date?
    @Published var pendingMessages: [WatchMessage] = []
    
    private var session: WCSession?
    
    override init() {
        super.init()
        
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    // MARK: - Send Message
    func send(_ message: WatchMessage, replyHandler: ((Data?) -> Void)? = nil) {
        guard let session = session, session.isReachable else {
            // Queue for later
            print("⌚️ iOS CONN: Not reachable, queueing message type: \(message.type)")
            pendingMessages.append(message)
            return
        }
        
        do {
            let data = try JSONEncoder().encode(message)
            let dict: [String: Any] = ["message": data]
            
            print("⌚️ iOS CONN: Sending message type: \(message.type)")
            
            if let handler = replyHandler {
                session.sendMessage(dict, replyHandler: { reply in
                    if let replyData = reply["response"] as? Data {
                        handler(replyData)
                    }
                }, errorHandler: { error in
                    print("❌ iOS CONN: Watch message failed: \(error)")
                })
            } else {
                session.sendMessage(dict, replyHandler: nil, errorHandler: { error in
                    print("❌ iOS CONN: Watch message failed: \(error)")
                })
            }
        } catch {
            print("❌ iOS CONN: Failed to encode message: \(error)")
        }
    }
    
    // MARK: - Send Queued Messages
    func sendPendingMessages() {
        guard let session = session, session.isReachable else { return }
        
        let messages = pendingMessages
        pendingMessages.removeAll()
        
        print("⌚️ iOS CONN: Sending \(messages.count) pending messages")
        
        for message in messages {
            send(message)
        }
    }
    
    // MARK: - Sync Profile to Watch
    func syncProfileToWatch() {
        Task { @MainActor in
            let userData = UserData.shared
            
            // Create a simple dictionary that Watch can parse
            let profileDict: [String: Any] = [
                "equippedPetName": userData.profile.equippedPetId ?? "",
                "equippedPetEmoji": "🐾",  // TODO: Get actual emoji from pet config
                "level": userData.profile.level,
                "xp": userData.profile.xp,
                "coins": userData.coins,
                "rp": userData.profile.rp
            ]
            
            let profileData = try? JSONSerialization.data(withJSONObject: profileDict)
            let message = WatchMessage(type: .profileUpdate, payload: profileData)
            
            print("⌚️ iOS CONN: Syncing profile to Watch - level \(userData.profile.level)")
            send(message)
        }
    }
    
    // MARK: - Handle Incoming Run Summary
    private func handleRunSummary(_ data: Data) {
        Task { @MainActor in
            guard let payload = try? JSONDecoder().decode(RunSummaryPayload.self, from: data) else { 
                print("❌ iOS CONN: Failed to decode run summary")
                return 
            }
            
            print("⌚️ iOS CONN: Received run summary:")
            print("   Duration: \(payload.durationSeconds)s")
            print("   Sprints: \(payload.sprintsCompleted)/\(payload.sprintsTotal)")
            print("   Rewards: \(payload.rpEarned) RP, \(payload.xpEarned) XP, \(payload.coinsEarned) coins")
            print("   LootBoxes: \(payload.lootBoxesEarned)")
            print("   Pet: \(payload.petCaught ?? "none")")
            
            // Convert loot boxes
            let lootBoxes = payload.lootBoxesEarned.compactMap { Rarity(rawValue: $0) }
            
            // Create run record
            let run = CompletedRun(
                durationSeconds: payload.durationSeconds,
                distanceMeters: payload.distanceMeters,
                sprintsCompleted: payload.sprintsCompleted,
                sprintsTotal: payload.sprintsTotal,
                rpEarned: payload.rpEarned,
                xpEarned: payload.xpEarned,
                coinsEarned: payload.coinsEarned,
                petCaught: payload.petCaught,
                lootBoxesEarned: lootBoxes
            )
            
            // Apply to user data
            let userData = UserData.shared
            userData.completeRun(run)
            userData.addRP(payload.rpEarned)
            userData.addXP(payload.xpEarned)
            userData.addCoins(payload.coinsEarned)
            
            for rarity in lootBoxes {
                userData.addLootBox(rarity)
            }
            
            // Handle pet catch
            if let petId = payload.petCaught {
                print("⌚️ iOS CONN: Adding caught pet: \(petId)")
                _ = userData.addPet(petId)
            }
            
            print("✅ iOS CONN: Run summary applied to user data")
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            print("⌚️ iOS CONN: Activation complete, state: \(activationState.rawValue)")
            if activationState == .activated {
                isReachable = session.isReachable
                sendPendingMessages()
            }
        }
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isReachable = session.isReachable
            print("⌚️ iOS CONN: Reachability changed: \(isReachable)")
            if isReachable {
                sendPendingMessages()
            }
        }
    }
    
    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        print("⌚️ iOS CONN: Session became inactive")
    }
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        print("⌚️ iOS CONN: Session deactivated, reactivating...")
        session.activate()
    }
    #endif
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            print("⌚️ iOS CONN: Received message from Watch")
            
            guard let data = message["message"] as? Data else { 
                print("❌ iOS CONN: No 'message' data in received message")
                return 
            }
            
            guard let watchMessage = try? JSONDecoder().decode(WatchMessage.self, from: data) else { 
                print("❌ iOS CONN: Failed to decode WatchMessage")
                return 
            }
            
            print("⌚️ iOS CONN: Decoded message type: \(watchMessage.type)")
            
            switch watchMessage.type {
            case .runEnded:
                if let payload = watchMessage.payload {
                    handleRunSummary(payload)
                }
            case .petCaught:
                if let payload = watchMessage.payload,
                   let petId = String(data: payload, encoding: .utf8) {
                    print("⌚️ iOS CONN: Pet caught notification: \(petId)")
                    _ = UserData.shared.addPet(petId)
                }
            case .syncRequest:
                print("⌚️ iOS CONN: Sync request received, sending profile")
                syncProfileToWatch()
            default:
                print("⌚️ iOS CONN: Unhandled message type: \(watchMessage.type)")
            }
            
            lastSyncDate = Date()
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        // Handle messages that expect a reply
        Task { @MainActor in
            print("⌚️ iOS CONN: Received message with reply handler")
            
            guard let data = message["message"] as? Data,
                  let watchMessage = try? JSONDecoder().decode(WatchMessage.self, from: data) else {
                print("❌ iOS CONN: Failed to decode message, sending empty reply")
                replyHandler([:])
                return
            }
            
            print("⌚️ iOS CONN: Message type: \(watchMessage.type)")
            
            switch watchMessage.type {
            case .syncRequest:
                // Send back user profile as simple dictionary
                let userData = UserData.shared
                let profileDict: [String: Any] = [
                    "equippedPetName": userData.profile.equippedPetId ?? "",
                    "equippedPetEmoji": "🐾",
                    "level": userData.profile.level,
                    "xp": userData.profile.xp,
                    "coins": userData.coins,
                    "rp": userData.profile.rp
                ]
                
                if let profileData = try? JSONSerialization.data(withJSONObject: profileDict) {
                    print("⌚️ iOS CONN: Sending profile in reply")
                    replyHandler(["response": profileData])
                } else {
                    replyHandler([:])
                }
            default:
                replyHandler([:])
            }
        }
    }
}
