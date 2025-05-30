//
//  ScriptEditorView.swift
//  PromptScore
//
//  Created by Aidan O'Brien on 30/05/2025.
//

import SwiftUI
import AVFoundation

// Helper struct for .sheet(item: ...) 
struct IdentifiableSentence: Identifiable {
    let id: UUID
}

struct ScriptEditorView: View {
    @ObservedObject var viewModel: ScriptViewModel
    @StateObject private var paletteManager = PaletteManager()
    @FocusState private var isFocused: Bool
    @State private var fontSize: CGFloat = 36
    @State private var showingDeletePrompt = false
    
    // For tracking word positions for unified selection
    @State private var wordFrames: [WordFrame] = []
    
    // Audio recording
    @State private var activeRecordingSentence: IdentifiableSentence?
    
    var body: some View {
        VStack(spacing: 0) {
            // LIST MODE indicator
            if viewModel.isInListMode {
                HStack {
                    Text("LIST MODE")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red)
                        .cornerRadius(8)
                    Spacer()
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: fontSize * 1.2) {
                if let script = viewModel.script {
                    ForEach(Array(script.paragraphs.enumerated()), id: \.element.id) { pIndex, paragraph in
                        if viewModel.viewMode == .fullParagraph || pIndex == viewModel.currentParagraphIndex {
                            paragraphView(paragraph: paragraph, pIndex: pIndex)
                        }
                    }
                } else {
                    Text("No script loaded. Import a script to begin.")
                        .foregroundColor(.secondary)
                        .padding()
                }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
            }
        }
        .focusable()
        .focused($isFocused)
        .onAppear {
            isFocused = true
        }
        .onKeyPress { keyPress in
            handleKeyPress(keyPress)
        }
        .alert("Clear Formatting", isPresented: $showingDeletePrompt) {
            Button("Clear Annotations") {
                viewModel.clearAnnotationsFromSelectedWords()
            }
            Button("Clear Highlights") {
                viewModel.clearHighlightsFromSelectedWords()
            }
            Button("Clear Both") {
                viewModel.clearAllFormattingFromSelectedWords()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Selected words have both annotations and highlights. What would you like to clear?")
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                HStack {
                    Button(action: { fontSize = max(12, fontSize - 2) }) {
                        Image(systemName: "textformat.size.smaller")
                    }
                    Text("\(Int(fontSize))pt")
                        .font(.system(size: 12, design: .monospaced))
                        .frame(width: 40)
                    Button(action: { fontSize = min(48, fontSize + 2) }) {
                        Image(systemName: "textformat.size.larger")
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func paragraphView(paragraph: Paragraph, pIndex: Int) -> some View {
        ZStack(alignment: .topLeading) {
            // Draw unified highlight rectangles behind all words in the paragraph
            ForEach(wordFrames.calculateUnifiedHighlights()) { highlight in
                RoundedRectangle(cornerRadius: 4)
                    .fill(highlight.color)
                    .frame(width: highlight.rect.width, height: highlight.rect.height)
                    .overlay(
                        highlight.isSelection ?
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.accentColor, lineWidth: 2)
                        : nil
                    )
                    .offset(x: highlight.rect.minX, y: highlight.rect.minY)
                    .allowsHitTesting(false)
            }
            
            // Flow all sentences together in the paragraph
            FlowLayout(horizontalSpacing: 0, verticalSpacing: fontSize * 0.4) {
                ForEach(Array(paragraph.sentences.enumerated()), id: \.element.id) { sIndex, sentence in
                    if viewModel.viewMode == .fullParagraph || 
                       (viewModel.viewMode == .singleSentence && sIndex == viewModel.currentSentenceIndex) {
                        // Audio button at start of sentence
                        Button(action: {
                            activeRecordingSentence = IdentifiableSentence(id: sentence.id)
                        }) {
                            Image(systemName: sentence.audioClip != nil ? "mic.fill" : "mic")
                                .foregroundColor(sentence.audioClip != nil ? .accentColor : .secondary)
                                .font(.system(size: fontSize * 0.7))
                        }
                        .buttonStyle(.plain)
                        .help(sentence.audioClip != nil ? "Audio attached - Click to re-record" : "Record audio reference")
                        
                        // All words in the sentence
                        ForEach(Array(sentence.words.enumerated()), id: \.element.id) { index, word in
                            wordAndSpaceView(word: word, index: index, words: sentence.words)
                        }
                    }
                }
            }
        }
        .coordinateSpace(name: "paragraph")
        .onPreferenceChange(WordFramePreferenceKey.self) { frames in
            wordFrames = frames
        }
        .sheet(item: $activeRecordingSentence) { sentenceWrapper in
            AudioRecordingView(viewModel: viewModel, sentenceId: sentenceWrapper.id)
        }
    }
    
    
    @ViewBuilder
    private func wordAndSpaceView(word: Word, index: Int, words: [Word]) -> some View {
        let nextWord = index + 1 < words.count ? words[index + 1] : nil
        let isPunctuation = nextWord?.text.first?.isPunctuation ?? false
        let needsSpace = !isPunctuation && index < words.count - 1
        
        let isWordSelected = viewModel.selectedWords.contains(word.id)
        
        HStack(spacing: 0) {
            WordView(
                word: word,
                isSelected: isWordSelected,
                fontSize: fontSize,
                onTap: {
                    viewModel.handleWordTap(word.id)
                }
            )
            
            if needsSpace {
                Text(" ")
                    .font(.system(size: fontSize))
                    .opacity(0)
            }
        }
    }
    
    
    private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        print("Key pressed: \(keyPress.key), characters: '\(keyPress.characters)', modifiers: \(keyPress.modifiers)")
        
        switch keyPress.key {
        case .rightArrow:
            if keyPress.modifiers.contains(.shift) {
                viewModel.modifySelection(direction: .right)
            } else {
                viewModel.navigateToNextWord()
            }
            return .handled
        case .leftArrow:
            if keyPress.modifiers.contains(.shift) {
                viewModel.modifySelection(direction: .left)
            } else {
                viewModel.navigateToPreviousWord()
            }
            return .handled
        case .space:
            viewModel.navigateToNextWord()
            return .handled
        case .escape:
            if viewModel.isInListMode {
                viewModel.exitListMode()
            } else {
                viewModel.clearSelection()
            }
            return .handled
        case .delete, .deleteForward:
            if !viewModel.selectedWords.isEmpty {
                let hasAnnotations = viewModel.selectedWordsHaveAnnotations()
                let hasHighlights = viewModel.selectedWordsHaveHighlights()
                
                if hasAnnotations && hasHighlights {
                    showingDeletePrompt = true
                } else if hasAnnotations {
                    viewModel.clearAnnotationsFromSelectedWords()
                } else if hasHighlights {
                    viewModel.clearHighlightsFromSelectedWords()
                }
                return .handled
            }
            return .ignored
        default:
            if let character = keyPress.characters.first {
                print("Processing character: '\(character)' with modifiers: \(keyPress.modifiers)")
                // Handle backspace/delete characters
                if character == "\u{8}" || character == "\u{7F}" { // Backspace (BS) or Delete (DEL)
                    if !viewModel.selectedWords.isEmpty {
                        let hasAnnotations = viewModel.selectedWordsHaveAnnotations()
                        let hasHighlights = viewModel.selectedWordsHaveHighlights()
                        
                        if hasAnnotations && hasHighlights {
                            showingDeletePrompt = true
                        } else if hasAnnotations {
                            viewModel.clearAnnotationsFromSelectedWords()
                        } else if hasHighlights {
                            viewModel.clearHighlightsFromSelectedWords()
                        }
                        return .handled
                    }
                    return .ignored
                }
                
                // Check built-in annotations first
                // Convert to lowercase for comparison since Shift makes characters uppercase
                let lowercaseChar = character.lowercased().first
                if let annotation = AnnotationSymbol.allCases.first(where: { $0.keyboardShortcut == lowercaseChar }) {
                    if annotation == .list {
                        if viewModel.isInListMode {
                            // Apply next list number
                            viewModel.applyListAnnotation()
                        } else {
                            // Enter list mode and apply L1
                            viewModel.enterListMode()
                            viewModel.applyListAnnotation()
                        }
                    } else {
                        // Exit list mode if applying a different annotation
                        if viewModel.isInListMode {
                            viewModel.exitListMode()
                        }
                        let append = keyPress.modifiers.contains(.shift)
                        viewModel.addAnnotationToSelectedWords(symbol: annotation.rawValue, append: append)
                    }
                    return .handled
                }
                
                // Check all editable annotations (built-in + custom)
                for annotation in paletteManager.editableAnnotations {
                    // Compare lowercase to handle Shift key
                    if annotation.shortcutCharacter == lowercaseChar && !annotation.isBuiltIn {
                        // Exit list mode if applying a different annotation
                        if viewModel.isInListMode {
                            viewModel.exitListMode()
                        }
                        let append = keyPress.modifiers.contains(.shift)
                        viewModel.addAnnotationToSelectedWords(symbol: annotation.symbol, append: append)
                        return .handled
                    }
                }
                
                // Handle number keys for highlight colors
                if let number = Int(String(character)) {
                    if number >= 1 && number <= 6 {
                        // Built-in colors (1-6)
                        viewModel.setHighlightForSelectedWords(color: HighlightColor.allCases[number - 1])
                        return .handled
                    }
                    // Note: Custom colors would need a different approach since we can't store them in the Word model
                    // which only accepts HighlightColor enum values
                }
                
                // Handle 0 to remove highlight
                if character == "0" {
                    viewModel.setHighlightForSelectedWords(color: nil)
                    return .handled
                }
            }
            return .ignored
        }
    }
}

struct FlowLayout: Layout {
    var horizontalSpacing: CGFloat = 4
    var verticalSpacing: CGFloat = 4
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: result.positions[index].x + bounds.minX,
                                    y: result.positions[index].y + bounds.minY),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, horizontalSpacing: CGFloat, verticalSpacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + verticalSpacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                x += size.width + horizontalSpacing
                lineHeight = max(lineHeight, size.height)
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}