import SwiftUI

@main
struct PolyEatsApp: App {
    @State private var store = DiningStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .tint(Theme.green)
                .preferredColorScheme(.light)
        }
    }
}
