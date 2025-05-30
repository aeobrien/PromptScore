//
//  CustomAnnotation.swift
//  PromptScore
//
//  Created by Aidan O'Brien on 30/05/2025.
//

import Foundation

struct CustomAnnotation: Identifiable, Codable, Equatable {
    let id: UUID
    var symbol: String
    var description: String
    var keyboardShortcut: String?
    
    init(symbol: String, description: String, keyboardShortcut: String? = nil) {
        self.id = UUID()
        self.symbol = symbol
        self.description = description
        self.keyboardShortcut = keyboardShortcut
    }
    
    var shortcutCharacter: Character? {
        keyboardShortcut?.first
    }
}