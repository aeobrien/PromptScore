//
//  ContentView.swift
//  PromptScore
//
//  Created by Aidan O'Brien on 30/05/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ScriptViewModel()
    @State private var showingImportSheet = false
    @State private var showingAnnotationPalette = true
    
    var body: some View {
        NavigationSplitView {
            if showingAnnotationPalette {
                AnnotationPaletteView(viewModel: viewModel)
            }
        } detail: {
            VStack {
                toolbar
                
                if viewModel.script != nil {
                    ScriptEditorView(viewModel: viewModel)
                } else {
                    emptyStateView
                }
            }
        }
        .sheet(isPresented: $showingImportSheet) {
            ScriptInputView(isPresented: $showingImportSheet) { text in
                viewModel.importText(text)
            }
        }
    }
    
    private var toolbar: some View {
        HStack {
            Button(action: { showingImportSheet = true }) {
                Label("Import Script", systemImage: "doc.text")
            }
            
            if viewModel.script != nil {
                Picker("View Mode", selection: $viewModel.viewMode) {
                    Text("Full Paragraph").tag(ScriptViewModel.ViewMode.fullParagraph)
                    Text("Single Sentence").tag(ScriptViewModel.ViewMode.singleSentence)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 300)
            }
            
            Spacer()
            
            Button(action: { showingAnnotationPalette.toggle() }) {
                Label("Toggle Palette", systemImage: showingAnnotationPalette ? "rectangle.lefthalf.inset.filled" : "sidebar.leading")
            }
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Script Loaded")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Import a script to begin annotating")
                .foregroundColor(.secondary)
            
            Button("Import Script") {
                showingImportSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
