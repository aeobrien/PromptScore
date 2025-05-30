//
//  Script.swift
//  PromptScore
//
//  Created by Aidan O'Brien on 30/05/2025.
//

import Foundation

struct Script: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var paragraphs: [Paragraph]
    let createdAt: Date
    var modifiedAt: Date
    
    init(title: String, paragraphs: [Paragraph] = []) {
        self.id = UUID()
        self.title = title
        self.paragraphs = paragraphs
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
    
    var fullText: String {
        paragraphs.map { $0.fullText }.joined(separator: "\n\n")
    }
    
    mutating func updateModifiedDate() {
        self.modifiedAt = Date()
    }
}