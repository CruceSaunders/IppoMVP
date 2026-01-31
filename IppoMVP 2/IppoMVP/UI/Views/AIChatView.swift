import SwiftUI

struct AIChatView: View {
    @StateObject private var openAI = OpenAIService.shared
    @StateObject private var taskManager = TaskManager.shared
    
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var showingTaskSheet = false
    @State private var showingSettings = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Chat Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Welcome message
                            if messages.isEmpty {
                                WelcomeView()
                                    .padding(.top, 40)
                            }
                            
                            ForEach(messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if isLoading {
                                HStack {
                                    TypingIndicator()
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Error banner
                if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                        Text(error)
                            .font(.caption)
                        Spacer()
                        Button("Dismiss") {
                            errorMessage = nil
                        }
                        .font(.caption)
                    }
                    .padding(8)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // Input area
                HStack(spacing: 12) {
                    Button {
                        showingTaskSheet = true
                    } label: {
                        Image(systemName: "checklist")
                            .font(.title2)
                            .foregroundColor(AppColors.brandPrimary)
                    }
                    
                    TextField("Message Ippo AI...", text: $inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .lineLimit(1...5)
                    
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                            .foregroundColor(inputText.isEmpty ? .gray : AppColors.brandPrimary)
                    }
                    .disabled(inputText.isEmpty || isLoading)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingTaskSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "checklist")
                            if !taskManager.pendingTasks.isEmpty {
                                Text("\(taskManager.pendingTasks.count)")
                                    .font(.caption2)
                                    .padding(4)
                                    .background(AppColors.brandPrimary)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingTaskSheet) {
                TaskListView()
            }
            .sheet(isPresented: $showingSettings) {
                AISettingsView()
            }
        }
    }
    
    private func sendMessage() {
        let userMessage = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMessage.isEmpty else { return }
        
        let newMessage = ChatMessage(content: userMessage, isUser: true)
        messages.append(newMessage)
        inputText = ""
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await openAI.sendMessage(
                    messages: messages,
                    taskContext: taskManager.tasks
                )
                
                // Parse AI response for commands
                let parsed = taskManager.parseAIResponse(response)
                
                // Execute any commands
                await executeCommand(parsed.type)
                
                // Add AI response
                let aiMessage = ChatMessage(
                    content: parsed.cleanedResponse.isEmpty ? response : parsed.cleanedResponse,
                    isUser: false
                )
                
                await MainActor.run {
                    messages.append(aiMessage)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func executeCommand(_ command: TaskManager.ParsedCommand.CommandType) async {
        await MainActor.run {
            switch command {
            case .createTask(let title, let dueDate, let recurrence):
                let _ = taskManager.createTask(
                    title: title,
                    dueDate: dueDate,
                    recurrence: recurrence
                )
                
            case .completeTask(let id):
                let _ = taskManager.completeTask(byId: id)
                
            case .listTasks:
                // The AI will include tasks in its response
                break
                
            case .none:
                break
            }
        }
    }
}

// MARK: - Welcome View
struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(AppColors.brandPrimary)
            
            Text("Ippo AI Assistant")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("I can help you manage tasks, set reminders, and keep you motivated on your fitness journey!")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
            
            VStack(alignment: .leading, spacing: 8) {
                SuggestionChip(text: "📋 Create a morning run task")
                SuggestionChip(text: "🔄 Set up a daily workout reminder")
                SuggestionChip(text: "✅ Show my tasks")
            }
            .padding(.top, 8)
        }
    }
}

struct SuggestionChip: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(20)
    }
}

// MARK: - Chat Bubble
struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 60) }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(message.isUser ? AppColors.brandPrimary : Color(.systemGray5))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(16)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !message.isUser { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var animationOffset = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                    .offset(y: animationOffset == index ? -5 : 0)
            }
        }
        .padding(12)
        .background(Color(.systemGray5))
        .cornerRadius(16)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever()) {
                animationOffset = (animationOffset + 1) % 3
            }
        }
    }
}

// MARK: - AI Settings View
struct AISettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = ""
    @StateObject private var openAI = OpenAIService.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("OpenAI API Key", text: $apiKey)
                        .textContentType(.password)
                        .autocapitalization(.none)
                } header: {
                    Text("API Configuration")
                } footer: {
                    Text("Your API key is stored locally and never shared.")
                }
                
                Section {
                    Button("Save API Key") {
                        openAI.setAPIKey(apiKey)
                        dismiss()
                    }
                    .disabled(apiKey.isEmpty)
                }
            }
            .navigationTitle("AI Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                apiKey = openAI.getAPIKey()
            }
        }
    }
}

#Preview {
    AIChatView()
}
