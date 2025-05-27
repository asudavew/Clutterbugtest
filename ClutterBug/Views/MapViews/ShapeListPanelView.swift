import SwiftUI

// MARK: - Shape List Panel Component
struct ShapeListPanelView: View {
    @ObservedObject var mapState: MapViewState
    let viewSize: CGSize
    
    var body: some View {
        if mapState.showShapeList && !mapState.placedShapes.isEmpty {
            ZStack {
                // Background overlay
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        mapState.showShapeList = false
                    }
                
                // List panel
                VStack(spacing: 0) {
                    headerView
                    Divider()
                    shapeListView
                }
                .frame(maxWidth: min(viewSize.width - 32, 350))
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 10)
            }
            .transition(.opacity)
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Text("Items in Building")
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
            Button("Done") {
                mapState.showShapeList = false
            }
            .foregroundColor(.blue)
            .font(.system(size: 16, weight: .medium))
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Shape List
    
    private var shapeListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(mapState.placedShapes.enumerated()), id: \.element.id) { index, shape in
                    ShapeListRowView(
                        index: index + 1,
                        shape: shape,
                        isSelected: mapState.selectedShape?.id == shape.id,
                        onTap: {
                            mapState.selectShape(shape)
                            mapState.showShapeList = false
                        },
                        onEdit: {
                            startEditingShape(shape)
                        },
                        onDelete: {
                            startDeletingShape(shape)
                        }
                    )
                }
            }
        }
        .frame(maxHeight: min(viewSize.height * 0.6, 400))
    }
    
    // MARK: - Actions
    
    private func startEditingShape(_ shape: PlacedShape) {
        mapState.editingShapeDimensions = shape
        mapState.tempWidth = String(Int(shape.width))
        mapState.tempLength = String(Int(shape.length))
        mapState.tempLabelText = shape.label
        mapState.showShapeList = false
    }
    
    private func startDeletingShape(_ shape: PlacedShape) {
        mapState.shapeToDelete = shape
        mapState.showDeleteConfirmation = true
        mapState.showShapeList = false
    }
}

// MARK: - Shape List Row
struct ShapeListRowView: View {
    let index: Int
    let shape: PlacedShape
    let isSelected: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            roomNumberView
            shapeInfoView
            Spacer()
            actionButtonsView
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(backgroundColor)
        .onTapGesture(perform: onTap)
    }
    
    // MARK: - Row Components
    
    private var roomNumberView: some View {
        Text("\(index)")
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
            .frame(width: 24, height: 24)
            .background(shape.color)
            .clipShape(Circle())
    }
    
    private var shapeInfoView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: shape.type.icon)
                    .foregroundColor(shape.color)
                    .font(.caption2)
                
                Text(shape.label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            Text("\(Int(shape.length))ft × \(Int(shape.width))ft")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var actionButtonsView: some View {
        HStack(spacing: 6) {
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption2)
                    .foregroundColor(.red)
                    .frame(width: 24, height: 24)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }
    
    private var backgroundColor: some View {
        Rectangle()
            .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
    }
}

// MARK: - Preview
#Preview {
    let mapState = MapViewState()
    mapState.placedShapes = [
        PlacedShape.create(type: .rectangle, at: CGPoint(x: 100, y: 100)),
        PlacedShape.create(type: .circle, at: CGPoint(x: 200, y: 200))
    ]
    mapState.showShapeList = true
    
    return ShapeListPanelView(
        mapState: mapState,
        viewSize: CGSize(width: 400, height: 600)
    )
}
