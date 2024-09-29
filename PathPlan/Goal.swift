import Foundation
import SwiftData

@Model
final class Goal: ObservableObject {
    var id: UUID
    var title: String
    var startDate: Date
    var endDate: Date
    var progress: Double
    @Relationship(deleteRule: .cascade) var dailySteps: [Step]
    @Relationship(deleteRule: .cascade) var weeklySteps: [Step]
    @Relationship(deleteRule: .cascade) var monthlySteps: [Step]
    
    init(title: String, startDate: Date, endDate: Date, progress: Double = 0.0) {
        self.id = UUID()
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.progress = progress
        self.dailySteps = []
        self.weeklySteps = []
        self.monthlySteps = []
    }
}

@Model
final class Step {
    var id: UUID
    @Attribute(.transformable(by: NSAttributedStringTransformer.self)) var content: NSAttributedString
    var endDate: Date?
    
    init(content: NSAttributedString, endDate: Date? = nil) {
        self.id = UUID()
        self.content = content
        self.endDate = endDate
    }
}
