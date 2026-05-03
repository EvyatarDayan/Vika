//
//  HistoryView.swift
//  Vika
//

import SwiftUI
import UIKit

private extension UIColor {
    static var vikaAppGreen: UIColor {
        UIColor(named: "AppGreen") ?? UIColor(red: 0.314, green: 0.784, blue: 0.471, alpha: 1)
    }
}

struct ActivityShareView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct HistoryView: View {
    @ObservedObject var historyStore: LivePaymentHistoryStore
    @AppStorage(LocaleCurrency.appStorageKey) private var storedCurrencyCode = ""

    @State private var selectedFolder: String?
    @State private var selectedRecord: LivePaymentRecord?
    @State private var showShareSheet = false
    @State private var pdfURL: URL?
    @State private var refreshId = UUID()

    let languageCode: String

    private func t(_ key: VikaL10n.Key) -> String {
        VikaL10n.t(key, languageCode: languageCode)
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        f.locale = Locale(identifier: languageCode)
        return f
    }

    private var uniqueFolders: [String] {
        Array(Set(historyStore.records.map(\.folderName))).sorted()
    }

    private var sortedRecords: [LivePaymentRecord] {
        var list = historyStore.records
        if let selectedFolder {
            list = list.filter { $0.folderName == selectedFolder }
        }
        return list.sorted { $0.date > $1.date }
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            if historyStore.records.isEmpty {
                Text(t(.historyEmpty))
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            filterChip(title: t(.historyAll), isSelected: selectedFolder == nil) {
                                selectedFolder = nil
                            }

                            ForEach(uniqueFolders, id: \.self) { name in
                                filterChip(title: name, isSelected: selectedFolder == name) {
                                    selectedFolder = selectedFolder == name ? nil : name
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                    }
                    .background(Color(.systemGroupedBackground))

                    List {
                        ForEach(sortedRecords) { record in
                            recordRow(record: record)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                historyStore.deleteRecord(sortedRecords[index])
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle(t(.historyTitle))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            if !historyStore.records.isEmpty {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(t(.historyExport)) {
                        exportAllToPDF()
                    }
                    .foregroundStyle(Color.appGreen)
                }
            }
        }
        .sheet(item: $selectedRecord) { record in
            NavigationStack {
                LivePaymentDetailView(record: record, historyStore: historyStore, languageCode: languageCode)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let pdfURL {
                ActivityShareView(activityItems: [pdfURL])
            }
        }
        .onAppear {
            historyStore.loadRecords()
        }
        .onChange(of: storedCurrencyCode) { _, _ in
            historyStore.loadRecords()
            refreshId = UUID()
        }
        .id(refreshId)
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(isSelected ? Color.white : Color.appGreen)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.appGreen : Color.appGreen.opacity(0.12))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func recordRow(record: LivePaymentRecord) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.folderName)
                    .font(.headline)

                Text("\(dateFormatter.string(from: record.date)) • \(formatDuration(record.duration))")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(
                    String(
                        format: "%@%.2f",
                        LocaleCurrency.currencySymbol(forCode: record.currencyCode),
                        record.totalPay
                    )
                )
                .font(.headline)
                .foregroundStyle(Color.appGreen)

                Text(record.isPaid ? t(.historyPaid) : t(.historyPending))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(record.isPaid ? Color.green : Color.appGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(record.isPaid ? Color.green.opacity(0.2) : Color.appGreen.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .listRowBackground(Color(.systemGroupedBackground))
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 6, leading: 4, bottom: 6, trailing: 4))
        .contentShape(Rectangle())
        .onTapGesture {
            selectedRecord = record
        }
    }

    private var cardBackground: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? .secondarySystemBackground : .systemBackground
        })
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)

        var parts: [String] = []
        if hours > 0 {
            parts.append(
                hours == 1
                    ? t(.historyDurationHourOne)
                    : String(format: t(.historyDurationHours), hours)
            )
        }
        if minutes > 0 {
            parts.append(
                minutes == 1
                    ? t(.historyDurationMinuteOne)
                    : String(format: t(.historyDurationMinutes), minutes)
            )
        }
        if parts.isEmpty {
            return t(.historyDurationZero)
        }
        if parts.count == 1 {
            return parts[0]
        }
        return parts.joined(separator: " \(t(.historyDurationAnd)) ")
    }

    private func exportAllToPDF() {
        let pdfMetaData: [CFString: Any] = [
            kCGPDFContextCreator: "Vika",
            kCGPDFContextAuthor: "Vika",
            kCGPDFContextTitle: t(.historyPdfTitle),
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()

            let cgContext = context.cgContext
            var yPosition: CGFloat = 72
            let leftMargin: CGFloat = 72
            let rightMargin: CGFloat = 72
            let tableWidth = pageWidth - leftMargin - rightMargin
            let rowHeight: CGFloat = 30
            let cellPadding: CGFloat = 8

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.vikaAppGreen,
            ]
            let title = t(.historyPdfTitle)
            let titleSize = title.size(withAttributes: titleAttributes)
            title.draw(at: CGPoint(x: (pageWidth - titleSize.width) / 2, y: yPosition), withAttributes: titleAttributes)
            yPosition += titleSize.height + 20

            let summaryText = String(format: t(.historyPdfTotalRecords), sortedRecords.count)
            let summaryAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.secondaryLabel,
            ]
            let summarySize = summaryText.size(withAttributes: summaryAttributes)
            summaryText.draw(at: CGPoint(x: (pageWidth - summarySize.width) / 2, y: yPosition), withAttributes: summaryAttributes)
            yPosition += summarySize.height + 30

            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.label,
            ]

            let columns = [
                t(.historyColumnName),
                t(.historyColumnDate),
                t(.historyColumnDuration),
                t(.historyColumnTotal),
                t(.historyColumnStatus),
            ]
            let columnWidth = tableWidth / CGFloat(columns.count)

            var maxHeaderHeight: CGFloat = rowHeight
            let availableCellWidth = columnWidth - (cellPadding * 2)

            for column in columns {
                let boundingRect = (column as NSString).boundingRect(
                    with: CGSize(width: availableCellWidth, height: CGFloat.greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: headerAttributes,
                    context: nil
                )
                let cellHeight = max(boundingRect.height + (cellPadding * 2), rowHeight)
                maxHeaderHeight = max(maxHeaderHeight, cellHeight)
            }

            let headerRect = CGRect(x: leftMargin, y: yPosition, width: tableWidth, height: maxHeaderHeight)
            UIColor.systemGray6.setFill()
            cgContext.fill(headerRect)

            for (index, column) in columns.enumerated() {
                let xPosition = leftMargin + CGFloat(index) * columnWidth
                let cellRect = CGRect(
                    x: xPosition + cellPadding,
                    y: yPosition + cellPadding,
                    width: columnWidth - (cellPadding * 2),
                    height: maxHeaderHeight - (cellPadding * 2)
                )
                (column as NSString).draw(in: cellRect, withAttributes: headerAttributes)

                if index > 0 {
                    cgContext.setStrokeColor(UIColor.separator.cgColor)
                    cgContext.setLineWidth(1.0)
                    cgContext.move(to: CGPoint(x: xPosition, y: yPosition))
                    cgContext.addLine(to: CGPoint(x: xPosition, y: yPosition + maxHeaderHeight))
                    cgContext.strokePath()
                }
            }

            cgContext.setStrokeColor(UIColor.separator.cgColor)
            cgContext.setLineWidth(1.0)
            cgContext.stroke(headerRect)
            yPosition += maxHeaderHeight

            let recordAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.label,
            ]

            for record in sortedRecords {
                let dateText = dateFormatter.string(from: record.date)
                let durationText = formatDuration(record.duration)
                let totalPayText =
                    "\(LocaleCurrency.currencySymbol(forCode: record.currencyCode))\(String(format: "%.2f", record.totalPay))"
                let statusText = record.isPaid ? t(.historyPaid) : t(.historyPending)

                let rowData = [record.folderName, dateText, durationText, totalPayText, statusText]

                var maxCellHeight: CGFloat = rowHeight
                for data in rowData {
                    let boundingRect = (data as NSString).boundingRect(
                        with: CGSize(width: availableCellWidth, height: CGFloat.greatestFiniteMagnitude),
                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                        attributes: recordAttributes,
                        context: nil
                    )
                    let cellHeight = max(boundingRect.height + (cellPadding * 2), rowHeight)
                    maxCellHeight = max(maxCellHeight, cellHeight)
                }

                if yPosition + maxCellHeight > pageHeight - 72 {
                    context.beginPage()
                    yPosition = 72
                }

                let rowRect = CGRect(x: leftMargin, y: yPosition, width: tableWidth, height: maxCellHeight)

                for (index, data) in rowData.enumerated() {
                    let xPosition = leftMargin + CGFloat(index) * columnWidth
                    let cellRect = CGRect(
                        x: xPosition + cellPadding,
                        y: yPosition + cellPadding,
                        width: columnWidth - (cellPadding * 2),
                        height: maxCellHeight - (cellPadding * 2)
                    )
                    (data as NSString).draw(in: cellRect, withAttributes: recordAttributes)

                    if index > 0 {
                        cgContext.setStrokeColor(UIColor.separator.cgColor)
                        cgContext.setLineWidth(1.0)
                        cgContext.move(to: CGPoint(x: xPosition, y: yPosition))
                        cgContext.addLine(to: CGPoint(x: xPosition, y: yPosition + maxCellHeight))
                        cgContext.strokePath()
                    }
                }

                cgContext.setStrokeColor(UIColor.separator.cgColor)
                cgContext.setLineWidth(1.0)
                cgContext.stroke(rowRect)

                yPosition += maxCellHeight
            }
        }

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "Vika_History_\(Date().timeIntervalSince1970).pdf"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            pdfURL = fileURL
            showShareSheet = true
        } catch {
            print("PDF export error: \(error)")
        }
    }
}

private struct LivePaymentDetailView: View {
    let record: LivePaymentRecord
    @ObservedObject var historyStore: LivePaymentHistoryStore
    let languageCode: String

    @Environment(\.dismiss) private var dismiss

    private func t(_ key: VikaL10n.Key) -> String {
        VikaL10n.t(key, languageCode: languageCode)
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        f.locale = Locale(identifier: languageCode)
        return f
    }

    var body: some View {
        List {
            Section {
                LabeledContent(t(.historyColumnName), value: record.folderName)
                LabeledContent(t(.historyColumnTotal)) {
                    Text(
                        String(
                            format: "%@%.2f",
                            LocaleCurrency.currencySymbol(forCode: record.currencyCode),
                            record.totalPay
                        )
                    )
                    .foregroundStyle(Color.appGreen)
                    .fontWeight(.semibold)
                }
                LabeledContent(t(.historyColumnDate), value: dateFormatter.string(from: record.date))
            }

            Section {
                Toggle(t(.historyMarkPaid), isOn: Binding(
                    get: { historyStore.records.first(where: { $0.id == record.id })?.isPaid ?? record.isPaid },
                    set: { newValue in
                        if let r = historyStore.records.first(where: { $0.id == record.id }) {
                            historyStore.setPaid(newValue, for: r)
                        }
                    }
                ))
                .tint(Color.appGreen)
            }
        }
        .navigationTitle(t(.historyDetailTitle))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(t(.settingsDone)) {
                    dismiss()
                }
                .foregroundStyle(Color.appGreen)
            }
        }
    }
}

