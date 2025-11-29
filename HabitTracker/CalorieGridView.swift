import SwiftUI

struct CalorieGridView: View {
    @ObservedObject var vm: CalorieViewModel

    private let rowHeight: CGFloat = 44

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
        GeometryReader { geo in
            let widths = columnWidths(totalWidth: geo.size.width)

            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    headerRow(dateWidth: widths.date, intakeWidth: widths.intake)

                    ScrollView(.vertical) {
                        VStack(spacing: 0) {
                            ForEach(Array(vm.days.enumerated()), id: \.element) { index, day in
                                row(
                                    for: day,
                                    rowIndex: index,
                                    dateWidth: widths.date,
                                    intakeWidth: widths.intake
                                )
                                .id(day)
                            }
                        }
                    }
                    .scrollDismissesKeyboard(.immediately)
                }
                // 👇 card now fills the entire width given by the parent
                .frame(
                    width: geo.size.width,
                    height: geo.size.height,
                    alignment: .top
                )
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.separator), lineWidth: 1)
                )
                .shadow(radius: 4, y: 2)
                // no horizontal padding anymore
                .padding(.bottom, 8)
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

    private func headerRow(dateWidth: CGFloat,
                           intakeWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            ZStack {
                Color.accentColor
                Text("Date")
                    .font(.caption.bold())
                    .foregroundColor(Color(.systemBackground))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(width: dateWidth, height: rowHeight)

            ZStack {
                Color.accentColor
                VStack(spacing: 2) {
                    Text("Intake vs Target")
                        .font(.caption2.bold())
                        .foregroundColor(Color(.systemBackground))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)

                    Text("Target: \(vm.dailyTarget) kcal")
                        .font(.caption2)
                        .foregroundColor(Color(.systemBackground).opacity(0.9))
                }
            }
            .frame(width: intakeWidth, height: rowHeight)
        }
    }

    // MARK: - Rows

    private func row(for date: Date,
                     rowIndex: Int,
                     dateWidth: CGFloat,
                     intakeWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
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
            .frame(width: dateWidth, height: rowHeight)

            ZStack {
                rowBackground(for: rowIndex)

                VStack(spacing: 4) {
                    TextField(
                        "Intake",
                        text: Binding(
                            get: { vm.intakeString(for: date) },
                            set: { vm.updateIntakeString(for: date, value: $0) }
                        )
                    )
                    .keyboardType(.numberPad)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 6)
                    .frame(maxWidth: .infinity)
                    .frame(height: 26)
                    .background(Color(.tertiarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(.separator), lineWidth: 1)
                    )

                    Text(vm.deficitLabel(for: date))
                        .font(.caption2)
                        .foregroundColor(vm.deficitColor(for: date))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(.horizontal, 4)
            }
            .frame(width: intakeWidth, height: rowHeight)
        }
    }

    // MARK: - Helpers

    private func rowBackground(for index: Int) -> Color {
        index.isMultiple(of: 2)
        ? Color(.secondarySystemBackground)
        : Color(.systemBackground)
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

    private func columnWidths(totalWidth: CGFloat) -> (date: CGFloat, intake: CGFloat) {
        // use full width; no outer padding now
        let available = totalWidth

        // ~35% for date, rest for intake
        let date = max(110, available * 0.35)
        let intake = max(available - date, 150)

        return (date, intake)
    }
}
