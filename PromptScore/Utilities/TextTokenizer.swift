//
//  TextTokenizer.swift
//  PromptScore
//
//  Created by Aidan O'Brien on 30/05/2025.
//

import Foundation
import NaturalLanguage

class TextTokenizer {
    static func tokenizeScript(from text: String) -> Script {
        let paragraphs = tokenizeParagraphs(from: text)
        return Script(title: "Untitled Script", paragraphs: paragraphs)
    }
    
    static func tokenizeParagraphs(from text: String) -> [Paragraph] {
        let paragraphStrings = text.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        return paragraphStrings.map { paragraphString in
            let sentences = tokenizeSentences(from: paragraphString)
            return Paragraph(sentences: sentences)
        }
    }
    
    static func tokenizeSentences(from text: String) -> [Sentence] {
        var sentences: [Sentence] = []
        
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { sentenceRange, _ in
            let sentenceText = String(text[sentenceRange])
            let words = tokenizeWords(from: sentenceText)
            if !words.isEmpty {
                sentences.append(Sentence(words: words))
            }
            return true
        }
        
        return sentences
    }
    
    static func tokenizeWords(from text: String) -> [Word] {
        var words: [Word] = []
        
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        
        var lastWordIndex: Int? = nil
        
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { wordRange, _ in
            let wordText = String(text[wordRange])
            words.append(Word(text: wordText))
            lastWordIndex = words.count - 1
            return true
        }
        
        // Now go through the text again to find punctuation and attach it to preceding words
        var processedIndex = text.startIndex
        
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { wordRange, _ in
            // Check for punctuation after this word
            var checkIndex = wordRange.upperBound
            var punctuation = ""
            
            while checkIndex < text.endIndex {
                let char = text[checkIndex]
                if char.isWhitespace {
                    break
                } else if char.isPunctuation || char == "'" || char == "\u{201C}" || char == "\u{201D}" {
                    punctuation.append(char)
                    checkIndex = text.index(after: checkIndex)
                } else {
                    break
                }
            }
            
            // Find the word in our array that corresponds to this range
            if !punctuation.isEmpty {
                for (index, word) in words.enumerated() {
                    if word.text == String(text[wordRange]) {
                        // Found the matching word, append punctuation
                        words[index] = Word(text: word.text + punctuation)
                        break
                    }
                }
            }
            
            processedIndex = wordRange.upperBound
            return true
        }
        
        // Remove any standalone punctuation words
        words = words.filter { word in
            !word.text.allSatisfy { $0.isPunctuation || $0.isWhitespace }
        }
        
        return words
    }
}