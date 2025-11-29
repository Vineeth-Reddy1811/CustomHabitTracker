import SwiftUI

struct CalorieCounterView: View {
    @StateObject private var vm = CalorieViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                // Daily target control
                targetRow

                // View range picker (1W / 1M / 1Y)
                Picker("View", selection: $vm.viewMode) {
                    ForEach(ViewMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Net total summary for current range
                Text(vm.loggedNetSummaryLabel())
                    .font(.footnote.weight(.medium))
                    .foregroundColor(vm.loggedNetSummaryColor())
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Grid fills remaining space
                if vm.days.isEmpty {
                    Text("No days to show.")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    CalorieGridView(vm: vm)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top)
            .background(
                Color(.systemBackground)
                    .ignoresSafeArea()
            )
            .navigationTitle("Calorie Counter")
        }
        .hideKeyboardOnTap()
    }

    // MARK: - Subviews

    private var targetRow: some View {
        HStack {
            Text("Daily target")
                .font(.subheadline)

            TextField(
                "kcal",
                text: Binding(
                    get: { vm.dailyTarget == 0 ? "" : String(vm.dailyTarget) },
                    set: { newValue in
                        let filtered = newValue.filter { $0.isNumber }
                        if let intVal = Int(filtered) {
                            vm.dailyTarget = intVal
                        } else if newValue.isEmpty {
                            vm.dailyTarget = 0
                        }
                    }
                )
            )
            .keyboardType(.numberPad)
            .textFieldStyle(.roundedBorder)

            Text("kcal")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
}
