import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var appModel
    @State private var showResetConfirmation = false

    var body: some View {
        ZStack {
            SciFiTheme.backgroundGradient.ignoresSafeArea()
            VStack(spacing: 16) {
                InstrumentPanel {
                    VStack(spacing: 14) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(SciFiTheme.green)
                        Text("Solved")
                            .font(.title2.weight(.black))
                            .foregroundStyle(SciFiTheme.text)
                        Text("\(appModel.progress.completedLevelIDs.count)/\(LevelCatalog.levels.count)")
                            .font(.title.weight(.black))
                            .foregroundStyle(SciFiTheme.green)
                    }
                    .frame(maxWidth: .infinity)
                }

                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    Label("Reset Progress", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryLabButtonStyle())

                Spacer()
            }
            .padding(20)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Reset Progress?", isPresented: $showResetConfirmation, titleVisibility: .visible) {
            Button("Reset", role: .destructive) {
                appModel.resetProgress()
            }
        }
    }
}
