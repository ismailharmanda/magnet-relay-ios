import SwiftUI

@main
struct MagnetRelayApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(appModel)
                .preferredColorScheme(.dark)
        }
    }
}
