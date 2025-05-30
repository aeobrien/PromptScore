//
//  ScriptViewModel.swift
//  PromptScore
//
//  Created by Aidan O'Brien on 30/05/2025.
//

import Foundation
import SwiftUI

@MainActor
class ScriptViewModel: ObservableObject {
    @Published var script: Script?
    @Published var selectedWords: Set<UUID> = []
    @Published var viewMode: ViewMode = .fullParagraph
    @Published var currentSentenceIndex: Int = 0
    @Published var currentParagraphIndex: Int = 0
    
    // Track the selection anchor and direction
    private var selectionAnchor: UUID?
    private var selectionHead: UUID?
    
    // List mode tracking
    @Published var isInListMode = false
    private var listCounter = 1
    
    enum ViewMode {
        case fullParagraph
        case singleSentence
    }
    
    enum SelectionDirection {
        case left, right
    }
    
    func importText(_ text: String) {
        script = TextTokenizer.tokenizeScript(from: text)
        if let firstWord = script?.paragraphs.first?.sentences.first?.words.first {
            selectedWords = [firstWord.id]
            selectionAnchor = firstWord.id
            selectionHead = firstWord.id
        }
    }
    
    func handleWordTap(_ wordId: UUID) {
        // TODO: Handle shift+click for extending selection
        selectedWords = [wordId]
        selectionAnchor = wordId
        selectionHead = wordId
        updateCurrentIndices(for: wordId)
    }
    
    func clearSelection() {
        // Keep only the first word in the ordered selection
        let orderedSelection = getOrderedSelection()
        if let firstWord = orderedSelection.first {
            selectedWords = [firstWord.id]
            selectionAnchor = firstWord.id
            selectionHead = firstWord.id
            updateCurrentIndices(for: firstWord.id)
        }
    }
    
    func exitListMode() {
        isInListMode = false
        listCounter = 1
    }
    
    func enterListMode() {
        isInListMode = true
        listCounter = 1
    }
    
    func applyListAnnotation() {
        let listSymbol = "L\(listCounter)"
        addAnnotationToSelectedWords(symbol: listSymbol, append: false)
        listCounter += 1
    }
    
    func navigateToNextWord() {
        guard let script = script else { return }
        
        if selectedWords.count == 1 {
            // Single word selected - move to next
            guard let currentId = selectedWords.first else { return }
            
            var foundCurrent = false
            for (pIndex, paragraph) in script.paragraphs.enumerated() {
                for (sIndex, sentence) in paragraph.sentences.enumerated() {
                    for word in sentence.words {
                        if foundCurrent {
                            selectedWords = [word.id]
                            selectionAnchor = word.id
                            selectionHead = word.id
                            currentParagraphIndex = pIndex
                            currentSentenceIndex = sIndex
                            return
                        }
                        if word.id == currentId {
                            foundCurrent = true
                        }
                    }
                }
            }
        } else {
            // Multiple words selected - shift the selection right by one word
            let orderedSelection = getOrderedSelection()
            guard let firstWord = orderedSelection.first else { return }
            
            // Find the word after the first selected word
            var foundFirst = false
            var newSelectionStart: UUID?
            
            for paragraph in script.paragraphs {
                for sentence in paragraph.sentences {
                    for word in sentence.words {
                        if foundFirst {
                            newSelectionStart = word.id
                            break
                        }
                        if word.id == firstWord.id {
                            foundFirst = true
                        }
                    }
                    if newSelectionStart != nil { break }
                }
                if newSelectionStart != nil { break }
            }
            
            // Build new selection starting from the new start
            if let startId = newSelectionStart {
                var newSelection: [UUID] = []
                var collecting = false
                var count = 0
                
                for paragraph in script.paragraphs {
                    for sentence in paragraph.sentences {
                        for word in sentence.words {
                            if word.id == startId {
                                collecting = true
                            }
                            if collecting {
                                newSelection.append(word.id)
                                count += 1
                                if count == selectedWords.count {
                                    selectedWords = Set(newSelection)
                                    selectionAnchor = newSelection.first
                                    selectionHead = newSelection.last
                                    return
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func navigateToPreviousWord() {
        guard let script = script else { return }
        
        if selectedWords.count == 1 {
            // Single word selected - move to previous
            guard let currentId = selectedWords.first else { return }
            
            var previousWordId: UUID?
            var prevParagraphIndex = 0
            var prevSentenceIndex = 0
            
            for (pIndex, paragraph) in script.paragraphs.enumerated() {
                for (sIndex, sentence) in paragraph.sentences.enumerated() {
                    for word in sentence.words {
                        if word.id == currentId {
                            if let prevId = previousWordId {
                                selectedWords = [prevId]
                                selectionAnchor = prevId
                                selectionHead = prevId
                                currentParagraphIndex = prevParagraphIndex
                                currentSentenceIndex = prevSentenceIndex
                            }
                            return
                        }
                        previousWordId = word.id
                        prevParagraphIndex = pIndex
                        prevSentenceIndex = sIndex
                    }
                }
            }
        } else {
            // Multiple words selected - shift the selection left by one word
            let orderedSelection = getOrderedSelection()
            guard let firstWord = orderedSelection.first else { return }
            
            // Find the word before the first selected word
            var previousWord: UUID?
            
            for paragraph in script.paragraphs {
                for sentence in paragraph.sentences {
                    for word in sentence.words {
                        if word.id == firstWord.id {
                            if let prevId = previousWord {
                                // Build new selection starting from previous word
                                var newSelection: [UUID] = []
                                var collecting = false
                                var count = 0
                                
                                for p in script.paragraphs {
                                    for s in p.sentences {
                                        for w in s.words {
                                            if w.id == prevId {
                                                collecting = true
                                            }
                                            if collecting {
                                                newSelection.append(w.id)
                                                count += 1
                                                if count == selectedWords.count {
                                                    selectedWords = Set(newSelection)
                                                    selectionAnchor = newSelection.first
                                                    selectionHead = newSelection.last
                                                    return
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            return
                        }
                        previousWord = word.id
                    }
                }
            }
        }
    }
    
    func modifySelection(direction: SelectionDirection) {
        guard let script = script,
              let anchor = selectionAnchor,
              let head = selectionHead else { return }
        
        // Find next/previous word relative to head
        var newHead: UUID?
        
        if direction == .right {
            var foundHead = false
            for paragraph in script.paragraphs {
                for sentence in paragraph.sentences {
                    for word in sentence.words {
                        if foundHead {
                            newHead = word.id
                            break
                        }
                        if word.id == head {
                            foundHead = true
                        }
                    }
                    if newHead != nil { break }
                }
                if newHead != nil { break }
            }
        } else {
            var previousWord: UUID?
            for paragraph in script.paragraphs {
                for sentence in paragraph.sentences {
                    for word in sentence.words {
                        if word.id == head {
                            newHead = previousWord
                            break
                        }
                        previousWord = word.id
                    }
                    if newHead != nil { break }
                }
                if newHead != nil { break }
            }
        }
        
        if let newHead = newHead {
            // Update selection based on anchor and new head
            
            // Special case: if anchor and newHead are the same, select just that word
            if anchor == newHead {
                selectedWords = [anchor]
                selectionHead = newHead
                return
            }
            
            var newSelection: Set<UUID> = []
            var collecting = false
            var passedAnchor = false
            var passedNewHead = false
            
            for paragraph in script.paragraphs {
                for sentence in paragraph.sentences {
                    for word in sentence.words {
                        let isAnchor = word.id == anchor
                        let isNewHead = word.id == newHead
                        
                        if isAnchor {
                            passedAnchor = true
                            newSelection.insert(word.id)
                            if passedNewHead {
                                collecting = false
                            } else {
                                collecting = true
                            }
                        } else if isNewHead {
                            passedNewHead = true
                            newSelection.insert(word.id)
                            if passedAnchor {
                                collecting = false
                            } else {
                                collecting = true
                            }
                        } else if collecting {
                            newSelection.insert(word.id)
                        }
                    }
                }
            }
            
            selectedWords = newSelection
            selectionHead = newHead
        }
    }
    
    func addAnnotationToSelectedWords(symbol: String, append: Bool = false) {
        guard var script = script else { return }
        
        for wordId in selectedWords {
            for pIndex in script.paragraphs.indices {
                for sIndex in script.paragraphs[pIndex].sentences.indices {
                    for wIndex in script.paragraphs[pIndex].sentences[sIndex].words.indices {
                        if script.paragraphs[pIndex].sentences[sIndex].words[wIndex].id == wordId {
                            let annotation = Annotation(symbol: symbol)
                            if append {
                                script.paragraphs[pIndex].sentences[sIndex].words[wIndex].annotations.append(annotation)
                            } else {
                                // Overwrite - clear existing annotations first
                                script.paragraphs[pIndex].sentences[sIndex].words[wIndex].annotations = [annotation]
                            }
                        }
                    }
                }
            }
        }
        
        script.updateModifiedDate()
        self.script = script
        
        // Clear selection to first word after applying annotation
        clearSelection()
    }
    
    func setHighlightForSelectedWords(color: HighlightColor?) {
        guard var script = script else { return }
        
        for wordId in selectedWords {
            for pIndex in script.paragraphs.indices {
                for sIndex in script.paragraphs[pIndex].sentences.indices {
                    for wIndex in script.paragraphs[pIndex].sentences[sIndex].words.indices {
                        if script.paragraphs[pIndex].sentences[sIndex].words[wIndex].id == wordId {
                            script.paragraphs[pIndex].sentences[sIndex].words[wIndex].highlight = color
                        }
                    }
                }
            }
        }
        
        script.updateModifiedDate()
        self.script = script
        
        // Clear selection to first word after applying highlight
        clearSelection()
    }
    
    func removeAnnotation(from wordId: UUID, annotationId: UUID) {
        guard var script = script else { return }
        
        for pIndex in script.paragraphs.indices {
            for sIndex in script.paragraphs[pIndex].sentences.indices {
                for wIndex in script.paragraphs[pIndex].sentences[sIndex].words.indices {
                    if script.paragraphs[pIndex].sentences[sIndex].words[wIndex].id == wordId {
                        script.paragraphs[pIndex].sentences[sIndex].words[wIndex].annotations.removeAll { $0.id == annotationId }
                        script.updateModifiedDate()
                        self.script = script
                        return
                    }
                }
            }
        }
    }
    
    func clearAnnotationsFromSelectedWords() {
        guard var script = script else { return }
        
        for wordId in selectedWords {
            for pIndex in script.paragraphs.indices {
                for sIndex in script.paragraphs[pIndex].sentences.indices {
                    for wIndex in script.paragraphs[pIndex].sentences[sIndex].words.indices {
                        if script.paragraphs[pIndex].sentences[sIndex].words[wIndex].id == wordId {
                            script.paragraphs[pIndex].sentences[sIndex].words[wIndex].annotations.removeAll()
                        }
                    }
                }
            }
        }
        
        script.updateModifiedDate()
        self.script = script
    }
    
    func clearHighlightsFromSelectedWords() {
        guard var script = script else { return }
        
        for wordId in selectedWords {
            for pIndex in script.paragraphs.indices {
                for sIndex in script.paragraphs[pIndex].sentences.indices {
                    for wIndex in script.paragraphs[pIndex].sentences[sIndex].words.indices {
                        if script.paragraphs[pIndex].sentences[sIndex].words[wIndex].id == wordId {
                            script.paragraphs[pIndex].sentences[sIndex].words[wIndex].highlight = nil
                        }
                    }
                }
            }
        }
        
        script.updateModifiedDate()
        self.script = script
    }
    
    func clearAllFormattingFromSelectedWords() {
        clearAnnotationsFromSelectedWords()
        clearHighlightsFromSelectedWords()
    }
    
    func selectedWordsHaveAnnotations() -> Bool {
        guard let script = script else { return false }
        
        for wordId in selectedWords {
            for paragraph in script.paragraphs {
                for sentence in paragraph.sentences {
                    for word in sentence.words {
                        if word.id == wordId && !word.annotations.isEmpty {
                            return true
                        }
                    }
                }
            }
        }
        return false
    }
    
    func selectedWordsHaveHighlights() -> Bool {
        guard let script = script else { return false }
        
        for wordId in selectedWords {
            for paragraph in script.paragraphs {
                for sentence in paragraph.sentences {
                    for word in sentence.words {
                        if word.id == wordId && word.highlight != nil {
                            return true
                        }
                    }
                }
            }
        }
        return false
    }
    
    func attachAudioToSentence(sentenceId: UUID, audioURL: URL) {
        guard var script = script else { return }
        
        // Copy audio to app's documents directory with a stable name
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsPath.appendingPathComponent("audio_\(sentenceId).m4a")
        
        do {
            // Remove existing audio if any
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // Copy new audio
            try FileManager.default.copyItem(at: audioURL, to: destinationURL)
            
            // Update sentence with audio reference
            for pIndex in script.paragraphs.indices {
                for sIndex in script.paragraphs[pIndex].sentences.indices {
                    if script.paragraphs[pIndex].sentences[sIndex].id == sentenceId {
                        script.paragraphs[pIndex].sentences[sIndex].audioClip = destinationURL
                        script.updateModifiedDate()
                        self.script = script
                        return
                    }
                }
            }
        } catch {
            print("Failed to attach audio: \(error)")
        }
    }
    
    private func updateCurrentIndices(for wordId: UUID) {
        guard let script = script else { return }
        
        for (pIndex, paragraph) in script.paragraphs.enumerated() {
            for (sIndex, sentence) in paragraph.sentences.enumerated() {
                for word in sentence.words {
                    if word.id == wordId {
                        currentParagraphIndex = pIndex
                        currentSentenceIndex = sIndex
                        return
                    }
                }
            }
        }
    }
    
    func getOrderedSelection() -> [Word] {
        guard let script = script else { return [] }
        
        var orderedWords: [Word] = []
        
        for paragraph in script.paragraphs {
            for sentence in paragraph.sentences {
                for word in sentence.words {
                    if selectedWords.contains(word.id) {
                        orderedWords.append(word)
                    }
                }
            }
        }
        
        return orderedWords
    }
}