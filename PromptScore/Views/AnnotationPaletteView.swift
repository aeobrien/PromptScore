//
//  AnnotationPaletteView.swift
//  PromptScore
//
//  Created by Aidan O'Brien on 30/05/2025.
//

import SwiftUI

struct AnnotationPaletteView: View {
    @ObservedObject var viewModel: ScriptViewModel
    @StateObject private var paletteManager = PaletteManager()
    @State private var showingEditView = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Annotations")
                    .font(.headline)
                Spacer()
                Button(action: { showingEditView = true }) {
                    Image(systemName: "pencil")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(paletteManager.getAllAnnotations(), id: \.symbol) { annotation in
                    HStack {
                        Text(annotation.symbol)
                            .font(.system(size: 20))
                            .frame(width: 30)
                        
                        Text(annotation.description)
                            .font(.system(size: 14))
                        
                        Spacer()
                        
                        if let shortcut = annotation.shortcut {
                            Text(String(shortcut))
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            Divider()
            
            HStack {
                Text("Highlights")
                    .font(.headline)
                Spacer()
                Text("Press 1-\(paletteManager.getAllColors().count) or click")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(paletteManager.getAllColors(), id: \.index) { colorInfo in
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(colorInfo.color)
                            .frame(width: 30, height: 20)
                        
                        Text(colorInfo.name)
                            .font(.system(size: 14))
                        
                        Spacer()
                        
                        if colorInfo.index <= 9 {
                            Text("\(colorInfo.index)")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    .onTapGesture {
                        // Apply color based on index
                        if colorInfo.index <= HighlightColor.allCases.count {
                            // Built-in color
                            if let color = HighlightColor.allCases[safe: colorInfo.index - 1] {
                                viewModel.setHighlightForSelectedWords(color: color)
                            }
                        } else {
                            // Custom color - need to implement custom color support
                            // For now, just use the first built-in color
                            viewModel.setHighlightForSelectedWords(color: .greenDark)
                        }
                    }
                }
                
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.secondary, style: StrokeStyle(lineWidth: 1, dash: [3]))
                        .frame(width: 30, height: 20)
                    
                    Text("Remove highlight")
                        .font(.system(size: 14))
                    
                    Spacer()
                    
                    Text("0")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }
                .onTapGesture {
                    viewModel.setHighlightForSelectedWords(color: nil)
                }
            }
            
            Divider()
            
            if !viewModel.selectedWords.isEmpty {
                Text("\(viewModel.selectedWords.count) word\(viewModel.selectedWords.count == 1 ? "" : "s") selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 300)
        .background(Color(NSColor.controlBackgroundColor))
        .sheet(isPresented: $showingEditView) {
            PaletteEditView(paletteManager: paletteManager)
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}