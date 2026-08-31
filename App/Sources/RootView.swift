import SwiftUI

struct RootView: View {
    @EnvironmentObject private var profile: AllergenProfile

    var body: some View {
        TabView {
            ScanView()
                .tabItem { Label("Scan", systemImage: "viewfinder") }

            ProfileView()
                .tabItem { Label("Allergens", systemImage: "list.bullet") }
                .badge(profile.isEmpty ? "!" : nil)
        }
    }
}
