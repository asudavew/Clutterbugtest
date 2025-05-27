
import Foundation
import SwiftData

@Model
final class Building {
    @Attribute(.unique) var id: UUID
    var name: String
    var photoIdentifier: String?
    var height: Double // Measurement in feet
    var width: Double  // Measurement in feet
    var length: Double // Measurement in feet

    // Relationship to Items directly parented to this Building
    @Relationship(deleteRule: .cascade, inverse: \Item.parentBuilding)
    var items: [Item]? = []

    // --- New Map-related fields ---
    var mapX: Double?          // X-coordinate on the canvas
    var mapY: Double?          // Y-coordinate on the canvas
    var mapWidth: Double?      // Width of the shape on the canvas
    var mapHeight: Double?     // Height of the shape on the canvas
    var shapeType: String?     // E.g., "rectangle", "circle", "square" (Consider an Enum later)
    var mapLabel: String?      // Label displayed on the map shape (might be same as 'name' or custom)
    // --- End New Map-related fields ---

    init(id: UUID = UUID(),
         name: String = "My Workshop",
         photoIdentifier: String? = nil,
         height: Double = 0.0, // Default to 0, user can edit
         width: Double = 0.0,
         length: Double = 0.0,
         // New map fields added to initializer with default nil values
         mapX: Double? = nil,
         mapY: Double? = nil,
         mapWidth: Double? = nil,
         mapHeight: Double? = nil,
         shapeType: String? = nil,
         mapLabel: String? = nil) { // mapLabel can default to name if not provided
        self.id = id
        self.name = name
        self.photoIdentifier = photoIdentifier
        self.height = height
        self.width = width
        self.length = length
        
        self.mapX = mapX
        self.mapY = mapY
        self.mapWidth = mapWidth
        self.mapHeight = mapHeight
        self.shapeType = shapeType
        self.mapLabel = mapLabel ?? name // Default mapLabel to the building's name if not specified
        // 'items' is initialized above
    }
}
