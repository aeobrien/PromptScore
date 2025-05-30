//
//  HighlightColor.swift
//  PromptScore
//
//  Created by Aidan O'Brien on 30/05/2025.
//

import SwiftUI

enum HighlightColor: String, CaseIterable, Codable {
    case greenDark = "greenDark"
    case blueLight = "blueLight"
    case blueDark = "blueDark"
    case orangeLight = "orangeLight"
    case orangeDark = "orangeDark"
    case yellow = "yellow"
    
    var color: Color {
        switch self {
        case .greenDark:
            return Color(red: 0.0, green: 0.5, blue: 0.2)
        case .blueLight:
            return Color(red: 0.6, green: 0.8, blue: 1.0)
        case .blueDark:
            return Color(red: 0.0, green: 0.3, blue: 0.7)
        case .orangeLight:
            return Color(red: 1.0, green: 0.7, blue: 0.3)
        case .orangeDark:
            return Color(red: 0.8, green: 0.4, blue: 0.0)
        case .yellow:
            return Color(red: 1.0, green: 0.9, blue: 0.3)
        }
    }
    
    var displayName: String {
        switch self {
        case .greenDark:
            return "Sentence Resolution"
        case .blueLight:
            return "Palms Up"
        case .blueDark:
            return "Palms Down"
        case .orangeLight:
            return "Comparison (Light)"
        case .orangeDark:
            return "Comparison (Dark)"
        case .yellow:
            return "Aside"
        }
    }
}