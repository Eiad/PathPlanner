import SwiftUI
import SwiftData

struct AddGoalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var category: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Goal Details")) {
                    TextField("Title", text: $title)
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    TextField("Category", text: $category)
                }
                
                Section {
                    Button("Save") {
                        saveGoal()
                    }
                }
            }
            .navigationTitle("Add Goal")
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
        }
    }

    private func saveGoal() {
        let newGoal = Goal(title: title, startDate: startDate, endDate: endDate, progress: 0.0)
        modelContext.insert(newGoal)
        dismiss()
    }
}

struct AddGoalView_Previews: PreviewProvider {
    static var previews: some View {
        AddGoalView()
            .modelContainer(for: Goal.self, inMemory: true)
    }
}
