import SwiftUI

@main
struct AlergenScanApp: App {
    @StateObject private var profile = AllergenProfile()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(profile)
        }
    }
}
