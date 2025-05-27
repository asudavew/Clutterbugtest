import SwiftUI

struct OnboardingPage2View: View {
    @Binding var userHierarchyChoice: String // "Simple" or "Advanced"
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "list.bullet.indent") // Placeholder for hierarchy graphic
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)

            Text("How Organized Are You Feeling?")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Start with just Items, or go big with Buildings, Rooms, and more? You can change this later in Settings!")
                .font(.title3)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Picker("Inventory Style", selection: $userHierarchyChoice) {
                Text("Simple (Items Only)").tag("Simple")
                Text("Advanced (Full Hierarchy)").tag("Advanced")
            }
            .pickerStyle(.segmented) // Or .inline for more prominent options
            .padding(.horizontal, 40)
            .padding(.vertical)

            Text(userHierarchyChoice == "Simple" ? "Great! We'll keep it simple." : "Ambitious! Let's build your empire of stuff!")
                .font(.headline)
                .foregroundColor(userHierarchyChoice == "Simple" ? .green : .purple)
            
            Spacer()
        }
        .padding(.top, 100)
        .padding()
    }
}

#Preview {
    // For the preview, provide a dummy binding
    struct PreviewWrapper: View {
        @State var choice: String = "Simple"
        var body: some View {
            OnboardingPage2View(userHierarchyChoice: $choice)
        }
    }
    return PreviewWrapper()
}
