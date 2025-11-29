import Foundation
import Combine
import SwiftUI

// View range options (no infinite now)
enum ViewMode: String, CaseIterable, Identifiable {
    case week
    case month
    case year

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week:  return "1W"
        case .month: return "1M"
        case .year:  return "1Y"
        }
    }

    var daysCount: Int {
        switch self {
        case .week:  return 7
        case .month: return 30
        case .year:  return 365
        }
    }
}

struct Habit: Identifiable, Codable {
    let id: UUID
    var name: String
    var kind : HabitKind
    var isCompletedToday: Bool   // unused now but kept for compatibility
}

enum HabitKind: String, Codable, CaseIterable, Identifiable {
    case checkbox
    case text
    case number

    var id: String { rawValue }

    var label: String {
        switch self {
        case .checkbox: return "Checkbox"
        case .text:     return "Text"
        case .number:   return "Number"
        }
    }
}

class HabitViewModel: ObservableObject {
    @Published var habits: [Habit] = [] {
        didSet { save() }
    }

    @Published var days: [Date] = []

    /// Checkbox completions: dateKey -> set of habit IDs
    @Published var completions: [String: Set<UUID>] = [:] {
        didSet { save() }
    }

    /// Text entries: dateKey -> habitId -> text
    @Published var textValues: [String: [UUID: String]] = [:] {
        didSet { save() }
    }

    /// Number entries (stored as strings for simplicity)
    @Published var numberValues: [String: [UUID: String]] = [:] {
        didSet { save() }
    }

    @Published var viewMode: ViewMode = .week {
        didSet { updateDaysForViewMode() }
    }

    private let habitsKey = "habits"
    private let completionsKey = "habitCompletions"
    private let textValuesKey = "habitTextValues"
    private let numberValuesKey = "habitNumberValues"
    
    private let calendar = Calendar.current

    init() {
        load()
        updateDaysForViewMode()
    }

    // MARK: - Habit CRUD

    func addHabit(name: String, kind: HabitKind) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let newHabit = Habit(id: UUID(), name: trimmed, kind: kind, isCompletedToday: false)
        habits.append(newHabit)
    }

    func rename(_ habit: Habit, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[index].name = trimmed
    }

    func deleteHabits(at offsets: IndexSet) {
        let idsToDelete = offsets.map { habits[$0].id }
        habits.remove(atOffsets: offsets)

        // Clean up completions for deleted habits
        for key in completions.keys {
            var set = completions[key] ?? []
            set.subtract(idsToDelete)
            if set.isEmpty {
                completions.removeValue(forKey: key)
            } else {
                completions[key] = set
            }
        }
    }

    // MARK: - Completion checks

    func isCompleted(_ habit: Habit, on date: Date) -> Bool {
        guard habit.kind == .checkbox else {return false}
        let key = dateKey(date)
        return completions[key]?.contains(habit.id) ?? false
    }

    func toggle(_ habit: Habit, on date: Date) {
        guard habit.kind == .checkbox else { return }
        let key = dateKey(date)
        var set = completions[key] ?? []

        if set.contains(habit.id) {
            set.remove(habit.id)
        } else {
            set.insert(habit.id)
        }

        completions[key] = set
    }

    // MARK: - Range handling (no infinite)

    private func updateDaysForViewMode() {
        let today = calendar.startOfDay(for: Date())
        let count = viewMode.daysCount

        var result: [Date] = []
        // oldest -> newest, ending at today
        for offset in stride(from: count - 1, through: 0, by: -1) {
            if let date = calendar.date(byAdding: .day, value: -offset, to: today) {
                result.append(date)
            }
        }

        days = result
    }

    // MARK: - Persistence

    private func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func save() {
        do {
            let habitsData = try JSONEncoder().encode(habits)
            UserDefaults.standard.set(habitsData, forKey: habitsKey)

            let dict = completions.mapValues { Array($0) }
            let completionsData = try JSONEncoder().encode(dict)
            UserDefaults.standard.set(completionsData, forKey: completionsKey)
            
            let textData = try JSONEncoder().encode(textValues)
                   UserDefaults.standard.set(textData, forKey: textValuesKey)

           let numberData = try JSONEncoder().encode(numberValues)
           UserDefaults.standard.set(numberData, forKey: numberValuesKey)
        } catch {
            print("Failed to save:", error)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: habitsKey),
           let decoded = try? JSONDecoder().decode([Habit].self, from: data) {
            habits = decoded
        }

        if let data = UserDefaults.standard.data(forKey: completionsKey),
           let decoded = try? JSONDecoder().decode([String: [UUID]].self, from: data) {
            completions = decoded.mapValues { Set($0) }
        }

        if let data = UserDefaults.standard.data(forKey: textValuesKey),
           let decoded = try? JSONDecoder().decode([String: [UUID: String]].self, from: data) {
            textValues = decoded
        }

        if let data = UserDefaults.standard.data(forKey: numberValuesKey),
           let decoded = try? JSONDecoder().decode([String: [UUID: String]].self, from: data) {
            numberValues = decoded
        }
    }

    
    // MARK: - Stats

    func completionCount(for habit: Habit) -> Int {
        guard habit.kind == .checkbox else { return 0 }
        return days.reduce(0) { count, date in
            let key = dateKey(date)
            let done = completions[key]?.contains(habit.id) ?? false
            return count + (done ? 1 : 0)
        }
    }

    func completionLabel(for habit: Habit) -> String {
        switch habit.kind {
            case .checkbox:
                let done = completionCount(for: habit)
                let total = viewMode.daysCount
                return "\(habit.name) (\(done)/\(total)d)"
            case .text:
                return "\(habit.name) (text)"
            case .number:
                return "\(habit.name) (number)"
            }
    }
    
    // MARK: - Text / Number values

    func textValue(for habit: Habit, on date: Date) -> String {
        let key = dateKey(date)
        return textValues[key]?[habit.id] ?? ""
    }

    func updateTextValue(for habit: Habit, on date: Date, value: String) {
        let key = dateKey(date)
        var dayDict = textValues[key] ?? [:]
        dayDict[habit.id] = value
        textValues[key] = dayDict
    }

    func numberString(for habit: Habit, on date: Date) -> String {
        let key = dateKey(date)
        return numberValues[key]?[habit.id] ?? ""
    }

    func updateNumberString(for habit: Habit, on date: Date, value: String) {
        let key = dateKey(date)
        var dayDict = numberValues[key] ?? [:]
        dayDict[habit.id] = value
        numberValues[key] = dayDict
    }

    
}
