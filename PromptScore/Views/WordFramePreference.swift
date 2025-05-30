//
//  WordFramePreference.swift
//  PromptScore
//
//  Created by Aidan O'Brien on 30/05/2025.
//

import SwiftUI

// Structure to hold word frame information
struct WordFrame: Equatable {
    let id: UUID
    let frame: CGRect
    let isSelected: Bool
    let highlight: HighlightColor?
}

// PreferenceKey to collect word frames
struct WordFramePreferenceKey: PreferenceKey {
    static var defaultValue: [WordFrame] = []
    
    static func reduce(value: inout [WordFrame], nextValue: () -> [WordFrame]) {
        value.append(contentsOf: nextValue())
    }
}

// Helper view modifier to report word frames
struct WordFrameModifier: ViewModifier {
    let wordId: UUID
    let isSelected: Bool
    let highlight: HighlightColor?
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: WordFramePreferenceKey.self,
                            value: [WordFrame(
                                id: wordId,
                                frame: geometry.frame(in: .named("paragraph")),
                                isSelected: isSelected,
                                highlight: highlight
                            )]
                        )
                }
            )
    }
}

// Extension for easier use
extension View {
    func reportWordFrame(wordId: UUID, isSelected: Bool, highlight: HighlightColor?) -> some View {
        self.modifier(WordFrameModifier(wordId: wordId, isSelected: isSelected, highlight: highlight))
    }
}

// Helper enum for highlight types
enum HighlightType: Equatable {
    case selection
    case highlight(HighlightColor)
}

// Structure to represent a unified highlight rectangle
struct UnifiedHighlight: Identifiable {
    let id = UUID()
    let rect: CGRect
    let color: Color
    let isSelection: Bool  // true for selection, false for persistent highlight
}

// Helper to calculate unified rectangles from word frames
extension Array where Element == WordFrame {
    func calculateUnifiedHighlights() -> [UnifiedHighlight] {
        var highlights: [UnifiedHighlight] = []
        
        // Sort frames by position (left to right, top to bottom)
        let sortedFrames = self.sorted { frame1, frame2 in
            if abs(frame1.frame.minY - frame2.frame.minY) < 5 {
                // Same line
                return frame1.frame.minX < frame2.frame.minX
            } else {
                // Different lines
                return frame1.frame.minY < frame2.frame.minY
            }
        }
        
        // Group consecutive words with the same highlight/selection
        var currentGroup: [WordFrame] = []
        var currentType: HighlightType?
        
        for frame in sortedFrames {
            let frameType: HighlightType?
            if frame.isSelected {
                frameType = .selection
            } else if let highlight = frame.highlight {
                frameType = .highlight(highlight)
            } else {
                frameType = nil
            }
            
            if let frameType = frameType {
                if currentType == frameType && !currentGroup.isEmpty {
                    let lastFrame = currentGroup.last!
                    // Check if frames are adjacent (on same line and close together)
                    if abs(lastFrame.frame.minY - frame.frame.minY) < 5 &&
                       frame.frame.minX - lastFrame.frame.maxX < 20 {
                        currentGroup.append(frame)
                    } else {
                        // Create highlight for current group
                        if let highlight = createHighlight(from: currentGroup, type: currentType!) {
                            highlights.append(highlight)
                        }
                        currentGroup = [frame]
                        currentType = frameType
                    }
                } else {
                    // Create highlight for previous group if exists
                    if !currentGroup.isEmpty, let currentType = currentType {
                        if let highlight = createHighlight(from: currentGroup, type: currentType) {
                            highlights.append(highlight)
                        }
                    }
                    currentGroup = [frame]
                    currentType = frameType
                }
            } else {
                // No highlight/selection, finish current group
                if !currentGroup.isEmpty, let currentType = currentType {
                    if let highlight = createHighlight(from: currentGroup, type: currentType) {
                        highlights.append(highlight)
                    }
                }
                currentGroup = []
                currentType = nil
            }
        }
        
        // Don't forget the last group
        if !currentGroup.isEmpty, let currentType = currentType {
            if let highlight = createHighlight(from: currentGroup, type: currentType) {
                highlights.append(highlight)
            }
        }
        
        return highlights
    }
    
    private func createHighlight(from frames: [WordFrame], type: HighlightType) -> UnifiedHighlight? {
        guard !frames.isEmpty else { return nil }
        
        // Calculate bounding box with padding
        let minX = frames.map { $0.frame.minX }.min()! - 2
        let maxX = frames.map { $0.frame.maxX }.max()! + 2
        let minY = frames.map { $0.frame.minY }.min()! - 2
        let maxY = frames.map { $0.frame.maxY }.max()! + 2
        
        let rect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        
        let (color, isSelection) = switch type {
        case .selection:
            (Color.accentColor.opacity(0.1), true)
        case .highlight(let highlightColor):
            (highlightColor.color, false)
        }
        
        return UnifiedHighlight(rect: rect, color: color, isSelection: isSelection)
    }
}