import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var appModel
    @State private var previewLevel: LevelDefinition?

    private var resumeLevel: LevelDefinition {
        LevelCatalog.level(id: appModel.progress.unlockedLevel)
    }

    private var shouldAutoOpenSolvedPreview: Bool {
        ProcessInfo.processInfo.arguments.contains("-MagnetRelaySolvedPreview")
            || ProcessInfo.processInfo.arguments.contains("-MagnetRelayCompletionPreview")
    }

    var body: some View {
        ZStack {
            SciFiTheme.backgroundGradient.ignoresSafeArea()
            VStack(spacing: 22) {
                Spacer(minLength: 18)
                title
                HeroBoardPreview()
                    .frame(height: 310)
                    .padding(.horizontal, 4)
                primaryActions
                solvedBadge
                Spacer(minLength: 10)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
        .navigationBarHidden(true)
        .navigationDestination(item: $previewLevel) { level in
            GameScreen(level: level)
        }
        .onAppear {
            if shouldAutoOpenSolvedPreview {
                previewLevel = LevelCatalog.level(id: 1)
            }
        }
    }

    private var title: some View {
        Text("FLUX RELAY")
            .font(.system(size: 40, weight: .black, design: .rounded))
            .foregroundStyle(SciFiTheme.text)
            .tracking(1.3)
            .minimumScaleFactor(0.72)
            .shadow(color: SciFiTheme.cyan.opacity(0.45), radius: 18)
            .accessibilityAddTraits(.isHeader)
    }

    private var primaryActions: some View {
        VStack(spacing: 12) {
            NavigationLink {
                GameScreen(level: resumeLevel)
            } label: {
                Label("Play", systemImage: "play.fill")
                    .font(.title3.weight(.black))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryLabButtonStyle(color: SciFiTheme.cyan))

            HStack(spacing: 12) {
                NavigationLink {
                    LevelSelectView()
                } label: {
                    Label("Levels", systemImage: "square.grid.3x3.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryLabButtonStyle())

                NavigationLink {
                    SettingsView()
                } label: {
                    Label("Settings", systemImage: "slider.horizontal.3")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryLabButtonStyle())
            }
        }
    }

    private var solvedBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(SciFiTheme.green)
            Text("Solved")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(SciFiTheme.text)
            Text("\(appModel.progress.completedLevelIDs.count)/\(LevelCatalog.levels.count)")
                .font(.subheadline.weight(.black))
                .foregroundStyle(SciFiTheme.green)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(SciFiTheme.green.opacity(0.10))
                .overlay(Capsule().stroke(SciFiTheme.green.opacity(0.35), lineWidth: 1))
        )
    }
}

struct HeroBoardPreview: View {
    @State private var pulse = false

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let tile = side / 5.9
            let originX = (proxy.size.width - tile * 5) / 2
            let originY = (proxy.size.height - tile * 5) / 2

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black.opacity(0.24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(SciFiTheme.cyan.opacity(0.40), lineWidth: 1.5)
                    )
                    .shadow(color: SciFiTheme.cyan.opacity(0.28), radius: 24)

                ForEach(0..<25, id: \.self) { index in
                    let x = index % 5
                    let y = index / 5
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(SciFiTheme.panel.opacity(0.92))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(SciFiTheme.panelStroke.opacity(0.85), lineWidth: 1.2)
                        )
                        .frame(width: tile * 0.86, height: tile * 0.86)
                        .position(
                            x: originX + CGFloat(x) * tile + tile / 2,
                            y: originY + CGFloat(y) * tile + tile / 2
                        )
                }

                ArcLine(
                    start: CGPoint(x: originX + tile * 1.5, y: originY + tile * 2.5),
                    end: CGPoint(x: originX + tile * 3.5, y: originY + tile * 2.5),
                    control: CGPoint(x: originX + tile * 2.5, y: originY + tile * 1.7)
                )
                .stroke(SciFiTheme.cyan.opacity(pulse ? 0.95 : 0.35), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .shadow(color: SciFiTheme.cyan.opacity(0.55), radius: 12)

                Circle()
                    .fill(SciFiTheme.cyan.opacity(0.18))
                    .overlay(Circle().stroke(SciFiTheme.cyan, lineWidth: 4))
                    .overlay(Circle().fill(SciFiTheme.cyan).frame(width: tile * 0.28, height: tile * 0.28))
                    .frame(width: tile * 0.78, height: tile * 0.78)
                    .scaleEffect(pulse ? 1.08 : 0.98)
                    .shadow(color: SciFiTheme.cyan.opacity(0.75), radius: pulse ? 22 : 12)
                    .position(x: originX + tile * 1.5, y: originY + tile * 2.5)

                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(SciFiTheme.cyan.opacity(0.40))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(.white.opacity(0.85), lineWidth: 2))
                    .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(.white.opacity(0.16)).padding(tile * 0.16))
                    .frame(width: tile * 0.70, height: tile * 0.70)
                    .offset(x: pulse ? -tile * 0.18 : 0)
                    .shadow(color: SciFiTheme.cyan.opacity(0.55), radius: 14)
                    .position(x: originX + tile * 3.5, y: originY + tile * 2.5)

                Circle()
                    .fill(SciFiTheme.green.opacity(0.16))
                    .overlay(Circle().stroke(SciFiTheme.green, lineWidth: 3))
                    .frame(width: tile * 0.70, height: tile * 0.70)
                    .shadow(color: SciFiTheme.green.opacity(0.45), radius: 14)
                    .position(x: originX + tile * 2.5, y: originY + tile * 2.5)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.05).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
        .accessibilityHidden(true)
    }
}

struct ArcLine: Shape {
    var start: CGPoint
    var end: CGPoint
    var control: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: start)
        path.addQuadCurve(to: end, control: control)
        return path
    }
}

struct ProgressBadge: View {
    var completed: Int

    var body: some View {
        VStack(spacing: 3) {
            Text("\(completed)")
                .font(.title3.weight(.black))
                .foregroundStyle(SciFiTheme.green)
            Text("Solved")
                .font(.caption2.weight(.heavy))
                .foregroundStyle(SciFiTheme.muted)
        }
        .frame(width: 72, height: 58)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(SciFiTheme.green.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(SciFiTheme.green.opacity(0.45), lineWidth: 1)
        )
    }
}

struct StatPill: View {
    var label: String
    var value: String
    var color: Color

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .shadow(color: color.opacity(0.65), radius: 7)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(SciFiTheme.muted)
            Spacer(minLength: 4)
            Text(value)
                .font(.caption.weight(.black))
                .foregroundStyle(SciFiTheme.text)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color.opacity(0.10))
        )
    }
}

struct PrimaryLabButtonStyle: ButtonStyle {
    var color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.black.opacity(0.84))
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(configuration.isPressed ? 0.72 : 1.0))
                    .shadow(color: color.opacity(configuration.isPressed ? 0.18 : 0.42), radius: 18, y: 8)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct SecondaryLabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(SciFiTheme.text)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(SciFiTheme.panel.opacity(configuration.isPressed ? 0.72 : 0.94))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(SciFiTheme.panelStroke.opacity(0.82), lineWidth: 1)
                    )
            )
    }
}
