import SwiftUI

// MARK: - Shape Manager Component
struct ShapeManagerView: View {
    @ObservedObject var mapState: MapViewState
    let building: Building?
    let viewSize: CGSize
    
    var body: some View {
        ZStack {
            // Shape interaction overlays
            ForEach(mapState.placedShapes) { shape in
                ShapeInteractionOverlay(
                    shape: shape,
                    mapState: mapState,
                    building: building,
                    viewSize: viewSize
                )
            }
            
            // Shape list panel
            ShapeListPanelView(mapState: mapState, viewSize: viewSize)
            
            // Shape editor toolbar
            if mapState.showShapeEditor {
                VStack {
                    Spacer()
                    ShapeEditorToolbarView(
                        mapState: mapState,
                        building: building,
                        viewSize: viewSize
                    )
                }
            }
        }
        .alert("Edit Shape", isPresented: .constant(mapState.editingShapeDimensions != nil)) {
            TextField("Label", text: $mapState.tempLabelText)
            
            if let shape = mapState.editingShapeDimensions {
                if shape.type == .circle {
                    TextField("Diameter (ft)", text: $mapState.tempWidth)
                } else {
                    TextField("Length (ft)", text: $mapState.tempLength)
                    TextField("Width (ft)", text: $mapState.tempWidth)
                }
            }
            
            Button("Cancel") {
                mapState.editingShapeDimensions = nil
                mapState.tempLabelText = ""
                mapState.tempWidth = ""
                mapState.tempLength = ""
            }
            Button("Save") {
                saveShapeEdits()
            }
        }
        .alert("Delete Shape", isPresented: $mapState.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                mapState.shapeToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let shape = mapState.shapeToDelete {
                    mapState.deleteShape(id: shape.id)
                }
                mapState.shapeToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this shape?")
        }
    }
    
    // MARK: - Actions
    
    private func saveShapeEdits() {
        guard let shape = mapState.editingShapeDimensions,
              let newWidth = Double(mapState.tempWidth) else { return }
        
        let newLength: Double
        if shape.type == .circle {
            // For circles, length equals width (diameter)
            newLength = newWidth
        } else {
            guard let lengthValue = Double(mapState.tempLength) else { return }
            newLength = lengthValue
        }
        
        mapState.updateShape(
            id: shape.id,
            label: mapState.tempLabelText,
            width: newWidth,
            length: newLength
        )
        
        mapState.editingShapeDimensions = nil
        mapState.tempLabelText = ""
        mapState.tempWidth = ""
        mapState.tempLength = ""
    }
}

// MARK: - Shape Interaction Overlay
struct ShapeInteractionOverlay: View {
    let shape: PlacedShape
    @ObservedObject var mapState: MapViewState
    let building: Building?
    let viewSize: CGSize
    
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        let screenPosition = mapToScreenCoordinates(shape.position)
        let shapeSize = calculateShapeSize()
        let screenSize = CGSize(
            width: shapeSize.width * currentZoom,
            height: shapeSize.height * currentZoom
        )
        
        ZStack {
            // Main interaction area
            Rectangle()
                .fill(isSelected ? Color.red.opacity(0.15) : Color.clear)
                .frame(width: screenSize.width + 10, height: screenSize.height + 10)
                .position(x: screenPosition.x + dragOffset.width, y: screenPosition.y + dragOffset.height)
                .onTapGesture {
                    mapState.selectShape(shape)
                }
                .gesture(dragGesture)
            
            // Selection indicator
            if isSelected {
                Text("Selected - Drag to move")
                    .font(.caption2)
                    .bold()
                    .foregroundColor(.red)
                    .padding(3)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(3)
                    .position(x: screenPosition.x + dragOffset.width,
                             y: screenPosition.y + dragOffset.height + screenSize.height/2 + 25)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateShapeSize() -> CGSize {
        guard let building = building,
              let mapWidth = building.mapWidth,
              let mapHeight = building.mapHeight,
              building.length > 0,
              building.width > 0 else {
            // Fallback if no building data
            switch shape.type {
            case .circle:
                return CGSize(width: shape.width, height: shape.width)
            case .rectangle, .triangle, .diamond:
                return CGSize(width: shape.length, height: shape.width)
            }
        }
        
        // Calculate scale: map units per foot
        let scaleX = mapWidth / building.length
        let scaleY = mapHeight / building.width
        
        switch shape.type {
        case .circle:
            // Circle uses width as diameter, use average scale
            let avgScale = (scaleX + scaleY) / 2
            let diameter = shape.width * avgScale
            return CGSize(width: diameter, height: diameter)
        case .rectangle, .triangle, .diamond:
            // Other shapes use both dimensions with proper scaling
            return CGSize(width: shape.length * scaleX, height: shape.width * scaleY)
        }
    }
    
    // MARK: - Computed Properties
    
    private var isSelected: Bool {
        mapState.selectedShape?.id == shape.id
    }
    
    private var currentZoom: CGFloat {
        mapState.zoom * mapState.magnifyBy
    }
    
    private var currentPan: CGSize {
        CGSize(
            width: mapState.panOffset.width + mapState.dragOffset.width,
            height: mapState.panOffset.height + mapState.dragOffset.height
        )
    }
    
    // MARK: - Gestures
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                if isSelected {
                    dragOffset = value.translation
                    mapState.isDraggingShape = true
                }
            }
            .onEnded { value in
                if isSelected {
                    // Convert screen translation to map translation
                    let mapTranslation = CGSize(
                        width: value.translation.width / currentZoom,
                        height: value.translation.height / currentZoom
                    )
                    
                    // Apply translation directly to current position
                    let newPosition = CGPoint(
                        x: shape.position.x + mapTranslation.width,
                        y: shape.position.y + mapTranslation.height
                    )
                    
                    mapState.updateShape(id: shape.id, position: newPosition)
                    dragOffset = .zero
                    mapState.isDraggingShape = false
                }
            }
    }
    
    // MARK: - Coordinate Transformations
    
    private func mapToScreenCoordinates(_ mapPoint: CGPoint) -> CGPoint {
        guard let building = building,
              let mapX = building.mapX,
              let mapY = building.mapY,
              let mapWidth = building.mapWidth,
              let mapHeight = building.mapHeight else {
            return mapPoint
        }
        
        let viewCenter = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        let buildingCenter = CGPoint(x: mapX + mapWidth / 2, y: mapY + mapHeight / 2)
        
        let translatedPoint = CGPoint(
            x: (mapPoint.x - buildingCenter.x) * currentZoom,
            y: (mapPoint.y - buildingCenter.y) * currentZoom
        )
        
        return CGPoint(
            x: translatedPoint.x + viewCenter.x + currentPan.width,
            y: translatedPoint.y + viewCenter.y + currentPan.height
        )
    }
    
    private func screenToMapCoordinates(_ screenPoint: CGPoint) -> CGPoint {
        guard let building = building,
              let mapX = building.mapX,
              let mapY = building.mapY,
              let mapWidth = building.mapWidth,
              let mapHeight = building.mapHeight else {
            return screenPoint
        }
        
        let viewCenter = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        let buildingCenter = CGPoint(x: mapX + mapWidth / 2, y: mapY + mapHeight / 2)
        
        let translatedPoint = CGPoint(
            x: screenPoint.x - viewCenter.x - currentPan.width,
            y: screenPoint.y - viewCenter.y - currentPan.height
        )
        
        let scaledPoint = CGPoint(
            x: translatedPoint.x / currentZoom,
            y: translatedPoint.y / currentZoom
        )
        
        return CGPoint(
            x: scaledPoint.x + buildingCenter.x,
            y: scaledPoint.y + buildingCenter.y
        )
    }
}
