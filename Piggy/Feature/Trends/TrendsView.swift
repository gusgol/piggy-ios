import SwiftUI

// Placeholder. Built in Phase 4 (Trends).
struct TrendsView: View {
    var body: some View {
        ContentUnavailableView("Trends", systemImage: "chart.bar", description: Text("Coming in Phase 4"))
            .navigationTitle("Trends")
    }
}

#Preview {
    NavigationStack { TrendsView() }
}
