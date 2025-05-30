//
//  Sentence.swift
//  PromptScore
//
//  Created by Aidan O'Brien on 30/05/2025.
//

import Foundation

struct Sentence: Identifiable, Codable, Equatable {
    let id: UUID
    var words: [Word]
    var audioClip: URL?
    
    init(words: [Word]) {
        self.id = UUID()
        self.words = words
        self.audioClip = nil
    }
    
    var fullText: String {
        words.map { $0.text }.joined(separator: " ")
    }
}