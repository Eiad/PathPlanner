import SwiftUI
import SwiftData

struct AddGoalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(86400 * 30)
    @State private var category: String = ""
    
    let categories = ["Personal", "Work", "Health", "Education", "Finance"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Goal Details")) {
                    TextField("Title", text: $title)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                    
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                }
                
                Section {
                    Button(action: saveGoal) {
                        Text("Save")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .navigationTitle("Add Goal")
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
        }
        .accentColor(.purple)
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