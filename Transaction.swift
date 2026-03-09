import SwiftData
import Foundation
import NaturalLanguage

@Model
class Transaction {
    var id: UUID = UUID()
    var amount: Double
    var merchant: String
    var category: String
    var date: Date
    var rawText: String
    
    init(amount: Double, merchant: String, category: String, date: Date, rawText: String) {
        self.amount = amount
        self.merchant = merchant
        self.category = category
        self.date = date
        self.rawText = rawText
    }
}

extension Date {
    var isInCurrentMonth: Bool {
        let calendar = Calendar.current
        let now = Date()
        return calendar.component(.month, from: self) == calendar.component(.month, from: now) &&
               calendar.component(.year, from: self) == calendar.component(.year, from: now)
    }
}
