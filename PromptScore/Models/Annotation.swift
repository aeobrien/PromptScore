//
//  Annotation.swift
//  PromptScore
//
//  Created by Aidan O'Brien on 30/05/2025.
//

import Foundation

struct Annotation: Identifiable, Codable, Equatable {
    let id = UUID()
    let symbol: String
    let createdAt: Date
    
    init(symbol: String) {
        self.symbol = symbol
        self.createdAt = Date()
    }
}

enum AnnotationSymbol: String, CaseIterable {
    case highPitch = "↑"
    case lowPitch = "↓"
    case lowToHigh = "↗︎"
    case highToLow = "↘︎"
    case highEmphasis = "●"
    case lowEmphasis = "○"
    case pause = "_"
    case airQuotes = "\"\""
    case list = "L"
    
    var description: String {
        switch self {
        case .highPitch:
            return "High pitch"
        case .lowPitch:
            return "Low pitch"
        case .lowToHigh:
            return "Low to high"
        case .highToLow:
            return "High to low"
        case .highEmphasis:
            return "High emphasis"
        case .lowEmphasis:
            return "Low emphasis"
        case .pause:
            return "Pause"
        case .airQuotes:
            return "Air quotes"
        case .list:
            return "List item"
        }
    }
    
    var keyboardShortcut: Character? {
        switch self {
        case .highPitch:
            return "h"
        case .lowPitch:
            return "l"
        case .lowToHigh:
            return "u"
        case .highToLow:
            return "d"
        case .highEmphasis:
            return "e"
        case .lowEmphasis:
            return "w"
        case .pause:
            return "p"
        case .airQuotes:
            return "q"
        case .list:
            return "t"
        }
    }
}