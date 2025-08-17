
import Foundation
import SwiftUI

struct GrammarTopic: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    private let colorName: String // For Codable conformance
    let stages: [Stage]

    var color: Color {
        // Convert colorName string to Color. You might need a more robust mapping here.
        // For now, a simple switch or a custom Color extension could be used.
        // This is a placeholder, you'll need to implement the actual color mapping.
        switch colorName {
        case "orange": return .orange
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "red": return .red
        case "yellow": return .yellow
        case "indigo": return .indigo
        default: return .gray
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, title, description, iconName, colorName = "color", stages
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        iconName = try container.decode(String.self, forKey: .iconName)
        colorName = try container.decode(String.self, forKey: .colorName)
        stages = try container.decode([Stage].self, forKey: .stages)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(iconName, forKey: .iconName)
        try container.encode(colorName, forKey: .colorName)
        try container.encode(stages, forKey: .stages)
    }
}
