import SwiftUI
import UIKit

// MARK: - ContentView

struct ContentView: View {
    @StateObject private var vm = HabitViewModel()
    @State private var newHabitName: String = ""
    @State private var showManageHabits = false
    @State private var newHabitKind: HabitKind = .checkbox


    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // Top row: add new habit
                HStack {
                    TextField("New habit", text: $newHabitName)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        vm.addHabit(name: newHabitName)
                        newHabitName = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                    }
                }
                .padding(.horizontal)
                
                // View range picker (1W / 1M / 1Y)
                Picker("View", selection: $vm.viewMode) {
                    ForEach(ViewMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if vm.habits.isEmpty {
                    Text("Add a habit to start tracking.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    HabitGridView(vm: vm)
                }
            }
            .padding(.vertical)
            .background(
                Color(.systemBackground)
                    .ignoresSafeArea()
            )
            .navigationTitle("Habit Calendar")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showManageHabits = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showManageHabits) {
                HabitManagementView(vm: vm)
            }
        }
        .hideKeyboardOnTap() // 👈 tapping anywhere dismisses the keyboard
    }
}
