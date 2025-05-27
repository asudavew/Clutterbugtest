import Foundation
import SwiftData

@Model
final class Item {
    @Attribute(.unique) var id: UUID
    var name: String
    var photoIdentifier: String?
    var height: Double // Measurement in inches
    var width: Double  // Measurement in inches
    var length: Double // Measurement in inches
    var category: String
    var quantity: Int
    var notes: String?
    var sku: String?
    var condition: String

    // Parent Relationship
    var parentBuilding: Building?
    // Future parent relationships (Room, StorageArea, etc.) will go here.

    // --- New Map-related fields ---
    var mapX: Double?
    var mapY: Double?
    var mapWidth: Double?
    var mapHeight: Double?
    var shapeType: String?
    var mapLabel: String?
    // --- End New Map-related fields ---

    var ultimateBuilding: Building? { // This logic will need to expand for full hierarchy
        parentBuilding
    }

    init(id: UUID = UUID(),
         name: String = "",
         photoIdentifier: String? = nil,
         height: Double = 0.0,
         width: Double = 0.0,
         length: Double = 0.0,
         category: String = "",
         quantity: Int = 1,
         notes: String? = nil,
         sku: String? = nil,
         condition: String = "Used",
         parentBuilding: Building, // Required for Phase 1 "Items Only" mode
         // New map fields added to initializer
         mapX: Double? = nil,
         mapY: Double? = nil,
         mapWidth: Double? = nil,
         mapHeight: Double? = nil,
         shapeType: String? = nil,
         mapLabel: String? = nil) {
        self.id = id
        self.name = name
        self.photoIdentifier = photoIdentifier
        self.height = height
        self.width = width
        self.length = length
        self.category = category
        self.quantity = quantity
        self.notes = notes
        self.sku = sku
        self.condition = condition
        self.parentBuilding = parentBuilding
        
        self.mapX = mapX
        self.mapY = mapY
        self.mapWidth = mapWidth
        self.mapHeight = mapHeight
        self.shapeType = shapeType
        self.mapLabel = mapLabel ?? name // Default mapLabel to item's name
    }
}
