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
            ZStack {
                VStack(spacing: 0) {
                    headerSection
                    bodySection
                }
                .background(backgroundGradient)
                .ignoresSafeArea(.all, edges: .top)
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        addNewGoalButton
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
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
        VStack(spacing: 16) {
            Text("PathPlan")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Achieve Your Dreams")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
        .padding(.top, 60) 
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
        )
    }
    
    private var bodySection: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    Text("My Goals")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    if goals.isEmpty {
                        encouragingText
                            .frame(height: geometry.size.height - 250) // Adjust this value as needed
                    } else {
                        ForEach(goals) { goal in
                            NavigationLink(destination: GoalDetailView(goal: goal)) {
                                GoalCardView(goal: goal)
                            }
                        }
                    }
                }
                .padding(.bottom)
            }
        }
    }
    
    private var encouragingText: some View {
        VStack(spacing: 24) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.purple)
            
            Text("Ready to achieve greatness?")
                .font(.system(size: 24, weight: .bold, design: .rounded))
            
            Text("Tap the '+' button to add your first goal and start your journey!")
                .font(.system(size: 16, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var addNewGoalButton: some View {
        Button(action: {
            showingAddGoalView = true
        }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]),
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                colorScheme == .dark ? Color(hex: "1A1A1A") : Color(hex: "F0F0F0"),
                colorScheme == .dark ? Color(hex: "2A2A2A") : Color.white
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct GoalCardView: View {
    var goal: Goal
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(goal.title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            ProgressView(value: goal.progress)
                .progressViewStyle(RoundedRectProgressViewStyle())
            
            HStack {
                Label(formatDate(goal.startDate), systemImage: "calendar")
                Spacer()
                Label(formatDate(goal.endDate), systemImage: "flag")
            }
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(hex: "2A2A2A") : .white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

struct RoundedRectProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 14)
                .frame(height: 8)
                .foregroundColor(Color.secondary.opacity(0.2))
            
            RoundedRectangle(cornerRadius: 14)
                .frame(width: CGFloat(configuration.fractionCompleted ?? 0) * 100, height: 8)
                .foregroundColor(.purple)
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
            (a, r, g, b) = (1, 1, 1, 0)
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
