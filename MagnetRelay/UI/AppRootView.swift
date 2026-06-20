import SwiftUI

enum LaunchSplashPolicy {
    private static let bypassArguments = [
        "-MagnetRelayLevelsPreview",
        "-MagnetRelaySettingsPreview",
        "-MagnetRelayGamePreview",
        "-MagnetRelaySolvedPreview",
        "-MagnetRelayCompletionPreview",
        "-MagnetRelaySkipSplash"
    ]

    static func shouldShowSplash(for arguments: [String]) -> Bool {
        !bypassArguments.contains { arguments.contains($0) }
    }
}

struct AppRootView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var isSplashVisible = true
    @State private var navigationPath = NavigationPath()

    private var launchArguments: [String] {
        ProcessInfo.processInfo.arguments
    }

    private var previewLevelID: Int {
        guard let index = launchArguments.firstIndex(of: "-MagnetRelayGamePreviewLevel"),
              launchArguments.indices.contains(index + 1),
              let levelID = Int(launchArguments[index + 1])
        else { return 1 }
        return levelID
    }

    var body: some View {
        ZStack {
            navigationRoot

            if isSplashVisible && LaunchSplashPolicy.shouldShowSplash(for: launchArguments) {
                LaunchSplashView(reduceMotion: reduceMotion, isActive: scenePhase == .active) {
                    withAnimation(.easeInOut(duration: reduceMotion ? 0.16 : 0.24)) {
                        isSplashVisible = false
                    }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .tint(SciFiTheme.cyan)
    }

    private var navigationRoot: some View {
        NavigationStack(path: $navigationPath) {
            if launchArguments.contains("-MagnetRelayLevelsPreview") {
                LevelSelectView()
            } else if launchArguments.contains("-MagnetRelaySettingsPreview") {
                SettingsView()
            } else if launchArguments.contains("-MagnetRelayGamePreview")
                || launchArguments.contains("-MagnetRelaySolvedPreview")
                || launchArguments.contains("-MagnetRelayCompletionPreview") {
                GameScreen(level: LevelCatalog.level(id: previewLevelID))
            } else {
                HomeView()
            }
        }
    }
}
