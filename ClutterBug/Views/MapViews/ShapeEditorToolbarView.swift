import SwiftUI

// MARK: - Shape Editor Toolbar Component
struct ShapeEditorToolbarView: View {
    @ObservedObject var mapState: MapViewState
    let building: Building?
    let viewSize: CGSize
    
    var body: some View {
        VStack(spacing: 4) {
            Text("Drag shapes onto map")
                .font(.caption2)
                .foregroundColor(.gray)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(PlacedShape.ShapeType.allCases, id: \.self) { shapeType in
                        DraggableShapeButton(
                            shapeType: shapeType,
                            onDragged: { type, location in
                                addShapeAt(shapeType: type, screenLocation: location)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.95))
                .shadow(radius: 4)
        )
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .transition(.move(edge: .bottom))
    }
    
    // MARK: - Actions
    
    private func addShapeAt(shapeType: PlacedShape.ShapeType, screenLocation: CGPoint) {
        let mapPosition = screenToMapCoordinates(screenLocation)
        let newShape = PlacedShape.create(type: shapeType, at: mapPosition)
        mapState.addShape(newShape)
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
        let currentZoom = mapState.zoom * mapState.magnifyBy
        let currentPan = CGSize(
            width: mapState.panOffset.width + mapState.dragOffset.width,
            height: mapState.panOffset.height + mapState.dragOffset.height
        )
        
        // Reverse the transformation applied in BuildingCanvasView
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

// MARK: - Draggable Shape Button
struct DraggableShapeButton: View {
    let shapeType: PlacedShape.ShapeType
    let onDragged: (PlacedShape.ShapeType, CGPoint) -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: shapeType.icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                )
                .scaleEffect(isDragging ? 1.1 : 1.0)
                .offset(dragOffset)
            
            Text(shapeType.displayName)
                .font(.caption2)
                .foregroundColor(.primary)
        }
        .frame(width: 50)
        .gesture(
            DragGesture(coordinateSpace: .global)
                .onChanged { value in
                    dragOffset = value.translation
                    isDragging = true
                }
                .onEnded { value in
                    onDragged(shapeType, value.location)
                    dragOffset = .zero
                    isDragging = false
                }
        )
        .animation(.spring(response: 0.2), value: isDragging)
    }
}
