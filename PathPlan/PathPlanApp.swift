//
//  PathPlanApp.swift
//  PathPlan
//
//  Created by Ash on 29/09/2024.
//

import Foundation
import SwiftUI
import SwiftData

@main
struct PathPlanApp: App {
    init() {
        registerTransformer()
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: [Goal.self, Step.self])
    }
    
    private func registerTransformer() {
        let transformer = NSAttributedStringTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: NSValueTransformerName("NSAttributedStringTransformer"))
    }
}

class NSAttributedStringTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSAttributedString.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let attributedString = value as? NSAttributedString else { return nil }
        do {
            return try NSKeyedArchiver.archivedData(withRootObject: attributedString, requiringSecureCoding: true)
        } catch {
            print("Error archiving NSAttributedString: \(error)")
            return nil
        }
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: data)
        } catch {
            print("Error unarchiving NSAttributedString: \(error)")
            return nil
        }
    }
}

