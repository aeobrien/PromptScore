//
//  ScriptInputView.swift
//  PromptScore
//
//  Created by Aidan O'Brien on 30/05/2025.
//

import SwiftUI

struct ScriptInputView: View {
    @Binding var isPresented: Bool
    @State private var inputText: String = ""
    var onImport: (String) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Import Script")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Paste your script text below")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ScrollView {
                TextEditor(text: $inputText)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 300)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            }
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Import") {
                    onImport(inputText)
                    isPresented = false
                }
                .keyboardShortcut(.return)
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .frame(width: 600, height: 500)
    }
}