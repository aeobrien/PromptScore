//
//  Paragraph.swift
//  PromptScore
//
//  Created by Aidan O'Brien on 30/05/2025.
//

import Foundation

struct Paragraph: Identifiable, Codable, Equatable {
    let id: UUID
    var sentences: [Sentence]
    
    init(sentences: [Sentence]) {
        self.id = UUID()
        self.sentences = sentences
    }
    
    var fullText: String {
        sentences.map { $0.fullText }.joined(separator: " ")
    }
}