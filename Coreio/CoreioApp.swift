import SwiftUI

@main
struct CoreioApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(store.colorScheme)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Group {
            if store.isConfigured {
                MainView()
            } else {
                SetupView()
            }
        }
        .animation(.easeInOut(duration: 0.22), value: store.isConfigured)
    }
}
