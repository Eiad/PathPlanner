//
//  GoalDetailView.swift
//  PathPlan
//
//  Created by Ash on 29/09/2024.
//

import SwiftUI
import SwiftData

struct AttributedText: UIViewRepresentable {
    @Binding var text: NSAttributedString
    @Binding var selectedRange: NSRange
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isSelectable = true
        textView.isEditable = true
        textView.delegate = context.coordinator
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = text
        uiView.selectedRange = selectedRange
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: AttributedText
        
        init(_ parent: AttributedText) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.attributedText
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            parent.selectedRange = textView.selectedRange
        }
    }
}

struct GoalDetailView: View {
    @Bindable var goal: Goal
    @Environment(\.presentationMode) var presentationMode
    @State private var newStep = Step(content: NSAttributedString(string: ""))
    @State private var selectedStepType: StepType = .daily
    @State private var showingStepEditor = false
    @State private var showingGoalEditor = false
    @Environment(\.colorScheme) private var colorScheme
    @State private var refreshID = UUID()

    enum StepType: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(goal.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(goal.category ?? "General Goal")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
                
                dateRangeView
                progressView
                stepsSection
            }
            .padding()
        }
        .navigationTitle("Goal Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingGoalEditor = true
                }
                .foregroundColor(.purple)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .sheet(isPresented: $showingStepEditor) {
            StepEditorView(step: newStep.content) { attributedText, endDate in
                addStep(attributedText: attributedText, endDate: endDate)
            }
        }
        .sheet(isPresented: $showingGoalEditor) {
            GoalEditorView(goal: goal) {
                refreshID = UUID()
            }
        }
    }

    private var dateRangeView: some View {
        HStack {
            dateView(date: goal.startDate, icon: "calendar")
            Spacer()
            dateView(date: goal.endDate, icon: "flag.fill")
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private func dateView(date: Date, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.purple)
            Text(formattedDate(date))
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
    }

    private var progressView: some View {
        VStack(spacing: 8) {
            Text("Progress")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            ProgressView(value: goal.progress)
                .progressViewStyle(RoundedRectProgressViewStyle())
            Text("\(Int(goal.progress * 100))%")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private var stepsSection: some View {
        VStack(spacing: 16) {
            stepRow(title: "Daily Steps", steps: goal.dailySteps, type: .daily)
            stepRow(title: "Weekly Steps", steps: goal.weeklySteps, type: .weekly)
            stepRow(title: "Monthly Steps", steps: goal.monthlySteps, type: .monthly)
        }
    }

    private func stepRow(title: String, steps: [Step], type: StepType) -> some View {
        HStack {
            NavigationLink(destination: StepListView(title: title, goal: goal, stepType: type, refreshID: $refreshID)) {
                HStack {
                    Image(systemName: iconForStepType(type))
                        .font(.system(size: 24))
                        .foregroundColor(colorForStepType(type))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("\(steps.count) steps")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
            }
            Spacer()
            Button(action: {
                selectedStepType = type
                showingStepEditor = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(colorForStepType(type))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private func iconForStepType(_ type: StepType) -> String {
        switch type {
        case .daily:
            return "sun.max"
        case .weekly:
            return "calendar.badge.clock"
        case .monthly:
            return "calendar"
        }
    }

    private func colorForStepType(_ type: StepType) -> Color {
        switch type {
        case .daily:
            return .blue
        case .weekly:
            return .green
        case .monthly:
            return .purple
        }
    }

    private func addStep(attributedText: NSAttributedString, endDate: Date?) {
        guard !attributedText.string.isEmpty else { return }
        
        let newStep = Step(content: attributedText, endDate: endDate)
        
        if let index = goal.dailySteps.firstIndex(where: { $0.id == newStep.id }) {
            goal.dailySteps[index] = newStep
        } else {
            goal.dailySteps.append(newStep)
        }
        
        self.newStep = Step(content: NSAttributedString(string: ""))
        showingStepEditor = false
        self.refreshID = UUID()
    }

    private func convertImageToBase64String(img: UIImage) -> String {
        return img.jpegData(compressionQuality: 0.5)?.base64EncodedString() ?? ""
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
}

struct StepListView: View {
    let title: String
    @ObservedObject var goal: Goal
    let stepType: GoalDetailView.StepType
    @Binding var refreshID: UUID
    @State private var showingAddStep = false

    var steps: [Step] {
        switch stepType {
        case .daily:
            return goal.dailySteps
        case .weekly:
            return goal.weeklySteps
        case .monthly:
            return goal.monthlySteps
        }
    }

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(steps, id: \.id) { step in
                        StepCardView(step: step, goal: goal, refreshID: $refreshID)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddStep = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddStep) {
            StepEditorView(step: NSAttributedString()) { attributedText, endDate in
                addStep(attributedText: attributedText, endDate: endDate)
            }
        }
    }

    private func addStep(attributedText: NSAttributedString, endDate: Date?) {
        let newStep = Step(content: attributedText, endDate: endDate)
        switch stepType {
        case .daily:
            goal.dailySteps.append(newStep)
        case .weekly:
            goal.weeklySteps.append(newStep)
        case .monthly:
            goal.monthlySteps.append(newStep)
        }
        refreshID = UUID()
    }
}

struct StepCardView: View {
    let step: Step
    @ObservedObject var goal: Goal
    @Binding var refreshID: UUID
    @State private var showingStepEditView = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(AttributedString(step.content))
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .lineLimit(2)
                Spacer()
                Button(action: { showingStepEditView = true }) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(.purple)
                        .font(.system(size: 24))
                }
            }

            if let endDate = step.endDate {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                    Text(endDate, style: .date)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showingStepEditView) {
            StepEditorView(step: step.content) { updatedContent, updatedEndDate in
                updateStep(content: updatedContent, endDate: updatedEndDate)
            }
        }
    }

    private func updateStep(content: NSAttributedString, endDate: Date?) {
        step.content = content
        step.endDate = endDate
        refreshID = UUID()
    }
}

struct GoalDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GoalDetailView(goal: Goal(title: "Sample Goal", startDate: Date(), endDate: Date().addingTimeInterval(86400 * 30)))
        }
    }
}

struct StepEditorView: View {
    @State private var attributedText: NSAttributedString
    @State private var endDate: Date?
    @State private var showingDatePicker = false
    @State private var fontSize: CGFloat = 17
    @State private var isBold = false
    @State private var textColor: Color = .primary
    @State private var showingFormatting = false
    @State private var selectedRange: NSRange = NSRange(location: 0, length: 0)
    @Environment(\.presentationMode) var presentationMode
    var onSave: (NSAttributedString, Date?) -> Void

    init(step: NSAttributedString, onSave: @escaping (NSAttributedString, Date?) -> Void) {
        _attributedText = State(initialValue: step)
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                ZStack(alignment: .topLeading) {
                    if attributedText.string.isEmpty {
                        Text("Enter your step details...")
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 12)
                    }
                    AttributedText(text: $attributedText, selectedRange: $selectedRange)
                        .frame(height: 150)
                        .padding(8)
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )

                HStack {
                    Button(action: { showingFormatting.toggle() }) {
                        Image(systemName: "textformat")
                            .foregroundColor(.accentColor)
                    }
                    Spacer()
                    Button(action: { showingDatePicker = true }) {
                        Image(systemName: "calendar")
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.horizontal)

                if showingFormatting {
                    HStack {
                        Button(action: toggleBold) {
                            Image(systemName: "bold")
                                .foregroundColor(isBold ? .accentColor : .primary)
                        }
                        Picker("Size", selection: $fontSize) {
                            Text("S").tag(CGFloat(14))
                            Text("M").tag(CGFloat(17))
                            Text("L").tag(CGFloat(20))
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 120)
                        ColorPicker("", selection: $textColor)
                    }
                    .padding(.horizontal)
                    .transition(.move(edge: .top))
                    .animation(.default, value: showingFormatting)
                }

                if let endDate = endDate {
                    HStack {
                        Text("End Date: \(endDate, style: .date)")
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: { self.endDate = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
            .navigationTitle(attributedText.string.isEmpty ? "Add Step" : "Edit Step")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(attributedText, endDate)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePicker("Select End Date", selection: Binding(
                get: { self.endDate ?? Date() },
                set: { self.endDate = $0 }
            ), displayedComponents: .date)
            .datePickerStyle(GraphicalDatePickerStyle())
            .padding()
            .presentationDetents([.medium])
        }
        .onChange(of: fontSize) { _ in applyFormatting() }
        .onChange(of: isBold) { _ in applyFormatting() }
        .onChange(of: textColor) { _ in applyFormatting() }
    }

    private func toggleBold() {
        isBold.toggle()
        applyFormatting()
    }

    private func applyFormatting() {
        guard selectedRange.location != NSNotFound else { return }
        
        let mutableAttrString = NSMutableAttributedString(attributedString: attributedText)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: isBold ? .bold : .regular),
            .foregroundColor: UIColor(textColor)
        ]
        
        mutableAttrString.addAttributes(attributes, range: selectedRange)
        attributedText = mutableAttrString
    }
}

struct RichTextEditorView: View {
    @Binding var text: NSAttributedString
    @Binding var endDate: Date?
    @State private var showingDatePicker = false
    @State private var selectedRange: NSRange = NSRange(location: 0, length: 0)
    @State private var fontSize: CGFloat = 17
    @State private var isBold = false
    @State private var textColor: Color = .primary
    @State private var showingFormatting = false

    var body: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .topLeading) {
                if text.string.isEmpty {
                    Text("Enter your step details...")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                }
                AttributedText(text: $text, selectedRange: $selectedRange)
                    .frame(height: 150)
                    .padding(8)
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )

            HStack {
                Button(action: { showingFormatting.toggle() }) {
                    Image(systemName: "textformat")
                        .foregroundColor(.accentColor)
                }
                Spacer()
                Button(action: { showingDatePicker = true }) {
                    Image(systemName: "calendar")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)

            if showingFormatting {
                HStack {
                    Button(action: toggleBold) {
                        Image(systemName: "bold")
                            .foregroundColor(isBold ? .accentColor : .primary)
                    }
                    Picker("Size", selection: $fontSize) {
                        Text("S").tag(CGFloat(14))
                        Text("M").tag(CGFloat(17))
                        Text("L").tag(CGFloat(20))
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 120)
                    ColorPicker("", selection: $textColor)
                }
                .padding(.horizontal)
                .transition(.move(edge: .top))
                .animation(.default, value: showingFormatting)
            }

            if let endDate = endDate {
                HStack {
                    Text("End Date: \(endDate, style: .date)")
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: { self.endDate = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePicker("Select End Date", selection: Binding(
                get: { self.endDate ?? Date() },
                set: { self.endDate = $0 }
            ), displayedComponents: .date)
            .datePickerStyle(GraphicalDatePickerStyle())
            .padding()
            .presentationDetents([.medium])
        }
        .onChange(of: fontSize) { _ in applyFormatting() }
        .onChange(of: isBold) { _ in applyFormatting() }
        .onChange(of: textColor) { _ in applyFormatting() }
    }

    private func toggleBold() {
        isBold.toggle()
        applyFormatting()
    }

    private func applyFormatting() {
        guard selectedRange.location != NSNotFound else { return }
        
        let mutableAttrString = NSMutableAttributedString(attributedString: text)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: isBold ? .bold : .regular),
            .foregroundColor: UIColor(textColor)
        ]
        
        mutableAttrString.addAttributes(attributes, range: selectedRange)
        text = mutableAttrString
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct GoalEditorView: View {
    @Bindable var goal: Goal
    @State private var title: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var selectedCategory: String
    @Environment(\.presentationMode) var presentationMode
    var onSave: () -> Void

    let categories = ["Personal", "Work", "Health", "Education", "Finance", "Other"]

    init(goal: Goal, onSave: @escaping () -> Void) {
        self.goal = goal
        _title = State(initialValue: goal.title)
        _startDate = State(initialValue: goal.startDate)
        _endDate = State(initialValue: goal.endDate)
        _selectedCategory = State(initialValue: goal.category ?? "Other")
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Goal Details")) {
                    TextField("Title", text: $title)
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) {
                            Text($0)
                        }
                    }
                    .accentColor(.purple)
                }
            }
            .navigationTitle("Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveGoal()
                        onSave()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    private func saveGoal() {
        goal.title = title
        goal.startDate = startDate
        goal.endDate = endDate
        goal.category = selectedCategory
    }
}