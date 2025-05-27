import SwiftUI
import Foundation

// MARK: - PlacedShape Model
struct PlacedShape: Identifiable, Codable {
    let id: UUID
    var type: ShapeType
    var position: CGPoint  // Center position in map coordinates
    var width: Double      // Actual width in feet
    var length: Double     // Actual length in feet (not used for circles)
    var label: String
    var colorType: ShapeColor
    
    // Computed properties
    var color: Color {
        colorType.color
    }
    
    // Display text for measurements
    var measurementText: String {
        switch type {
        case .circle:
            return "\(Int(width))ft ⌀"  // ⌀ = diameter symbol
        case .rectangle, .triangle, .diamond:
            return "\(Int(length))ft × \(Int(width))ft"
        }
    }
    
    init(id: UUID = UUID(), type: ShapeType, position: CGPoint, width: Double, length: Double, label: String, colorType: ShapeColor) {
        self.id = id
        self.type = type
        self.position = position
        self.width = width
        self.length = length
        self.label = label
        self.colorType = colorType
    }
}

// MARK: - Shape Type
extension PlacedShape {
    enum ShapeType: String, CaseIterable, Codable {
        case rectangle = "rectangle"
        case circle = "circle"
        case triangle = "triangle"
        case diamond = "diamond"
        
        var icon: String {
            switch self {
            case .rectangle: return "rectangle"
            case .circle: return "circle"
            case .triangle: return "triangle"
            case .diamond: return "diamond"
            }
        }
        
        var defaultWidth: Double {
            switch self {
            case .circle: return 8.0      // 8 foot diameter circle
            case .rectangle, .triangle, .diamond: return 4.0  // 4 feet width
            }
        }
        
        var defaultLength: Double {
            switch self {
            case .circle: return 8.0      // Not used, but set same as width
            case .rectangle, .triangle, .diamond: return 6.0  // 6 feet length
            }
        }
        
        var displayName: String {
            return rawValue.capitalized
        }
        
        var usesLength: Bool {
            switch self {
            case .circle: return false
            case .rectangle, .triangle, .diamond: return true
            }
        }
        
        var dimensionLabel: String {
            switch self {
            case .circle: return "Diameter (ft)"
            case .rectangle, .triangle, .diamond: return "Length × Width (ft)"
            }
        }
    }
}

// MARK: - Shape Color
extension PlacedShape {
    enum ShapeColor: String, CaseIterable, Codable {
        case blue = "blue"
        case red = "red"
        case green = "green"
        case orange = "orange"
        case purple = "purple"
        
        var color: Color {
            switch self {
            case .blue: return .blue
            case .red: return .red
            case .green: return .green
            case .orange: return .orange
            case .purple: return .purple
            }
        }
        
        var displayName: String {
            return rawValue.capitalized
        }
    }
}

// MARK: - Shape Factory
extension PlacedShape {
    static func create(type: ShapeType, at position: CGPoint) -> PlacedShape {
        return PlacedShape(
            type: type,
            position: position,
            width: type.defaultWidth,
            length: type.defaultLength,
            label: "New \(type.displayName)",
            colorType: .blue
        )
    }
}
