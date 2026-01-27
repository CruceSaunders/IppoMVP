import Foundation
import WatchConnectivity
import Combine

// MARK: - Message Types (must match iOS side)
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

struct RunSummaryPayload: Codable {
    let durationSeconds: Int
    let distanceMeters: Double
    let sprintsCompleted: Int
    let sprintsTotal: Int
    let rpEarned: Int
    let xpEarned: Int
    let coinsEarned: Int
    let petCaught: String?
    let lootBoxesEarned: [String]
}

@MainActor
final class WatchConnectivityServiceWatch: NSObject, ObservableObject {
    static let shared = WatchConnectivityServiceWatch()
    
    @Published var equippedPetName: String?
    @Published var equippedPetEmoji: String = "🐾"
    @Published var isConnected: Bool = false
    
    private var session: WCSession?
    private var pendingMessages: [WatchMessage] = []
    
    override init() {
        super.init()
        
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    // MARK: - Send Message (properly formatted)
    private func send(_ message: WatchMessage, replyHandler: (([String: Any]) -> Void)? = nil) {
        guard let session = session, session.isReachable else {
            print("📱 WATCH CONN: Not reachable, queueing message type: \(message.type)")
            pendingMessages.append(message)
            return
        }
        
        do {
            let data = try JSONEncoder().encode(message)
            let dict: [String: Any] = ["message": data]
            
            print("📱 WATCH CONN: Sending message type: \(message.type)")
            
            if let handler = replyHandler {
                session.sendMessage(dict, replyHandler: handler, errorHandler: { error in
                    print("❌ WATCH CONN: Message failed: \(error)")
                })
            } else {
                session.sendMessage(dict, replyHandler: nil, errorHandler: { error in
                    print("❌ WATCH CONN: Message failed: \(error)")
                })
            }
        } catch {
            print("❌ WATCH CONN: Failed to encode message: \(error)")
        }
    }
    
    // MARK: - Send Pending Messages
    private func sendPendingMessages() {
        guard let session = session, session.isReachable else { return }
        
        let messages = pendingMessages
        pendingMessages.removeAll()
        
        print("📱 WATCH CONN: Sending \(messages.count) pending messages")
        
        for message in messages {
            send(message)
        }
    }
    
    // MARK: - Send Run Summary
    func sendRunSummary(_ summary: WatchRunSummary) {
        let payload = RunSummaryPayload(
            durationSeconds: summary.durationSeconds,
            distanceMeters: summary.distanceMeters,
            sprintsCompleted: summary.sprintsCompleted,
            sprintsTotal: summary.sprintsTotal,
            rpEarned: summary.rpEarned,
            xpEarned: summary.xpEarned,
            coinsEarned: summary.coinsEarned,
            petCaught: summary.petCaught,
            lootBoxesEarned: summary.lootBoxesEarned
        )
        
        let payloadData = try? JSONEncoder().encode(payload)
        let message = WatchMessage(type: .runEnded, payload: payloadData)
        
        print("📱 WATCH CONN: Sending run summary - \(summary.sprintsCompleted)/\(summary.sprintsTotal) sprints, \(summary.rpEarned) RP")
        send(message)
    }
    
    // MARK: - Send Pet Caught
    func sendPetCaught(_ petId: String) {
        let payloadData = petId.data(using: .utf8)
        let message = WatchMessage(type: .petCaught, payload: payloadData)
        
        print("📱 WATCH CONN: Sending pet caught: \(petId)")
        send(message)
    }
    
    // MARK: - Request Sync
    func requestSync() {
        let message = WatchMessage(type: .syncRequest, payload: nil)
        
        print("📱 WATCH CONN: Requesting sync from iPhone")
        send(message) { [weak self] response in
            Task { @MainActor in
                // Handle the response - iOS sends back profile data
                if let profileData = response["response"] as? Data {
                    print("📱 WATCH CONN: Received profile data from iPhone")
                    self?.handleProfileData(profileData)
                } else if let petName = response["equippedPetName"] as? String {
                    // Fallback: direct fields
                    print("📱 WATCH CONN: Received direct profile fields")
                    self?.equippedPetName = petName
                    if let emoji = response["equippedPetEmoji"] as? String {
                        self?.equippedPetEmoji = emoji
                    }
                }
            }
        }
    }
    
    // MARK: - Handle Profile Data
    private func handleProfileData(_ data: Data) {
        // Try to decode PlayerProfile from iOS
        // For now, just extract what we need
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let petName = json["equippedPetName"] as? String {
                equippedPetName = petName
            }
            if let emoji = json["equippedPetEmoji"] as? String {
                equippedPetEmoji = emoji
            }
            print("📱 WATCH CONN: Updated profile - pet: \(equippedPetName ?? "none")")
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityServiceWatch: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            isConnected = activationState == .activated
            print("📱 WATCH CONN: Activation complete, connected: \(isConnected)")
            if isConnected {
                sendPendingMessages()
                requestSync()
            }
        }
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isConnected = session.isReachable
            print("📱 WATCH CONN: Reachability changed: \(isConnected)")
            if isConnected {
                sendPendingMessages()
            }
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            print("📱 WATCH CONN: Received message from iPhone")
            
            // Try new format first (WatchMessage wrapped in "message" key)
            if let data = message["message"] as? Data,
               let watchMessage = try? JSONDecoder().decode(WatchMessage.self, from: data) {
                print("📱 WATCH CONN: Decoded WatchMessage type: \(watchMessage.type)")
                handleWatchMessage(watchMessage)
                return
            }
            
            // Fallback: old direct format
            if let type = message["type"] as? String {
                print("📱 WATCH CONN: Received legacy message type: \(type)")
                switch type {
                case "profileUpdate":
                    if let petName = message["equippedPetName"] as? String {
                        equippedPetName = petName
                    }
                    if let emoji = message["equippedPetEmoji"] as? String {
                        equippedPetEmoji = emoji
                    }
                    print("📱 WATCH CONN: Updated profile from legacy message")
                default:
                    break
                }
            }
        }
    }
    
    @MainActor
    private func handleWatchMessage(_ message: WatchMessage) {
        switch message.type {
        case .profileUpdate:
            if let payload = message.payload {
                handleProfileData(payload)
            }
        case .syncResponse:
            if let payload = message.payload {
                handleProfileData(payload)
            }
        default:
            print("📱 WATCH CONN: Unhandled message type: \(message.type)")
        }
    }
}
