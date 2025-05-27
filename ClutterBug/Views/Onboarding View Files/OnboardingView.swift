import SwiftUI

struct OnboardingView: View {
    // This binding will be used to tell the parent view (e.g., ContentView or ClutterBugApp)
    // that onboarding is complete.
    @Binding var isOnboardingComplete: Bool

    // State to manage the currently selected onboarding page
    @State private var currentPage = 0
    
    // User preference for hierarchy (will be set during onboarding)
    // We'll use AppStorage here or pass it up to be stored by the parent.
    // For simplicity in this view, let's assume we set it here and the app reads it later.
    @AppStorage("userHierarchyChoice") private var userHierarchyChoice: String = "Simple" // "Simple" or "Advanced"

    let totalPages = 5 // As per your outline

    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                OnboardingPage1View()
                    .tag(0)
                
                OnboardingPage2View(userHierarchyChoice: $userHierarchyChoice) // Pass binding for choice
                    .tag(1)
                
                OnboardingPage3View()
                    .tag(2)
                
                OnboardingPage4View()
                    .tag(3)
                
                OnboardingPage5View(isOnboardingComplete: $isOnboardingComplete) // Pass binding to complete
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic)) // Makes it swipeable with page dots
            .indexViewStyle(.page(backgroundDisplayMode: .interactive))
            
            // Custom Page Control / Next Button (Optional, TabView provides dots by default)
            // We can add a more prominent "Next" or "Finish" button if desired,
            // especially for the last page. For now, the swipe and default dots will work.
            // The last page (OnboardingPage5View) will have its own "Get Started" button.
            
        }
        // Apply handwriting font to all text within onboarding if desired (can be done per page too)
        // .font(.custom("YourHandwritingFont", size: 18)) // Example
        .background(Color(.systemGroupedBackground)) // A slightly off-white background
        .edgesIgnoringSafeArea(.all) // Make it full screen
    }
}

// Dummy preview for OnboardingView
#Preview {
    // For the preview, we need a @State variable for the binding.
    struct OnboardingPreviewWrapper: View {
        @State var isComplete: Bool = false
        var body: some View {
            OnboardingView(isOnboardingComplete: $isComplete)
        }
    }
    return OnboardingPreviewWrapper()
}
