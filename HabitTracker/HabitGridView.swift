import SwiftUI

struct HabitGridView: View {
    @ObservedObject var vm: HabitViewModel

    // Tunable sizes
    private let columnWidth: CGFloat = 90
    private let rowHeight: CGFloat = 40

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        return df
    }()

    private static let weekdayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "EEE"
        return df
    }()

    var body: some View {
        // Horizontal scroll for the whole table
        ScrollView(.horizontal) {
            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    // 🔹 Header stays fixed vertically
                    headerRow

                    // 🔹 Rows scroll vertically beneath the header
                    ScrollView(.vertical) {
                        VStack(spacing: 0) {
                            ForEach(Array(vm.days.enumerated()), id: \.element) { index, day in
                                row(for: day, rowIndex: index)
                                    .id(day)   // for scrollTo(today)
                            }
                        }
                    }
                    .scrollDismissesKeyboard(.immediately)
                }
                // Card background adapts to light/dark
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.separator), lineWidth: 1)
                )
                .shadow(radius: 4, y: 2)
                .padding()
                // 👇 Scroll to today on first show & whenever view mode changes
                .onAppear {
                    scrollToToday(proxy: proxy)
                }
                .onChange(of: vm.viewMode) {
                    scrollToToday(proxy: proxy)
                }
            }
        }
        .scrollDismissesKeyboard(.immediately)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 0) {
            // Date header cell
            ZStack {
                Color.accentColor
                Text("Date")
                    .font(.caption.bold())
                    .foregroundColor(Color(.systemBackground))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(width: columnWidth, height: rowHeight)

            // Habit header cells with stats + type dropdown
            ForEach(vm.habits) { habit in
                Menu {
                    // 👇 Picker-style menu for type
                    Picker("Type", selection: Binding<HabitKind>(
                        get: { habit.kind },
                        set: { newKind in
                            vm.updateKind(habit, to: newKind)
                        }
                    )) {
                        ForEach(HabitKind.allCases) { kind in
                            Text(kind.label).tag(kind)
                        }
                    }
                } label: {
                    ZStack {
                        Color.accentColor
                        VStack(spacing: 2) {
                            Text(vm.completionLabel(for: habit))
                                .font(.caption2.bold())
                                .foregroundColor(Color(.systemBackground))
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .truncationMode(.tail)
                                .padding(.horizontal, 2)

                            // Small type indicator under the name
                            Text(habit.kind.label)
                                .font(.caption2)
                                .foregroundColor(Color(.systemBackground).opacity(0.8))
                        }
                    }
                    .frame(width: columnWidth, height: rowHeight)
                }
            }
        }
    }

    // MARK: - Rows

    private func row(for date: Date, rowIndex: Int) -> some View {
        HStack(spacing: 0) {
            // Date cell
            ZStack {
                rowBackground(for: rowIndex)

                VStack(spacing: 2) {
                    Text(Self.dateFormatter.string(from: date))
                        .font(.caption.bold())
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text(Self.weekdayFormatter.string(from: date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(width: columnWidth, height: rowHeight)

            // Habit cells: checkbox / text / number
            ForEach(vm.habits) { habit in
                ZStack {
                    rowBackground(for: rowIndex)

                    switch habit.kind {
                    case .checkbox:
                        let checked = vm.isCompleted(habit, on: date)

                        Button {
                            vm.toggle(habit, on: date)
                        } label: {
                            Image(systemName: checked ? "checkmark.square.fill" : "square")
                                .imageScale(.medium)
                                .foregroundColor(
                                    checked
                                    ? Color(.systemGreen)
                                    : Color(.tertiaryLabel)
                                )
                        }
                        .buttonStyle(.plain)

                    case .text:
                        TextField(
                            "",
                            text: Binding(
                                get: { vm.textValue(for: habit, on: date) },
                                set: { vm.updateTextValue(for: habit, on: date, value: $0) }
                            )
                        )
                        .padding(.horizontal, 4)
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background(Color(.tertiarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                        .font(.caption)
                        .multilineTextAlignment(.center)

                    case .number:
                        TextField(
                            "",
                            text: Binding(
                                get: { vm.numberString(for: habit, on: date) },
                                set: { vm.updateNumberString(for: habit, on: date, value: $0) }
                            )
                        )
                        .keyboardType(.decimalPad)
                        .padding(.horizontal, 4)
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background(Color(.tertiarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                        .font(.caption)
                        .multilineTextAlignment(.center)
                    }
                }
                .frame(width: columnWidth, height: rowHeight)
                .padding(.horizontal, 3)
            }
        }
    }

    // MARK: - Helpers

    private func rowBackground(for index: Int) -> Color {
        index.isMultiple(of: 2)
        ? Color(.secondarySystemBackground)   // slightly tinted
        : Color(.systemBackground)            // base background
    }

    private func scrollToToday(proxy: ScrollViewProxy) {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())

        if let target = vm.days.first(where: { calendar.isDate($0, inSameDayAs: todayStart) }) {
            withAnimation {
                proxy.scrollTo(target, anchor: .center)
            }
        }
    }
}
