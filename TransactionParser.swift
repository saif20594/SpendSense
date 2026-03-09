import Foundation
import NaturalLanguage

class TransactionParser {
    private let amountRegex = try! Regex(#"(?:\$|₹|€|£)?\s?(\d+(?:[.,]\d{2})?)"#)
    
    func parse(_ text: String) -> [Transaction] {
        var transactions: [Transaction] = []
        
        let matches = try? amountRegex.matches(in: text)
        for match in matches ?? [] {
            guard let amountGroup = match.output[1],
                  let amountString = String(text[amountGroup]).replacingOccurrences(of: ",", with: ""),
                  let amount = Double(amountString) else { continue }
            
            let merchant = extractMerchant(from: text)
            let date = Date()
            let category = categorize(text)
            
            let transaction = Transaction(
                amount: amount,
                merchant: merchant,
                category: category,
                date: date,
                rawText: text
            )
            transactions.append(transaction)
        }
        return transactions
    }
    
    private func extractMerchant(from text: String) -> String {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        var merchant = "Unknown"
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, range in
            if tag == .organizationName {
                merchant = String(text[range])
                return false
            }
            return true
        }
        return merchant
    }
    
    private func categorize(_ text: String) -> String {
        let lowerText = text.lowercased()
        if lowerText.contains("uber") || lowerText.contains("lyft") { return "Transport" }
        if lowerText.contains("starbucks") || lowerText.contains("food") { return "Dining" }
        if lowerText.contains("amazon") || lowerText.contains("order") { return "Shopping" }
        return "Other"
    }
}
