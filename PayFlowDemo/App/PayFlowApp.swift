import SwiftUI

@main
struct PayFlowApp: App {
    @StateObject private var store = ChatStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
                .tint(DemoTheme.accent)
                .preferredColorScheme(.light)
        }
    }
}
