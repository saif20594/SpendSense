import SwiftUI
import SwiftData
import Charts

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    @State private var inputText = ""
    @State private var showingExport = false
    
    private let parser = TransactionParser()
    
    var monthlyTotal: Double {
        transactions.filter { $0.date.isInCurrentMonth }.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Paste Message Text")
                        .font(.headline)
                    TextEditor(text: $inputText)
                        .frame(height: 100)
                        .border(Color.gray.opacity(0.3))
                        .cornerRadius(8)
                    Button("Parse & Add Transactions") {
                        addTransactions()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(inputText.isEmpty)
                }
                .padding()
                
                VStack(alignment: .leading) {
                    Text("This Month's Spend: $\(monthlyTotal, specifier: "%.2f")")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if !monthlyTransactions.isEmpty {
                        Chart {
                            ForEach(monthlyTransactions) { transaction in
                                BarMark(
                                    x: .value("Date", Calendar.current.component(.day, from: transaction.date)),
                                    y: .value("Amount", transaction.amount)
                                )
                            }
                        }
                        .frame(height: 200)
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                    } else {
                        Text("No transactions yet. Paste a message to start! 📱")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("SpendSense")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export CSV") {
                        showingExport = true
                    }
                    .disabled(transactions.isEmpty)
                }
            }
            .sheet(isPresented: $showingExport) {
                ExportView(transactions: transactions)
            }
        }
    }
    
    private var monthlyTransactions: [Transaction] {
        transactions.filter { $0.date.isInCurrentMonth }.sorted { $0.date < $1.date }
    }
    
    private func addTransactions() {
        let newTransactions = parser.parse(inputText)
        for transaction in newTransactions {
            modelContext.insert(transaction)
        }
        try? modelContext.save()
        inputText = ""
    }
}

struct ExportView: View {
    let transactions: [Transaction]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List(transactions, id: \.id) { transaction in
                VStack(alignment: .leading) {
                    Text("\(transaction.merchant): $\(transaction.amount, specifier: "%.2f")")
                    Text(transaction.rawText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Export Preview")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Copy CSV") {
                        let csv = generateCSV()
                        UIPasteboard.general.string = csv
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func generateCSV() -> String {
        var csv = "Date,Merchant,Amount,Category\n"
        for transaction in transactions {
            let dateString = DateFormatter.localizedString(from: transaction.date, dateStyle: .short, timeStyle: .none)
            csv += "\"\(dateString)\",\"\(transaction.merchant)\",\(transaction.amount),\"\(transaction.category)\"\n"
        }
        return csv
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Transaction.self)
}
