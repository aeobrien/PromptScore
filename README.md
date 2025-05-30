# PromptScore

A macOS SwiftUI app for annotating voiceover scripts with word-level annotations, color-coded phrasing, and audio reference recordings.

## Features

- **Script Import**: Paste plain text scripts which are automatically tokenized into paragraphs, sentences, and words
- **Word-Level Annotations**: Navigate through words using arrow keys and add annotation symbols using keyboard shortcuts
- **Color Highlighting**: Apply background colors to words for visual phrasing cues
- **View Modes**: Toggle between full paragraph view and single sentence view
- **Annotation Palette**: Visual reference for available annotations and their keyboard shortcuts

## Keyboard Shortcuts

### Navigation
- **Left Arrow**: Navigate to previous word
- **Right Arrow**: Navigate to next word

### Annotations
- **1**: ↑ (High pitch)
- **2**: ↓ (Low pitch)
- **3**: ↗︎ (Low to high)
- **4**: ↘︎ (High to low)
- **5**: ● (High emphasis)
- **6**: ○ (Low emphasis)
- **7**: _ (Pause)
- **8**: " " (Air quotes)
- **9**: L1 (List item 1)
- **0**: L2 (List item 2)
- **-**: L3 (List item 3)

## Building and Running

### Requirements
- macOS 13.0 or later
- Xcode 14.0 or later

### Build with Xcode
1. Open `PromptScore.xcodeproj` in Xcode
2. Select your development team in the project settings
3. Press ⌘R to build and run

### Build with xcodebuild
```bash
# Build the project
xcodebuild -scheme PromptScore -destination 'platform=macOS'

# Build and run
xcodebuild -scheme PromptScore -destination 'platform=macOS' build

# Run the built app
open build/Release/PromptScore.app
```

## Project Structure

```
PromptScore/
├── Models/
│   ├── Script.swift
│   ├── Paragraph.swift
│   ├── Sentence.swift
│   ├── Word.swift
│   ├── Annotation.swift
│   └── HighlightColor.swift
├── Views/
│   ├── ContentView.swift
│   ├── ScriptInputView.swift
│   ├── ScriptEditorView.swift
│   ├── WordView.swift
│   └── AnnotationPaletteView.swift
├── ViewModels/
│   └── ScriptViewModel.swift
└── Utilities/
    └── TextTokenizer.swift
```

## Future Enhancements

- Audio recording and playback functionality
- Multi-word highlight ranges
- Data persistence
- Export functionality
- iOS companion app for playback