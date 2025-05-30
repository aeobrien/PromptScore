//
//  Word.swift
//  PromptScore
//
//  Created by Aidan O'Brien on 30/05/2025.
//

import Foundation

struct Word: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    var annotations: [Annotation]
    var highlight: HighlightColor?
    var audioTimestamps: (start: TimeInterval, end: TimeInterval)?
    
    static func == (lhs: Word, rhs: Word) -> Bool {
        lhs.id == rhs.id &&
        lhs.text == rhs.text &&
        lhs.annotations == rhs.annotations &&
        lhs.highlight == rhs.highlight &&
        lhs.audioTimestamps?.start == rhs.audioTimestamps?.start &&
        lhs.audioTimestamps?.end == rhs.audioTimestamps?.end
    }
    
    init(text: String) {
        self.id = UUID()
        self.text = text
        self.annotations = []
        self.highlight = nil
        self.audioTimestamps = nil
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, text, annotations, highlight, audioStart, audioEnd
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        annotations = try container.decode([Annotation].self, forKey: .annotations)
        highlight = try container.decodeIfPresent(HighlightColor.self, forKey: .highlight)
        
        if let start = try container.decodeIfPresent(TimeInterval.self, forKey: .audioStart),
           let end = try container.decodeIfPresent(TimeInterval.self, forKey: .audioEnd) {
            audioTimestamps = (start: start, end: end)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(annotations, forKey: .annotations)
        try container.encodeIfPresent(highlight, forKey: .highlight)
        try container.encodeIfPresent(audioTimestamps?.start, forKey: .audioStart)
        try container.encodeIfPresent(audioTimestamps?.end, forKey: .audioEnd)
    }
}