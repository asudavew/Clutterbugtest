import SwiftUI

// MARK: - Building Canvas Component
struct BuildingCanvasView: View {
    let building: Building?
    @ObservedObject var mapState: MapViewState
    let viewSize: CGSize
    
    @GestureState private var tempDragOffset: CGSize = .zero
    @GestureState private var tempMagnifyBy: CGFloat = 1.0
    
    var body: some View {
        Canvas { context, size in
            guard let building = building,
                  let mapX = building.mapX,
                  let mapY = building.mapY,
                  let mapWidth = building.mapWidth,
                  let mapHeight = building.mapHeight else {
                return
            }
            
            let viewCenter = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
            let buildingCenter = CGPoint(x: mapX + mapWidth / 2, y: mapY + mapHeight / 2)
            let currentZoom = mapState.zoom * tempMagnifyBy
            let currentPan = CGSize(
                width: mapState.panOffset.width + (shouldUseDragOffset ? tempDragOffset.width : 0),
                height: mapState.panOffset.height + (shouldUseDragOffset ? tempDragOffset.height : 0)
            )
            
            // Apply transformations
            context.translateBy(x: viewCenter.x + currentPan.width, y: viewCenter.y + currentPan.height)
            context.scaleBy(x: currentZoom, y: currentZoom)
            context.translateBy(x: -buildingCenter.x, y: -buildingCenter.y)
            
            // Draw grid if enabled
            if mapState.showGrid {
                drawGrid(context: context, buildingCenter: buildingCenter, zoom: currentZoom)
            }
            
            // Draw building
            drawBuilding(context: context, building: building, zoom: currentZoom)
            
            // Draw placed shapes
            for shape in mapState.placedShapes {
                drawPlacedShape(context: context, shape: shape, zoom: currentZoom)
            }
        }
        .frame(width: viewSize.width, height: viewSize.height)
        .clipped()
        .contentShape(Rectangle())
        .gesture(panGesture)
        .simultaneousGesture(zoomGesture)
        .onTapGesture(count: 2) {
            if !mapState.measurementMode && !mapState.showShapeEditor {
                withAnimation(.spring()) {
                    mapState.resetView(for: building, in: viewSize)
                }
            }
        }
        .onTapGesture {
            if mapState.measurementMode {
                mapState.measurementStart = nil
                mapState.measurementEnd = nil
            } else {
                mapState.clearSelection()
            }
        }
        .overlay {
            if building == nil {
                ContentUnavailableView("No Building Data", systemImage: "map.circle.fill")
            }
        }
    }
    
    // MARK: - Gestures
    
    private var panGesture: some Gesture {
        DragGesture()
            .updating($tempDragOffset) { value, state, _ in
                // Only update state, don't access mapState here
                state = value.translation
            }
            .onChanged { value in
                if mapState.measurementMode {
                    if mapState.measurementStart == nil {
                        mapState.measurementStart = value.location
                    }
                    mapState.measurementEnd = value.location
                }
            }
            .onEnded { value in
                // Check conditions here instead of in updating
                if !mapState.measurementMode && !mapState.isDraggingShape {
                    mapState.panOffset.width += value.translation.width
                    mapState.panOffset.height += value.translation.height
                }
            }
    }
    
    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .updating($tempMagnifyBy) { value, state, _ in
                state = value
            }
            .onEnded { value in
                mapState.zoom = min(max(mapState.zoom * value, 0.5), 5.0)
            }
    }
    
    // Computed property to determine if we should use the drag offset
    private var shouldUseDragOffset: Bool {
        !mapState.measurementMode && !mapState.isDraggingShape
    }
    
    // MARK: - Drawing Functions
    
    private func drawBuilding(context: GraphicsContext, building: Building, zoom: CGFloat) {
        guard let mapX = building.mapX,
              let mapY = building.mapY,
              let mapWidth = building.mapWidth,
              let mapHeight = building.mapHeight,
              building.shapeType?.lowercased() == "rectangle" else { return }
        
        let rect = CGRect(x: mapX, y: mapY, width: mapWidth, height: mapHeight)
        let buildingCenter = CGPoint(x: mapX + mapWidth / 2, y: mapY + mapHeight / 2)
        
        // Draw building shape
        context.stroke(
            RoundedRectangle(cornerRadius: 10).path(in: rect),
            with: .color(.blue),
            lineWidth: 2.0 / zoom
        )
        
        context.fill(
            RoundedRectangle(cornerRadius: 10).path(in: rect),
            with: .color(.blue.opacity(0.1))
        )
        
        // Draw building dimensions if enabled
        if mapState.showDimensions {
            drawBuildingDimensions(context: context, building: building, rect: rect, zoom: zoom)
        }
        
        // Draw building labels
        context.draw(
            Text(building.mapLabel ?? building.name)
                .font(.system(size: max(12, 18 / zoom), weight: .bold))
                .foregroundColor(.blue),
            at: CGPoint(x: buildingCenter.x, y: buildingCenter.y - 10 / zoom)
        )
        
        if zoom > 0.8 {
            context.draw(
                Text("(Tap shape to see items - TBD)")
                    .font(.system(size: max(10, 12 / zoom)))
                    .foregroundColor(.gray),
                at: CGPoint(x: buildingCenter.x, y: buildingCenter.y + 15 / zoom)
            )
        }
    }
    
    private func drawBuildingDimensions(context: GraphicsContext, building: Building, rect: CGRect, zoom: CGFloat) {
        let dimColor = Color.red
        let fontSize = max(10, 14 / zoom)
        let offset = 20 / zoom
        
        let lengthInFeet = building.length
        let widthInFeet = building.width
        
        // Length dimension (bottom)
        let lengthStart = CGPoint(x: rect.minX, y: rect.maxY + offset)
        let lengthEnd = CGPoint(x: rect.maxX, y: rect.maxY + offset)
        let lengthMid = CGPoint(x: rect.midX, y: rect.maxY + offset)
        
        let lengthPath = Path { path in
            path.move(to: lengthStart)
            path.addLine(to: lengthEnd)
            // End caps
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY + offset - 5/zoom))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY + offset + 5/zoom))
            path.move(to: CGPoint(x: rect.maxX, y: rect.maxY + offset - 5/zoom))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY + offset + 5/zoom))
        }
        context.stroke(lengthPath, with: .color(dimColor), lineWidth: 1.0 / zoom)
        
        context.draw(
            Text("\(Int(lengthInFeet))ft")
                .font(.system(size: fontSize, weight: .medium))
                .foregroundColor(dimColor),
            at: lengthMid
        )
        
        // Width dimension (right side)
        let widthStart = CGPoint(x: rect.maxX + offset, y: rect.minY)
        let widthEnd = CGPoint(x: rect.maxX + offset, y: rect.maxY)
        let widthMid = CGPoint(x: rect.maxX + offset, y: rect.midY)
        
        let widthPath = Path { path in
            path.move(to: widthStart)
            path.addLine(to: widthEnd)
            // End caps
            path.move(to: CGPoint(x: rect.maxX + offset - 5/zoom, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX + offset + 5/zoom, y: rect.minY))
            path.move(to: CGPoint(x: rect.maxX + offset - 5/zoom, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX + offset + 5/zoom, y: rect.maxY))
        }
        context.stroke(widthPath, with: .color(dimColor), lineWidth: 1.0 / zoom)
        
        context.draw(
            Text("\(Int(widthInFeet))ft")
                .font(.system(size: fontSize, weight: .medium))
                .foregroundColor(dimColor),
            at: widthMid
        )
    }
    
    private func drawGrid(context: GraphicsContext, buildingCenter: CGPoint, zoom: CGFloat) {
        let gridSpacing: CGFloat = 50
        let lineColor = Color.gray.opacity(0.3)
        let lineWidth = 0.5 / zoom
        
        let visibleArea = CGRect(
            x: buildingCenter.x - viewSize.width / (2 * zoom),
            y: buildingCenter.y - viewSize.height / (2 * zoom),
            width: viewSize.width / zoom,
            height: viewSize.height / zoom
        )
        
        // Draw vertical lines
        let startX = floor(visibleArea.minX / gridSpacing) * gridSpacing
        let endX = ceil(visibleArea.maxX / gridSpacing) * gridSpacing
        
        for x in stride(from: startX, through: endX, by: gridSpacing) {
            let path = Path { path in
                path.move(to: CGPoint(x: x, y: visibleArea.minY))
                path.addLine(to: CGPoint(x: x, y: visibleArea.maxY))
            }
            context.stroke(path, with: .color(lineColor), lineWidth: lineWidth)
            
            if zoom > 0.5 && Int(x) % 100 == 0 {
                context.draw(
                    Text("\(Int(x))ft")
                        .font(.system(size: max(8, 10 / zoom)))
                        .foregroundColor(.gray),
                    at: CGPoint(x: x, y: visibleArea.minY + 10 / zoom)
                )
            }
        }
        
        // Draw horizontal lines
        let startY = floor(visibleArea.minY / gridSpacing) * gridSpacing
        let endY = ceil(visibleArea.maxY / gridSpacing) * gridSpacing
        
        for y in stride(from: startY, through: endY, by: gridSpacing) {
            let path = Path { path in
                path.move(to: CGPoint(x: visibleArea.minX, y: y))
                path.addLine(to: CGPoint(x: visibleArea.maxX, y: y))
            }
            context.stroke(path, with: .color(lineColor), lineWidth: lineWidth)
            
            if zoom > 0.5 && Int(y) % 100 == 0 {
                context.draw(
                    Text("\(Int(y))ft")
                        .font(.system(size: max(8, 10 / zoom)))
                        .foregroundColor(.gray),
                    at: CGPoint(x: visibleArea.minX + 10 / zoom, y: y)
                )
            }
        }
    }
    
    private func drawPlacedShape(context: GraphicsContext, shape: PlacedShape, zoom: CGFloat) {
        let shapeSize = calculateShapeSize(shape: shape)
        let shapeRect = CGRect(
            x: shape.position.x - shapeSize.width / 2,
            y: shape.position.y - shapeSize.height / 2,
            width: shapeSize.width,
            height: shapeSize.height
        )
        
        let strokeColor = mapState.selectedShape?.id == shape.id ? Color.red : shape.color
        let fillColor = shape.color.opacity(0.3)
        let lineWidth = (mapState.selectedShape?.id == shape.id ? 3.0 : 2.0) / zoom
        
        switch shape.type {
        case .rectangle:
            context.stroke(
                RoundedRectangle(cornerRadius: 3).path(in: shapeRect),
                with: .color(strokeColor),
                lineWidth: lineWidth
            )
            context.fill(
                RoundedRectangle(cornerRadius: 3).path(in: shapeRect),
                with: .color(fillColor)
            )
            
        case .circle:
            context.stroke(
                Circle().path(in: shapeRect),
                with: .color(strokeColor),
                lineWidth: lineWidth
            )
            context.fill(
                Circle().path(in: shapeRect),
                with: .color(fillColor)
            )
            
        case .triangle:
            let trianglePath = Path { path in
                path.move(to: CGPoint(x: shapeRect.midX, y: shapeRect.minY))
                path.addLine(to: CGPoint(x: shapeRect.minX, y: shapeRect.maxY))
                path.addLine(to: CGPoint(x: shapeRect.maxX, y: shapeRect.maxY))
                path.closeSubpath()
            }
            context.stroke(trianglePath, with: .color(strokeColor), lineWidth: lineWidth)
            context.fill(trianglePath, with: .color(fillColor))
            
        case .diamond:
            let diamondPath = Path { path in
                path.move(to: CGPoint(x: shapeRect.midX, y: shapeRect.minY))
                path.addLine(to: CGPoint(x: shapeRect.maxX, y: shapeRect.midY))
                path.addLine(to: CGPoint(x: shapeRect.midX, y: shapeRect.maxY))
                path.addLine(to: CGPoint(x: shapeRect.minX, y: shapeRect.midY))
                path.closeSubpath()
            }
            context.stroke(diamondPath, with: .color(strokeColor), lineWidth: lineWidth)
            context.fill(diamondPath, with: .color(fillColor))
        }
        
        // Draw shape label centered
        context.draw(
            Text(shape.label)
                .font(.system(size: max(8, 12 / zoom), weight: .medium))
                .foregroundColor(strokeColor),
            at: CGPoint(x: shape.position.x, y: shape.position.y)
        )
        
        // Draw dimensions below the shape
        context.draw(
            Text(shape.measurementText)
                .font(.system(size: max(6, 10 / zoom), weight: .regular))
                .foregroundColor(.gray),
            at: CGPoint(x: shape.position.x, y: shape.position.y + shapeSize.height / 2 + 15 / zoom)
        )
    }
    
    private func calculateShapeSize(shape: PlacedShape) -> CGSize {
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
}

