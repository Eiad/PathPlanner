import Foundation
import SwiftData

@Model
final class Goal: ObservableObject {
    var id: UUID
    var title: String
    var startDate: Date
    var endDate: Date
    var progress: Double {
        let allSteps = dailySteps + weeklySteps + monthlySteps
        let totalSteps = allSteps.count
        let completedSteps = allSteps.filter { $0.isDone }.count
        
        return totalSteps > 0 ? Double(completedSteps) / Double(totalSteps) : 0.0
    }
    @Relationship(deleteRule: .cascade) var dailySteps: [Step]
    @Relationship(deleteRule: .cascade) var weeklySteps: [Step]
    @Relationship(deleteRule: .cascade) var monthlySteps: [Step]
    var category: String?
    
    init(title: String, startDate: Date, endDate: Date, category: String? = nil) {
        self.id = UUID()
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.category = category
        self.dailySteps = []
        self.weeklySteps = []
        self.monthlySteps = []
    }
    
    var isCompleted: Bool {
        let allSteps = dailySteps + weeklySteps + monthlySteps
        return !allSteps.isEmpty && allSteps.allSatisfy { $0.isDone }
    }
}

@Model
final class Step {
    var id: UUID
    @Attribute(.transformable(by: NSAttributedStringTransformer.self)) var content: NSAttributedString
    var endDate: Date?
    var isDone: Bool
    var goal: Goal?
    
    init(content: NSAttributedString, endDate: Date? = nil, isDone: Bool = false) {
        self.id = UUID()
        self.content = content
        self.endDate = endDate
        self.isDone = isDone
    }
}
