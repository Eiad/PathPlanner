//
//  HomeView.swift
//  PathPlan
//
//  Created by Ash on 29/09/2024.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var goals: [Goal]
    @State private var showingAddGoalView = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    statisticsSection
                    goalsList
                }
                .padding(.horizontal)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("PathPlan")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.purple)
                        .padding(.top, 20)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddGoalView = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.purple)
                    }
                }
            }
        }
        .accentColor(.purple)
        .sheet(isPresented: $showingAddGoalView) {
            AddGoalView()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Achieve Your Dreams")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Text("Track your progress and stay motivated")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 40)
        .padding(.bottom, 20)
    }
    
    private var statisticsSection: some View {
        HStack(spacing: 15) {
            statisticCard(title: "Total Goals", value: "\(goals.count)", icon: "flag.fill", color: .blue)
            statisticCard(title: "In Progress", value: "\(goalsInProgress)", icon: "arrow.triangle.2.circlepath", color: .orange)
            statisticCard(title: "Completed", value: "\(completedGoals)", icon: "checkmark.circle.fill", color: .green)
        }
    }
    
    private var goalsInProgress: Int {
        goals.filter { !$0.isCompleted }.count
    }
    
    private var completedGoals: Int {
        goals.filter { $0.isCompleted }.count
    }
    
    private var goalsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("My Goals")
                .font(.system(size: 22, weight: .bold, design: .rounded))
            
            if goals.isEmpty {
                emptyStateView
            } else {
                ForEach(goals) { goal in
                    NavigationLink(destination: GoalDetailView(goal: goal)) {
                        GoalCardView(goal: goal)
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.purple)
            
            Text("Ready to achieve greatness?")
                .font(.system(size: 22, weight: .bold, design: .rounded))
            
            Text("Tap the '+' button to add your first goal and start your journey!")
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showingAddGoalView = true }) {
                Text("Add Your First Goal")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.purple)
                    .cornerRadius(8)
            }
            .padding(.top, 10)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func statisticCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct GoalCardView: View {
    var goal: Goal
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(goal.title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                Spacer()
                if goal.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                Text(goal.category ?? "")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(categoryColor(for: goal.category))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            ProgressView(value: goal.progress)
                .progressViewStyle(RoundedRectProgressViewStyle(color: goal.isCompleted ? .green : .purple))
                .frame(height: 8)
            
            HStack {
                Label(formatDate(goal.startDate), systemImage: "calendar")
                Spacer()
                Label(formatDate(goal.endDate), systemImage: "flag")
            }
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color("2A2A2A") : .white)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    func categoryColor(for category: String?) -> Color {
        switch category {
        case "Personal": return .blue
        case "Work": return .orange
        case "Health": return .green
        case "Education": return .purple
        case "Finance": return .red
        default: return .gray
        }
    }
}

struct RoundedRectProgressViewStyle: ProgressViewStyle {
    var color: Color = .purple
    
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 14)
                    .frame(height: 8)
                    .foregroundColor(Color.secondary.opacity(0.2))
                
                RoundedRectangle(cornerRadius: 14)
                    .frame(width: CGFloat(configuration.fractionCompleted ?? 0) * geometry.size.width, height: 8)
                    .foregroundColor(color)
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .modelContainer(for: Goal.self, inMemory: true)
    }
}