//
//  PaletteEditView.swift
//  PromptScore
//
//  Created by Aidan O'Brien on 30/05/2025.
//

import SwiftUI

struct PaletteEditView: View {
    @ObservedObject var paletteManager: PaletteManager
    @Environment(\.dismiss) var dismiss
    
    @State private var newAnnotationSymbol = ""
    @State private var newAnnotationDescription = ""
    @State private var newAnnotationShortcut = ""
    
    @State private var newColorName = ""
    @State private var newColorR: Double = 0.5
    @State private var newColorG: Double = 0.5
    @State private var newColorB: Double = 0.5
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Palette")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            TabView {
                annotationsTab
                    .tabItem {
                        Label("Annotations", systemImage: "text.cursor")
                    }
                
                colorsTab
                    .tabItem {
                        Label("Colors", systemImage: "paintpalette")
                    }
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                
                Spacer()
                
                Button("Save") {
                    paletteManager.save()
                    dismiss()
                }
            }
            .padding(.top)
        }
        .padding()
        .frame(width: 600, height: 500)
    }
    
    private var annotationsTab: some View {
        VStack {
            Text("All Annotations")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top)
            
            List {
                ForEach(paletteManager.editableAnnotations) { annotation in
                    HStack {
                        TextField("Symbol", text: Binding(
                            get: { annotation.symbol },
                            set: { newValue in
                                if let index = paletteManager.editableAnnotations.firstIndex(where: { $0.id == annotation.id }) {
                                    paletteManager.editableAnnotations[index].symbol = newValue
                                }
                            }
                        ))
                        .frame(width: 50)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Description", text: Binding(
                            get: { annotation.description },
                            set: { newValue in
                                if let index = paletteManager.editableAnnotations.firstIndex(where: { $0.id == annotation.id }) {
                                    paletteManager.editableAnnotations[index].description = newValue
                                }
                            }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Key", text: Binding(
                            get: { annotation.keyboardShortcut ?? "" },
                            set: { newValue in
                                if let index = paletteManager.editableAnnotations.firstIndex(where: { $0.id == annotation.id }) {
                                    paletteManager.editableAnnotations[index].keyboardShortcut = newValue.isEmpty ? nil : String(newValue.prefix(1))
                                }
                            }
                        ))
                        .frame(width: 40)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        // Show "Built-in" label or delete button
                        if annotation.isBuiltIn {
                            Text("Built-in")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 60)
                        } else {
                            Button(action: {
                                paletteManager.removeAnnotation(id: annotation.id)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .frame(width: 60)
                        }
                    }
                }
            }
            
            // Add new annotation
            HStack {
                TextField("Symbol", text: $newAnnotationSymbol)
                    .frame(width: 50)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Description", text: $newAnnotationDescription)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Key", text: $newAnnotationShortcut)
                    .frame(width: 40)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Add") {
                    if !newAnnotationSymbol.isEmpty && !newAnnotationDescription.isEmpty {
                        paletteManager.addCustomAnnotation(
                            symbol: newAnnotationSymbol,
                            description: newAnnotationDescription,
                            keyboardShortcut: newAnnotationShortcut.isEmpty ? nil : String(newAnnotationShortcut.prefix(1))
                        )
                        newAnnotationSymbol = ""
                        newAnnotationDescription = ""
                        newAnnotationShortcut = ""
                    }
                }
                .frame(width: 60)
            }
            .padding()
        }
    }
    
    private var colorsTab: some View {
        VStack {
            // Built-in colors
            Text("Built-in Colors")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top)
            
            List {
                ForEach(Array(HighlightColor.allCases.enumerated()), id: \.element) { index, color in
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color.color)
                            .frame(width: 30, height: 20)
                        
                        Text(color.displayName)
                        
                        Spacer()
                        
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(4)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .frame(height: 150)
            
            Divider()
            
            // Custom colors
            Text("Custom Colors")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top)
            
            List {
                ForEach(paletteManager.customColors) { color in
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color.color)
                            .frame(width: 30, height: 20)
                        
                        TextField("Name", text: Binding(
                            get: { color.displayName },
                            set: { newValue in
                                if let index = paletteManager.customColors.firstIndex(where: { $0.id == color.id }) {
                                    paletteManager.customColors[index].displayName = newValue
                                }
                            }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: {
                            paletteManager.customColors.removeAll { $0.id == color.id }
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
                .onDelete { indices in
                    paletteManager.customColors.remove(atOffsets: indices)
                }
            }
            .frame(maxHeight: 100)
            
            // Add new color
            VStack {
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: newColorR, green: newColorG, blue: newColorB))
                        .frame(width: 30, height: 20)
                    
                    TextField("Color name", text: $newColorName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Add") {
                        if !newColorName.isEmpty {
                            let color = CustomHighlightColor(
                                red: newColorR,
                                green: newColorG,
                                blue: newColorB,
                                displayName: newColorName
                            )
                            paletteManager.customColors.append(color)
                            newColorName = ""
                            newColorR = 0.5
                            newColorG = 0.5
                            newColorB = 0.5
                        }
                    }
                }
                
                HStack {
                    Text("R:")
                    Slider(value: $newColorR, in: 0...1)
                        .frame(width: 100)
                    Text("\(Int(newColorR * 255))")
                        .frame(width: 40)
                    
                    Text("G:")
                    Slider(value: $newColorG, in: 0...1)
                        .frame(width: 100)
                    Text("\(Int(newColorG * 255))")
                        .frame(width: 40)
                    
                    Text("B:")
                    Slider(value: $newColorB, in: 0...1)
                        .frame(width: 100)
                    Text("\(Int(newColorB * 255))")
                        .frame(width: 40)
                }
                .font(.caption)
            }
            .padding()
        }
    }
}