import SwiftUI

struct TaskListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var taskManager = TaskManager.shared
    
    @State private var showingAddTask = false
    @State private var selectedFilter: TaskFilter = .pending
    @State private var searchText = ""
    
    enum TaskFilter: String, CaseIterable {
        case pending = "Pending"
        case completed = "Completed"
        case all = "All"
    }
    
    var filteredTasks: [TaskItem] {
        var tasks: [TaskItem]
        
        switch selectedFilter {
        case .pending:
            tasks = taskManager.pendingTasks
        case .completed:
            tasks = taskManager.completedTasks
        case .all:
            tasks = taskManager.tasks
        }
        
        if !searchText.isEmpty {
            tasks = tasks.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        
        return tasks
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(TaskFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Quick stats
                HStack(spacing: 20) {
                    StatBadge(
                        icon: "clock",
                        value: taskManager.pendingTasks.count,
                        label: "Pending",
                        color: .blue
                    )
                    
                    StatBadge(
                        icon: "exclamationmark.circle",
                        value: taskManager.overdueTasks.count,
                        label: "Overdue",
                        color: .red
                    )
                    
                    StatBadge(
                        icon: "checkmark.circle",
                        value: taskManager.completedTasks.count,
                        label: "Done",
                        color: .green
                    )
                }
                .padding(.horizontal)
                .padding(.bottom)
                
                // Task list
                if filteredTasks.isEmpty {
                    EmptyTasksView(filter: selectedFilter)
                } else {
                    List {
                        ForEach(filteredTasks) { task in
                            TaskRow(task: task, onToggle: {
                                taskManager.toggleComplete(task)
                            })
                        }
                        .onDelete { indexSet in
                            let tasksToDelete = indexSet.map { filteredTasks[$0] }
                            for task in tasksToDelete {
                                taskManager.deleteTask(task)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .searchable(text: $searchText, prompt: "Search tasks")
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddTask = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
        }
    }
}

// MARK: - Stat Badge
struct StatBadge: View {
    let icon: String
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text("\(value)")
                    .fontWeight(.bold)
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Task Row
struct TaskRow: View {
    let task: TaskItem
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            .buttonStyle(.plain)
            
            // Task info
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                
                HStack(spacing: 8) {
                    if let dueDate = task.dueDate {
                        Label(formatDueDate(dueDate), systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(isOverdue(dueDate) && !task.isCompleted ? .red : .secondary)
                    }
                    
                    if task.recurrence != .none {
                        Label(task.recurrence.displayName, systemImage: "repeat")
                            .font(.caption)
                            .foregroundColor(AppColors.brandPrimary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func formatDueDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
    
    private func isOverdue(_ date: Date) -> Bool {
        return date < Date()
    }
}

// MARK: - Empty Tasks View
struct EmptyTasksView: View {
    let filter: TaskListView.TaskFilter
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: emptyIcon)
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text(emptyTitle)
                .font(.headline)
            
            Text(emptySubtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxHeight: .infinity)
    }
    
    private var emptyIcon: String {
        switch filter {
        case .pending: return "checkmark.circle"
        case .completed: return "star.circle"
        case .all: return "tray"
        }
    }
    
    private var emptyTitle: String {
        switch filter {
        case .pending: return "All caught up!"
        case .completed: return "No completed tasks yet"
        case .all: return "No tasks"
        }
    }
    
    private var emptySubtitle: String {
        switch filter {
        case .pending: return "You've completed all your tasks. Nice work!"
        case .completed: return "Complete some tasks to see them here"
        case .all: return "Tap + to add your first task"
        }
    }
}

// MARK: - Add Task View
struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var taskManager = TaskManager.shared
    
    @State private var title = ""
    @State private var notes = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var recurrence: TaskRecurrence = .none
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task title", text: $title)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Toggle("Due Date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Date & Time", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section {
                    Picker("Repeat", selection: $recurrence) {
                        ForEach(TaskRecurrence.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                } footer: {
                    if recurrence != .none {
                        Text("This task will automatically repeat \(recurrence.rawValue)")
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        let _ = taskManager.createTask(
                            title: title,
                            notes: notes,
                            dueDate: hasDueDate ? dueDate : nil,
                            recurrence: recurrence
                        )
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    TaskListView()
}
