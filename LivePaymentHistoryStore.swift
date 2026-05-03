//
//  LivePaymentHistoryStore.swift
//  Vika
//

import Foundation
import Combine

struct LivePaymentRecord: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var folderName: String
    var totalPay: Double
    var duration: TimeInterval
    /// Session end time (used for sorting and display).
    var date: Date
    var currencyCode: String
    var startTime: Date
    var endTime: Date
    var hourlyRate: Double
    var otherPays: Double
    var isPaid: Bool

    init(
        id: UUID = UUID(),
        folderName: String,
        totalPay: Double,
        duration: TimeInterval,
        date: Date,
        currencyCode: String,
        startTime: Date,
        endTime: Date,
        hourlyRate: Double,
        otherPays: Double,
        isPaid: Bool = false
    ) {
        self.id = id
        self.folderName = folderName
        self.totalPay = totalPay
        self.duration = duration
        self.date = date
        self.currencyCode = currencyCode
        self.startTime = startTime
        self.endTime = endTime
        self.hourlyRate = hourlyRate
        self.otherPays = otherPays
        self.isPaid = isPaid
    }
}

@MainActor
final class LivePaymentHistoryStore: ObservableObject {
    @Published private(set) var records: [LivePaymentRecord] = []

    private let userId: String
    private var storageKey: String { "vika.livePaymentHistory.\(userId)" }

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    init(userId: String) {
        self.userId = userId
        loadRecords()
    }

    func loadRecords() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? decoder.decode([LivePaymentRecord].self, from: data) else {
            records = []
            return
        }
        records = decoded
    }

    func add(_ record: LivePaymentRecord) {
        records.insert(record, at: 0)
        persist()
    }

    func deleteRecord(_ record: LivePaymentRecord) {
        records.removeAll { $0.id == record.id }
        persist()
    }

    func setPaid(_ paid: Bool, for record: LivePaymentRecord) {
        guard let idx = records.firstIndex(where: { $0.id == record.id }) else { return }
        records[idx].isPaid = paid
        persist()
    }

    private func persist() {
        guard let data = try? encoder.encode(records) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
