// SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @AppStorage("userHierarchyChoice") private var userHierarchyChoice: String = "Simple" // Default if not set by onboarding

    // Define the options for the picker for clarity
    enum HierarchyMode: String, CaseIterable, Identifiable {
        case simple = "Simple"
        case advanced = "Advanced"
        var id: String { self.rawValue }
    }
    
    @State private var currentSelection: HierarchyMode = .simple // Local state for picker

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Inventory Organization Style")) {
                    Picker("Hierarchy Mode", selection: $currentSelection) {
                        ForEach(HierarchyMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    // Consider .pickerStyle(.inline) or .automatic for different looks
                    // .pickerStyle(.segmented) might also work if only two options

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Current Mode: \(userHierarchyChoice)")
                            .font(.headline)
                        if userHierarchyChoice == "Simple" {
                            Text("Keeping it chill with 'Items Only'. Perfect for when you just want to find that one wrench without navigating a labyrinth!")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else {
                            Text("Feeling fancy with Buildings, Rooms, and the whole shebang! Unleash your inner inventory architect.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 5)
                }
                
                Section(header: Text("About ClutterBug")) {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("1.0.0 (Phase 2)") // Example
                    }
                    // Add more about/feedback links later if needed
                }
                
                // Placeholder for future settings
                Section(header: Text("Future Settings")) {
                    Text("iCloud Sync (Optional, Post-MVP)")
                    Text("Customize Map Icons")
                    Text("Data Export/Import")
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                // Sync Picker with AppStorage on appear
                currentSelection = HierarchyMode(rawValue: userHierarchyChoice) ?? .simple
            }
            .onChange(of: currentSelection) { oldValue, newValue in
                // Update AppStorage when Picker changes
                userHierarchyChoice = newValue.rawValue
                print("User hierarchy choice changed to: \(userHierarchyChoice)")
                // You might want to add a small delay or confirmation before a major app-wide change
                // like hierarchy, or inform the user that changes will take effect on next Home screen load.
            }
        }
    }
}

#Preview {
    SettingsView()
}
