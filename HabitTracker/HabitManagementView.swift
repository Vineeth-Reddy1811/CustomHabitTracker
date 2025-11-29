//
//  HabitManagementView.swift
//  HabitTracker
//
//  Created by Vineeth  Reddy on 28/11/25.
//


import SwiftUI

struct HabitManagementView: View {
    @ObservedObject var vm: HabitViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(vm.habits) { habit in
                    HStack {
                        TextField(
                            "Name",
                            text: Binding(
                                get: { habit.name },
                                set: { newName in
                                    vm.rename(habit, to: newName)
                                }
                            )
                        )
                    }
                }
                .onDelete(perform: vm.deleteHabits)
            }
            .navigationTitle("Manage Habits")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
        }
    }
}
