//
//  WordView.swift
//  PromptScore
//
//  Created by Aidan O'Brien on 30/05/2025.
//

import SwiftUI

struct WordView: View {
    let word: Word
    let isSelected: Bool
    let fontSize: CGFloat
    let onTap: () -> Void
    
    init(word: Word, isSelected: Bool, fontSize: CGFloat, onTap: @escaping () -> Void) {
        self.word = word
        self.isSelected = isSelected
        self.fontSize = fontSize
        self.onTap = onTap
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed height annotation area
            HStack(spacing: 2) {
                if !word.annotations.isEmpty {
                    ForEach(word.annotations) { annotation in
                        Text(annotation.symbol)
                            .font(.system(size: fontSize * 0.6))
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text(" ")
                        .font(.system(size: fontSize * 0.6))
                }
            }
            .frame(height: fontSize * 0.8)
            
            Text(word.text)
                .font(textFont)
                .foregroundColor(textColor)
                .reportWordFrame(wordId: word.id, isSelected: isSelected, highlight: word.highlight)
        }
        .onTapGesture {
            onTap()
        }
    }
    
    private var textColor: Color {
        if let highlight = word.highlight {
            // Ensure good contrast for highlighted text
            switch highlight {
            case .blueDark, .greenDark, .orangeDark:
                return .white
            default:
                return .primary
            }
        }
        return .primary
    }
    
    private var hasHighEmphasis: Bool {
        word.annotations.contains { $0.symbol == AnnotationSymbol.highEmphasis.rawValue }
    }
    
    private var hasLowEmphasis: Bool {
        word.annotations.contains { $0.symbol == AnnotationSymbol.lowEmphasis.rawValue }
    }
    
    private var textFont: Font {
        var font = Font.system(size: fontSize)
        
        if hasHighEmphasis {
            font = font.italic()
        }
        
        if hasLowEmphasis {
            font = font.bold()
        }
        
        return font
    }
}