import Foundation
import SwiftUI

// MARK: - Task Recurrence
enum TaskRecurrence: String, Codable, CaseIterable {
    case none = "none"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    
    var displayName: String {
        switch self {
        case .none: return "One-time"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}

// MARK: - Task Item
struct TaskItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var notes: String
    var dueDate: Date?
    var isCompleted: Bool
    var completedDate: Date?
    var recurrence: TaskRecurrence
    var createdAt: Date
    var lastRecurredAt: Date?
    
    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        dueDate: Date? = nil,
        isCompleted: Bool = false,
        completedDate: Date? = nil,
        recurrence: TaskRecurrence = .none,
        createdAt: Date = Date(),
        lastRecurredAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.recurrence = recurrence
        self.createdAt = createdAt
        self.lastRecurredAt = lastRecurredAt
    }
}

// MARK: - Task Manager
class TaskManager: ObservableObject {
    static let shared = TaskManager()
    
    @Published var tasks: [TaskItem] = []
    
    private let tasksKey = "ippo_tasks"
    
    private init() {
        loadTasks()
        checkRecurringTasks()
    }
    
    // MARK: - CRUD Operations
    
    func addTask(_ task: TaskItem) {
        tasks.append(task)
        saveTasks()
    }
    
    func createTask(title: String, notes: String = "", dueDate: Date? = nil, recurrence: TaskRecurrence = .none) -> TaskItem {
        let task = TaskItem(
            title: title,
            notes: notes,
            dueDate: dueDate,
            recurrence: recurrence
        )
        addTask(task)
        return task
    }
    
    func updateTask(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveTasks()
        }
    }
    
    func deleteTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }
    
    func deleteTask(at indexSet: IndexSet) {
        tasks.remove(atOffsets: indexSet)
        saveTasks()
    }
    
    func toggleComplete(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            
            if tasks[index].isCompleted {
                tasks[index].completedDate = Date()
                
                // Handle recurring tasks
                if tasks[index].recurrence != .none {
                    scheduleNextRecurrence(for: tasks[index])
                }
            } else {
                tasks[index].completedDate = nil
            }
            
            saveTasks()
        }
    }
    
    func completeTask(byId id: String) -> Bool {
        // Try to match by UUID prefix
        if let task = tasks.first(where: { $0.id.uuidString.lowercased().hasPrefix(id.lowercased()) }) {
            toggleComplete(task)
            return true
        }
        return false
    }
    
    // MARK: - Recurring Tasks
    
    private func scheduleNextRecurrence(for task: TaskItem) {
        var newTask = task
        newTask.isCompleted = false
        newTask.completedDate = nil
        newTask.lastRecurredAt = Date()
        
        // Calculate next due date
        if let currentDue = task.dueDate {
            switch task.recurrence {
            case .daily:
                newTask.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDue)
            case .weekly:
                newTask.dueDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentDue)
            case .monthly:
                newTask.dueDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDue)
            case .none:
                break
            }
        }
        
        // Create new instance for recurring task
        let recurringTask = TaskItem(
            title: newTask.title,
            notes: newTask.notes,
            dueDate: newTask.dueDate,
            recurrence: newTask.recurrence,
            lastRecurredAt: Date()
        )
        
        addTask(recurringTask)
    }
    
    private func checkRecurringTasks() {
        // Called on init to check if any recurring tasks need new instances
        let now = Date()
        let calendar = Calendar.current
        
        for task in tasks where task.recurrence != .none && task.isCompleted {
            guard let dueDate = task.dueDate else { continue }
            
            var shouldRecur = false
            
            switch task.recurrence {
            case .daily:
                shouldRecur = !calendar.isDate(dueDate, inSameDayAs: now)
            case .weekly:
                shouldRecur = calendar.dateComponents([.day], from: dueDate, to: now).day ?? 0 >= 7
            case .monthly:
                shouldRecur = calendar.dateComponents([.month], from: dueDate, to: now).month ?? 0 >= 1
            case .none:
                break
            }
            
            if shouldRecur {
                scheduleNextRecurrence(for: task)
            }
        }
    }
    
    // MARK: - Filtering
    
    var pendingTasks: [TaskItem] {
        tasks.filter { !$0.isCompleted }.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }
    
    var completedTasks: [TaskItem] {
        tasks.filter { $0.isCompleted }.sorted { ($0.completedDate ?? .distantPast) > ($1.completedDate ?? .distantPast) }
    }
    
    var todayTasks: [TaskItem] {
        let calendar = Calendar.current
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDateInToday(dueDate) && !task.isCompleted
        }
    }
    
    var overdueTasks: [TaskItem] {
        let now = Date()
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate < now && !task.isCompleted
        }
    }
    
    // MARK: - Persistence
    
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: tasksKey)
        }
    }
    
    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: tasksKey),
           let decoded = try? JSONDecoder().decode([TaskItem].self, from: data) {
            tasks = decoded
        }
    }
}

// MARK: - AI Command Parser
extension TaskManager {
    
    struct ParsedCommand {
        enum CommandType {
            case createTask(title: String, dueDate: Date?, recurrence: TaskRecurrence)
            case completeTask(id: String)
            case listTasks
            case none
        }
        
        let type: CommandType
        let cleanedResponse: String
    }
    
    func parseAIResponse(_ response: String) -> ParsedCommand {
        var cleanedResponse = response
        var commandType: ParsedCommand.CommandType = .none
        
        // Check for CREATE_TASK command
        if let createMatch = response.range(of: #"\[CREATE_TASK:\s*([^\]]+)\]"#, options: .regularExpression) {
            let commandString = String(response[createMatch])
            cleanedResponse = response.replacingCharacters(in: createMatch, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Parse: title | due date | recurrence
            let content = commandString
                .replacingOccurrences(of: "[CREATE_TASK:", with: "")
                .replacingOccurrences(of: "]", with: "")
                .trimmingCharacters(in: .whitespaces)
            
            let parts = content.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
            
            let title = parts.first ?? "New Task"
            var dueDate: Date? = nil
            var recurrence: TaskRecurrence = .none
            
            if parts.count > 1 {
                dueDate = parseDate(parts[1])
            }
            
            if parts.count > 2 {
                recurrence = TaskRecurrence(rawValue: parts[2].lowercased()) ?? .none
            }
            
            commandType = .createTask(title: title, dueDate: dueDate, recurrence: recurrence)
        }
        
        // Check for COMPLETE_TASK command
        if let completeMatch = response.range(of: #"\[COMPLETE_TASK:\s*([^\]]+)\]"#, options: .regularExpression) {
            let commandString = String(response[completeMatch])
            cleanedResponse = response.replacingCharacters(in: completeMatch, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            
            let taskId = commandString
                .replacingOccurrences(of: "[COMPLETE_TASK:", with: "")
                .replacingOccurrences(of: "]", with: "")
                .trimmingCharacters(in: .whitespaces)
            
            commandType = .completeTask(id: taskId)
        }
        
        // Check for LIST_TASKS command
        if response.contains("[LIST_TASKS]") {
            cleanedResponse = response.replacingOccurrences(of: "[LIST_TASKS]", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            commandType = .listTasks
        }
        
        return ParsedCommand(type: commandType, cleanedResponse: cleanedResponse)
    }
    
    private func parseDate(_ string: String) -> Date? {
        let lowered = string.lowercased()
        let calendar = Calendar.current
        let now = Date()
        
        // Handle relative dates
        if lowered.contains("tomorrow") {
            var date = calendar.date(byAdding: .day, value: 1, to: now) ?? now
            date = parseTimeComponent(from: lowered, defaultDate: date)
            return date
        }
        
        if lowered.contains("today") {
            var date = now
            date = parseTimeComponent(from: lowered, defaultDate: date)
            return date
        }
        
        if lowered.contains("next") {
            // Handle "next Monday", "next week", etc.
            let weekdays = ["sunday": 1, "monday": 2, "tuesday": 3, "wednesday": 4, "thursday": 5, "friday": 6, "saturday": 7]
            
            for (day, weekdayNum) in weekdays {
                if lowered.contains(day) {
                    var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
                    components.weekday = weekdayNum
                    if let date = calendar.date(from: components) {
                        var adjustedDate = date < now ? calendar.date(byAdding: .weekOfYear, value: 1, to: date)! : date
                        adjustedDate = parseTimeComponent(from: lowered, defaultDate: adjustedDate)
                        return adjustedDate
                    }
                }
            }
        }
        
        // Try standard date formats
        let formatters = [
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd",
            "MM/dd/yyyy",
            "MM-dd-yyyy"
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: string) {
                return date
            }
        }
        
        return nil
    }
    
    private func parseTimeComponent(from string: String, defaultDate: Date) -> Date {
        let calendar = Calendar.current
        
        // Look for time patterns like "7am", "3:30pm", "14:00"
        let timePattern = #"(\d{1,2})(?::(\d{2}))?\s*(am|pm)?"#
        
        guard let regex = try? NSRegularExpression(pattern: timePattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: string, options: [], range: NSRange(string.startIndex..., in: string)) else {
            return defaultDate
        }
        
        var hour = 9 // Default to 9 AM
        var minute = 0
        
        if let hourRange = Range(match.range(at: 1), in: string) {
            hour = Int(string[hourRange]) ?? 9
        }
        
        if let minuteRange = Range(match.range(at: 2), in: string) {
            minute = Int(string[minuteRange]) ?? 0
        }
        
        if let ampmRange = Range(match.range(at: 3), in: string) {
            let ampm = string[ampmRange].lowercased()
            if ampm == "pm" && hour < 12 {
                hour += 12
            } else if ampm == "am" && hour == 12 {
                hour = 0
            }
        }
        
        var components = calendar.dateComponents([.year, .month, .day], from: defaultDate)
        components.hour = hour
        components.minute = minute
        
        return calendar.date(from: components) ?? defaultDate
    }
}
