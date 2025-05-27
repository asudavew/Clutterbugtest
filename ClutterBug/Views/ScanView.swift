//
//  ScanView.swift
//  ClutterBug
//
//  Created by David Watson on 5/20/25.
//

import Foundation
import SwiftUI

struct SearchView: View {
    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "magnifyingglass.circle.fill") // Placeholder icon
                    .font(.system(size: 80))
                    .padding()
                Text("Search")
                    .font(.largeTitle)
                Text("Find your treasures! (Coming Soon)")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .padding(.top)
            }
            // Example of how search bar might be added later
            // .searchable(text: $searchText, prompt: "Search items, categories, notes...")
            .navigationTitle("Search Inventory")
        }
    }
}

#Preview {
    SearchView()
}
