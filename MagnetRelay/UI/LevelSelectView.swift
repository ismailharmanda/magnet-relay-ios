import SwiftUI

struct LevelSelectView: View {
    @Environment(AppModel.self) private var appModel

    private let columns = [GridItem(.adaptive(minimum: 132), spacing: 12)]

    var body: some View {
        ZStack {
            SciFiTheme.backgroundGradient.ignoresSafeArea()
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(LevelCatalog.levels) { level in
                        let unlocked = level.id <= appModel.progress.unlockedLevel
                        if unlocked {
                            NavigationLink {
                                GameScreen(level: level)
                            } label: {
                                LevelTile(level: level, isComplete: appModel.progress.completedLevelIDs.contains(level.id), isLocked: false)
                            }
                            .buttonStyle(.plain)
                        } else {
                            LevelTile(level: level, isComplete: false, isLocked: true)
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Levels")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LevelTile: View {
    var level: LevelDefinition
    var isComplete: Bool
    var isLocked: Bool

    var body: some View {
        InstrumentPanel(padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(level.labCode)
                        .font(.caption.weight(.black))
                        .foregroundStyle(isLocked ? SciFiTheme.muted : SciFiTheme.cyan)
                    Spacer()
                    Image(systemName: isLocked ? "lock.fill" : isComplete ? "checkmark.seal.fill" : "wave.3.right")
                        .foregroundStyle(isLocked ? SciFiTheme.muted : isComplete ? SciFiTheme.green : SciFiTheme.amber)
                }
                Text(level.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(isLocked ? SciFiTheme.muted : SciFiTheme.text)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 7) {
                    ForEach(level.magnets.map(\.polarity), id: \.self) { polarity in
                        PolarityDot(polarity: polarity, size: 8)
                    }
                    Spacer()
                    Text("PAR \(level.parPulses)")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(SciFiTheme.muted)
                }
            }
            .frame(height: 102)
        }
        .opacity(isLocked ? 0.54 : 1)
    }
}
