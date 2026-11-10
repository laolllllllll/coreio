import SwiftUI

@main
struct CoreioApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var store = ConversationStore()
    @StateObject private var registry = ToolRegistry()
    @StateObject private var shell = ShellExecutor()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(store)
                .environmentObject(registry)
                .environmentObject(shell)
                .preferredColorScheme(settings.appearance.colorScheme)
                .onAppear {
                    // 注册内置示例工具；新增工具在此追加 register 即可
                    registry.register(TimeTool())
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Group {
            if settings.didCompleteOnboarding {
                MainChatView()
            } else {
                APIConfigView()
            }
        }
    }
}
