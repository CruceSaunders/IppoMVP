import Foundation

// MARK: - OpenAI Service
class OpenAIService: ObservableObject {
    static let shared = OpenAIService()
    
    // TODO: Replace with your actual API key or load from secure storage
    private var apiKey: String {
        // Try to load from environment or UserDefaults
        if let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            return key
        }
        if let key = UserDefaults.standard.string(forKey: "openai_api_key"), !key.isEmpty {
            return key
        }
        // Fallback - SET YOUR KEY HERE or in Settings
        return "YOUR_OPENAI_API_KEY"
    }
    
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    @Published var isLoading = false
    
    private init() {}
    
    // MARK: - Set API Key
    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "openai_api_key")
    }
    
    func getAPIKey() -> String {
        return UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
    }
    
    // MARK: - Chat Completion
    func sendMessage(
        messages: [ChatMessage],
        taskContext: [TaskItem]? = nil
    ) async throws -> String {
        isLoading = true
        defer { isLoading = false }
        
        guard apiKey != "YOUR_OPENAI_API_KEY" else {
            throw OpenAIError.noAPIKey
        }
        
        var systemPrompt = """
        You are Ippo's AI assistant, helping users manage their fitness journey and daily tasks.
        You can help users:
        - Create new tasks (respond with [CREATE_TASK: title | optional due date | optional recurrence])
        - Mark tasks complete (respond with [COMPLETE_TASK: task_id])
        - List their tasks (respond with [LIST_TASKS])
        - Set recurring tasks (use recurrence: daily, weekly, monthly)
        - Provide motivation and fitness tips
        
        Keep responses concise and encouraging. You're part of a running/fitness app called Ippo.
        
        Task command format examples:
        - [CREATE_TASK: Morning run | tomorrow 7am | daily]
        - [CREATE_TASK: Leg day workout | next Monday | weekly]
        - [COMPLETE_TASK: abc123]
        
        When users ask to create tasks, extract the details and use the command format.
        """
        
        // Add current tasks context
        if let tasks = taskContext, !tasks.isEmpty {
            let taskList = tasks.map { task in
                "- [\(task.isCompleted ? "✓" : " ")] \(task.title) (id: \(task.id.uuidString.prefix(8)))\(task.recurrence != .none ? " [Recurring: \(task.recurrence.rawValue)]" : "")"
            }.joined(separator: "\n")
            systemPrompt += "\n\nUser's current tasks:\n\(taskList)"
        }
        
        var apiMessages: [[String: String]] = [
            ["role": "system", "content": systemPrompt]
        ]
        
        for message in messages {
            apiMessages.append([
                "role": message.isUser ? "user" : "assistant",
                "content": message.content
            ])
        }
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": apiMessages,
            "max_tokens": 500,
            "temperature": 0.7
        ]
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw OpenAIError.apiError(message)
            }
            throw OpenAIError.httpError(httpResponse.statusCode)
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.invalidResponse
        }
        
        return content
    }
}

// MARK: - Chat Message
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    init(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

// MARK: - Errors
enum OpenAIError: LocalizedError {
    case noAPIKey
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No OpenAI API key configured. Go to Settings to add your key."
        case .invalidResponse:
            return "Invalid response from OpenAI"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return message
        }
    }
}
