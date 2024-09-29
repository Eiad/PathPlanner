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
    @ObservedObject var goal: Goal
    @State private var newStep = Step(content: NSAttributedString(string: ""))
    @State private var selectedStepType: StepType = .daily
    @State private var showingStepEditor = false
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
                headerView
                dateRangeView
                stepsSection
                addStepSection
            }
            .padding()
        }
        .navigationTitle("Goal Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    // Edit goal action
                }
                .foregroundColor(.purple)
            }
        }
        .background(colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground))
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            Text(goal.title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
        }
    }

    private var dateRangeView: some View {
        Text("Start: \(formattedDate(goal.startDate)) - End: \(formattedDate(goal.endDate))")
            .font(.subheadline)
            .foregroundColor(.secondary)
    }

    private var stepsSection: some View {
        VStack(spacing: 16) {
            stepButton(title: "Daily Steps", steps: goal.dailySteps, type: .daily)
            stepButton(title: "Weekly Steps", steps: goal.weeklySteps, type: .weekly)
            stepButton(title: "Monthly Steps", steps: goal.monthlySteps, type: .monthly)
        }
    }

    private func stepButton(title: String, steps: [Step], type: StepType) -> some View {
        NavigationLink(destination: StepListView(title: title, goal: goal, stepType: type)) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(steps.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
        .id(refreshID)
    }

    private var addStepSection: some View {
        VStack(spacing: 12) {
            Picker("Step Type", selection: $selectedStepType) {
                ForEach(StepType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            Button(action: {
                showingStepEditor = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add New Step")
                }
                .foregroundColor(.purple)
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(10)
            }
        }
        .sheet(isPresented: $showingStepEditor) {
            StepEditorView(step: newStep.content) { attributedText, images, endDate in
                addStep(attributedText: attributedText, images: images, endDate: endDate)
            }
        }
    }

    private func addStep(attributedText: NSAttributedString, images: [UIImage], endDate: Date?) {
        guard !attributedText.string.isEmpty else { return }
        
        let imageStrings = images.map { convertImageToBase64String(img: $0) }
        let fullStepContent = NSMutableAttributedString(attributedString: attributedText)
        for imageString in imageStrings {
            fullStepContent.append(NSAttributedString(string: "\n[IMAGE:\(imageString)]"))
        }
        
        let newStep = Step(content: fullStepContent, endDate: endDate)
        
        switch selectedStepType {
        case .daily:
            goal.dailySteps.append(newStep)
        case .weekly:
            goal.weeklySteps.append(newStep)
        case .monthly:
            goal.monthlySteps.append(newStep)
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
        List {
            ForEach(steps, id: \.id) { step in
                StepView(step: step)
            }
        }
        .navigationTitle(title)
    }
}

struct StepView: View {
    let step: Step
    @State private var selectedImage: UIImage?
    @State private var showingImagePreview = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AttributedString(step.content))
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
            
            if !extractImages(from: step.content).isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(extractImages(from: step.content), id: \.self) { imageData in
                            if let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .onTapGesture {
                                        selectedImage = uiImage
                                        showingImagePreview = true
                                    }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showingImagePreview) {
            if let image = selectedImage {
                ImagePreviewView(image: image)
            }
        }
    }
    
    func extractImages(from content: NSAttributedString) -> [Data] {
        content.string.components(separatedBy: "\n")
            .filter { $0.starts(with: "[IMAGE:") }
            .compactMap { component in
                let start = component.index(component.startIndex, offsetBy: 7)
                let end = component.index(component.endIndex, offsetBy: -1)
                let base64String = String(component[start..<end])
                return Data(base64Encoded: base64String)
            }
    }
}

struct ImagePreviewView: View {
    let image: UIImage
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .navigationBarItems(trailing: Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    })
            }
        }
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
    @State private var attachedImages: [UIImage] = []
    @State private var endDate: Date?
    @State private var selectedRange: NSRange = NSRange(location: 0, length: 0)
    var onSave: (NSAttributedString, [UIImage], Date?) -> Void
    @Environment(\.presentationMode) var presentationMode

    init(step: NSAttributedString, onSave: @escaping (NSAttributedString, [UIImage], Date?) -> Void) {
        _attributedText = State(initialValue: step)
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            ScrollView {
                RichTextEditorView(text: $attributedText, attachedImages: $attachedImages, endDate: $endDate)
                    .padding()
            }
            .navigationTitle("New Step")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(attributedText, attachedImages, endDate)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct RichTextEditorView: View {
    @Binding var text: NSAttributedString
    @Binding var attachedImages: [UIImage]
    @Binding var endDate: Date?
    @State private var showingImagePicker = false
    @State private var showingDatePicker = false
    @State private var inputImage: UIImage?
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
                Button(action: { showingImagePicker = true }) {
                    Image(systemName: "photo")
                        .foregroundColor(.accentColor)
                }
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

            if !attachedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(attachedImages.indices, id: \.self) { index in
                            Image(uiImage: attachedImages[index])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    Button(action: { removeImage(at: index) }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white)
                                            .background(Color.black.opacity(0.7))
                                            .clipShape(Circle())
                                    }
                                    .padding(4),
                                    alignment: .topTrailing
                                )
                        }
                    }
                }
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
        .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
            ImagePicker(image: $inputImage)
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

    private func loadImage() {
        guard let inputImage = inputImage else { return }
        attachedImages.append(inputImage)
    }

    private func removeImage(at index: Int) {
        attachedImages.remove(at: index)
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