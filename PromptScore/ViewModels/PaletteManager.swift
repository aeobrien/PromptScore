//
//  PaletteManager.swift
//  PromptScore
//
//  Created by Aidan O'Brien on 30/05/2025.
//

import Foundation
import SwiftUI

struct EditableAnnotation: Identifiable, Codable, Equatable {
    let id: UUID
    var symbol: String
    var description: String
    var keyboardShortcut: String?
    let isBuiltIn: Bool
    let originalType: String? // For built-in annotations, stores the AnnotationSymbol case
    
    init(symbol: String, description: String, keyboardShortcut: String? = nil, isBuiltIn: Bool = false, originalType: String? = nil) {
        self.id = UUID()
        self.symbol = symbol
        self.description = description
        self.keyboardShortcut = keyboardShortcut
        self.isBuiltIn = isBuiltIn
        self.originalType = originalType
    }
    
    var shortcutCharacter: Character? {
        keyboardShortcut?.first
    }
}

struct CustomHighlightColor: Identifiable, Codable, Equatable {
    let id: UUID
    var red: Double
    var green: Double
    var blue: Double
    var displayName: String
    
    init(red: Double, green: Double, blue: Double, displayName: String) {
        self.id = UUID()
        self.red = red
        self.green = green
        self.blue = blue
        self.displayName = displayName
    }
    
    var color: Color {
        Color(red: red, green: green, blue: blue)
    }
}

@MainActor
class PaletteManager: ObservableObject {
    @Published var customAnnotations: [CustomAnnotation] = []
    @Published var customColors: [CustomHighlightColor] = []
    @Published var editableAnnotations: [EditableAnnotation] = []
    
    private let annotationsKey = "customAnnotations"
    private let colorsKey = "customColors"
    private let editableAnnotationsKey = "editableAnnotations"
    
    init() {
        load()
    }
    
    func load() {
        // Load custom annotations
        if let data = UserDefaults.standard.data(forKey: annotationsKey),
           let annotations = try? JSONDecoder().decode([CustomAnnotation].self, from: data) {
            customAnnotations = annotations
        }
        
        // Load custom colors
        if let data = UserDefaults.standard.data(forKey: colorsKey),
           let colors = try? JSONDecoder().decode([CustomHighlightColor].self, from: data) {
            customColors = colors
        }
        
        // Load editable annotations or initialize with built-ins
        if let data = UserDefaults.standard.data(forKey: editableAnnotationsKey),
           let annotations = try? JSONDecoder().decode([EditableAnnotation].self, from: data) {
            editableAnnotations = annotations
        } else {
            // Initialize with built-in annotations
            initializeEditableAnnotations()
        }
    }
    
    func save() {
        // Save custom annotations
        if let data = try? JSONEncoder().encode(customAnnotations) {
            UserDefaults.standard.set(data, forKey: annotationsKey)
        }
        
        // Save custom colors
        if let data = try? JSONEncoder().encode(customColors) {
            UserDefaults.standard.set(data, forKey: colorsKey)
        }
        
        // Save editable annotations
        if let data = try? JSONEncoder().encode(editableAnnotations) {
            UserDefaults.standard.set(data, forKey: editableAnnotationsKey)
        }
    }
    
    private func initializeEditableAnnotations() {
        editableAnnotations = []
        
        // Add built-in annotations as editable
        for annotation in AnnotationSymbol.allCases {
            let editable = EditableAnnotation(
                symbol: annotation.rawValue,
                description: annotation.description,
                keyboardShortcut: annotation.keyboardShortcut?.description,
                isBuiltIn: true,
                originalType: String(describing: annotation)
            )
            editableAnnotations.append(editable)
        }
    }
    
    func addCustomAnnotation(symbol: String, description: String, keyboardShortcut: String?) {
        let annotation = EditableAnnotation(
            symbol: symbol,
            description: description,
            keyboardShortcut: keyboardShortcut,
            isBuiltIn: false,
            originalType: nil
        )
        editableAnnotations.append(annotation)
        save()
    }
    
    func removeAnnotation(id: UUID) {
        editableAnnotations.removeAll { $0.id == id }
        save()
    }
    
    // Get all annotations (built-in + custom)
    func getAllAnnotations() -> [(symbol: String, description: String, shortcut: Character?)] {
        return editableAnnotations.map { annotation in
            (symbol: annotation.symbol, description: annotation.description, shortcut: annotation.shortcutCharacter)
        }
    }
    
    // Get all colors (built-in + custom)
    func getAllColors() -> [(color: Color, name: String, index: Int)] {
        var colors: [(color: Color, name: String, index: Int)] = []
        
        // Add built-in colors
        for (index, color) in HighlightColor.allCases.enumerated() {
            colors.append((color: color.color, name: color.displayName, index: index + 1))
        }
        
        // Add custom colors
        for (index, custom) in customColors.enumerated() {
            colors.append((color: custom.color, name: custom.displayName, index: HighlightColor.allCases.count + index + 1))
        }
        
        return colors
    }
}