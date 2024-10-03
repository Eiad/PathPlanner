//
//  StepEditView.swift
//  PathPlan
//
//  Created by Ash on 30/09/2024.
//

import Foundation
import SwiftUI

struct StepEditView: View {
    @Binding var step: Step
    @State private var attributedText: NSAttributedString
    @State private var attachedImages: [UIImage] = []
    @State private var endDate: Date?
    @State private var selectedRange: NSRange = NSRange(location: 0, length: 0)
    @State private var isDone: Bool
    var onSave: (Step) -> Void
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) private var modelContext

    init(step: Binding<Step>, onSave: @escaping (Step) -> Void) {
        self._step = step
        self._attributedText = State(initialValue: step.wrappedValue.content)
        self._isDone = State(initialValue: step.wrappedValue.isDone)
        self.onSave = onSave
        self._endDate = State(initialValue: step.wrappedValue.endDate)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Toggle(isOn: $isDone) {
                        Text("Mark as Done")
                            .font(.headline)
                    }
                    .padding()
                    
                    RichTextEditorView(text: $attributedText, endDate: $endDate)
                        .padding()
                }
            }
            .navigationTitle("Edit Step")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        step.content = attributedText
                        step.endDate = endDate
                        step.isDone = isDone
                        onSave(step)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onChange(of: isDone) { oldValue, newValue in
                if let goal = step.goal {
                    if goal.isCompleted {
                        // The progress will be automatically updated by the computed property
                    } else {
                        // The progress will be automatically updated by the computed property
                    }
                    // Trigger an update to the goal
                    goal.objectWillChange.send()
                }
            }
        }
    }
}
