//
//  CalorieViewModel.swift
//  HabitTracker
//
//  Created by Vineeth  Reddy on 03/12/25.
//


import Foundation
import SwiftUI
import Combine

class CalorieViewModel: ObservableObject {
    @Published var dailyTarget: Int {
        didSet { save() }
    }

    @Published var days: [Date] = []

    /// dateKey -> total intake (kcal) for that day
    @Published var dailyIntake: [String: Int] = [:] {
        didSet { save() }
    }

    @Published var viewMode: ViewMode = .week {
        didSet { updateDaysForViewMode() }
    }

    private let calendar = Calendar.current

    private let targetKey = "calorieDailyTarget"
    private let intakeKey = "calorieDailyIntake"

    init() {
        // Target
        let storedTarget = UserDefaults.standard.integer(forKey: targetKey)
        dailyTarget = storedTarget == 0 ? 2000 : storedTarget   // sensible default

        // Intake
        if let data = UserDefaults.standard.data(forKey: intakeKey),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            dailyIntake = decoded
        }

        updateDaysForViewMode()
    }

    // MARK: - Public API

    func intake(for date: Date) -> Int {
        dailyIntake[dateKey(date)] ?? 0
    }

    func updateIntake(for date: Date, value: Int) {
        let safe = max(value, 0)
        dailyIntake[dateKey(date)] = safe
    }

    func intakeString(for date: Date) -> String {
        let value = intake(for: date)
        return value == 0 ? "" : String(value)
    }

    func updateIntakeString(for date: Date, value: String) {
        let filtered = value.filter { $0.isNumber }
        guard !filtered.isEmpty else {
            dailyIntake.removeValue(forKey: dateKey(date))
            return
        }
        if let intVal = Int(filtered) {
            updateIntake(for: date, value: intVal)
        }
    }

    /// Positive = deficit, negative = surplus
    func deficit(for date: Date) -> Int {
        dailyTarget - intake(for: date)
    }

    func deficitLabel(for date: Date) -> String {
        let diff = deficit(for: date)

        if dailyTarget == 0 && intake(for: date) == 0 {
            return "No data"
        }

        if diff == 0 {
            return "On target"
        } else if diff > 0 {
            return "Deficit \(diff) kcal"
        } else {
            return "Over by \(-diff) kcal"
        }
    }

    func deficitColor(for date: Date) -> Color {
        let diff = deficit(for: date)
        if diff > 0 {
            return Color(.systemGreen)
        } else if diff < 0 {
            return Color(.systemRed)
        } else {
            return .secondary
        }
    }

    // MARK: - Range handling (reuse logic)

    private func updateDaysForViewMode() {
        let today = calendar.startOfDay(for: Date())
        let count = viewMode.daysCount

        var result: [Date] = []
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
        UserDefaults.standard.set(dailyTarget, forKey: targetKey)

        if let data = try? JSONEncoder().encode(dailyIntake) {
            UserDefaults.standard.set(data, forKey: intakeKey)
        }
    }
    
    // MARK: - Range totals (net on logged days)

    /// Net deficit for days where intake was logged.
    /// - Only counts days in `days`
    /// - Only counts days where `dailyIntake` has an entry
    /// - Adds both deficits (positive) and surpluses (negative)
    func totalNetForLoggedDaysInRange() -> Int {
        days.reduce(0) { partial, date in
            let key = dateKey(date)

            // Only count days where user logged intake
            guard dailyIntake[key] != nil else { return partial }

            // deficit(for:) is (target - intake) and can be positive or negative
            return partial + deficit(for: date)
        }
    }

    /// Number of days in the current range where intake was logged.
    func loggedDaysCountInRange() -> Int {
        days.filter { date in
            dailyIntake[dateKey(date)] != nil
        }.count
    }

    func loggedNetSummaryLabel() -> String {
        let loggedDays = loggedDaysCountInRange()

        guard loggedDays > 0 else {
            return "No logged days in this range"
        }

        let total = totalNetForLoggedDaysInRange()

        if total == 0 {
            return "Net: On target across \(loggedDays) logged day(s): \(total) kcal "
        } else if total > 0 {
            return "Net deficit over \(loggedDays) logged day(s): \(total) kcal"
        } else {
            return "Net surplus over \(loggedDays) logged day(s): \(-total) kcal"
        }
    }

    func loggedNetSummaryColor() -> Color {
        let total = totalNetForLoggedDaysInRange()
        if total > 0 {
            return Color(.systemGreen)   // net deficit
        } else if total < 0 {
            return Color(.systemRed)     // net surplus
        } else {
            return .secondary
        }
    }

}
