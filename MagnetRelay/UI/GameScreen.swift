import SpriteKit
import SwiftUI

struct GameScreen: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var controller: GameController
    @State private var internalTapCount = 0

    init(level: LevelDefinition) {
        _controller = State(initialValue: GameController(level: level))
    }

    private var internalDebugEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-MagnetRelayInternalDebug")
            || ProcessInfo.processInfo.environment["MAGNET_RELAY_DEBUG"] == "1"
            || internalTapCount >= 7
    }

    private var shouldShowSolvedPreview: Bool {
        ProcessInfo.processInfo.arguments.contains("-MagnetRelaySolvedPreview")
    }

    private var shouldShowCompletionPreview: Bool {
        ProcessInfo.processInfo.arguments.contains("-MagnetRelayCompletionPreview")
    }

    var body: some View {
        ZStack {
            SciFiTheme.labBlack.ignoresSafeArea()
            SpriteView(scene: controller.scene, options: [.allowsTransparency])
                .ignoresSafeArea()
                .accessibilityLabel("Flux Relay game board")

            VStack(spacing: 0) {
                GameHUD(level: controller.level, state: controller.state)
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
                    .onTapGesture {
                        #if DEBUG
                        internalTapCount += 1
                        #endif
                    }
                GameObjectiveBar(level: controller.level, state: controller.state)
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                Spacer(minLength: 0)
                if let message = controller.message {
                    MessageStrip(message: message)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 8)
                }
                GameActionBar(controller: controller)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
            }

            #if DEBUG
            if internalDebugEnabled {
                DebugPanel(controller: controller)
                    .padding(.horizontal, 14)
                    .padding(.top, 104)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            #endif

            if let completion = controller.completion {
                LevelCompletionOverlay(
                    presentation: completion,
                    reduceMotion: reduceMotion
                ) {
                    controller.advanceFromCompletion()
                }
                .transition(.opacity)
            }
        }
        .navigationTitle(controller.level.labCode)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            controller.bind(appModel: appModel)
            controller.setSlowMotion(reduceMotion ? false : controller.slowMotionEnabled)
            if shouldShowCompletionPreview {
                controller.showCompletionPreview()
            } else if shouldShowSolvedPreview {
                controller.showSolvedPreview()
            }
        }
    }
}

struct GameHUD: View {
    var level: LevelDefinition
    var state: GameState

    var body: some View {
        InstrumentPanel(padding: 10) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.labCode)
                        .font(.caption.weight(.black))
                        .foregroundStyle(SciFiTheme.cyan)
                    Text(level.title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(SciFiTheme.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                Spacer()
                HUDMetric(label: "Moves", value: "\(state.moves)")
                HUDMetric(label: "Pulse", value: "\(state.pulses)/\(level.parPulses)")
            }
        }
    }
}

struct GameObjectiveBar: View {
    var level: LevelDefinition
    var state: GameState

    private var objective: String {
        if level.id == 1 {
            return "Pull cyan block into cyan socket."
        }
        if level.targets.count == 1, let target = level.targets.first {
            return "Pull \(target.polarity.displayName.lowercased()) block into its socket."
        }
        return "Lock every block into a matching socket."
    }

    private var showsGestureHint: Bool {
        level.id == 1 && state.moves == 0 && state.pulses == 0 && !state.solved
    }

    var body: some View {
        VStack(spacing: 5) {
            Text(objective)
                .font(.subheadline.weight(.black))
                .foregroundStyle(SciFiTheme.text)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            if showsGestureHint {
                Text("Drag magnet to pulse.")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SciFiTheme.cyan)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(SciFiTheme.panel.opacity(0.74))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(SciFiTheme.cyan.opacity(0.36), lineWidth: 1)
                )
        )
    }
}

struct HUDMetric: View {
    var label: String
    var value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.headline, design: .rounded, weight: .black))
                .foregroundStyle(SciFiTheme.text)
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(SciFiTheme.muted)
        }
        .frame(width: 62, height: 42)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(SciFiTheme.cyan.opacity(0.09))
        )
    }
}

struct MessageStrip: View {
    var message: String

    var body: some View {
        Text(message)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(SciFiTheme.text)
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(SciFiTheme.panel.opacity(0.88))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(SciFiTheme.amber.opacity(0.52), lineWidth: 1)
                    )
            )
    }
}

struct GameActionBar: View {
    var controller: GameController

    var body: some View {
        InstrumentPanel(padding: 10) {
            HStack(spacing: 9) {
                Button {
                    controller.undo()
                } label: {
                    Label("Undo", systemImage: controller.state.canUndo ? "arrow.uturn.backward" : "play.rectangle")
                        .labelStyle(.iconOnly)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ActionIconButtonStyle(color: controller.state.canUndo ? SciFiTheme.cyan : SciFiTheme.amber))

                Button {
                    controller.hint()
                } label: {
                    Label("Hint", systemImage: "lightbulb.fill")
                        .labelStyle(.iconOnly)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ActionIconButtonStyle(color: SciFiTheme.amber))

                Button {
                    controller.reset()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .labelStyle(.iconOnly)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ActionIconButtonStyle(color: SciFiTheme.crimson))

                if controller.state.solved && controller.completion == nil {
                    Button {
                        controller.nextLevel()
                    } label: {
                        Label("Next", systemImage: "arrow.right.circle.fill")
                            .labelStyle(.iconOnly)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ActionIconButtonStyle(color: SciFiTheme.green))
                }
            }
        }
    }
}

struct LevelCompletionOverlay: View {
    var presentation: LevelCompletionPresentation
    var reduceMotion: Bool
    var onAdvance: () -> Void

    @State private var panelVisible = false
    @State private var crosshairSpinning = false
    @State private var countdownProgress = 0.0
    @State private var isAdvancing = false
    @State private var scanlineProgress = 0.0

    private var autoDelay: TimeInterval {
        reduceMotion ? 2.0 : 3.0
    }

    private var ctaTitle: String {
        if let nextLabCode = presentation.nextLabCode {
            return "Next \(nextLabCode)"
        }
        return "Replay"
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                SciFiTheme.labBlack.opacity(panelVisible && !(isAdvancing && reduceMotion) ? 0.62 : 0.0)
                    .ignoresSafeArea()
                    .animation(.easeOut(duration: 0.18), value: isAdvancing)
                    .animation(.easeOut(duration: 0.18), value: panelVisible)

                VStack(spacing: 16) {
                    completionPanel
                        .frame(maxWidth: 336)
                        .scaleEffect(panelVisible ? 1 : 0.92)
                        .opacity(panelVisible && !(isAdvancing && reduceMotion) ? 1 : 0)
                        .shadow(color: SciFiTheme.cyan.opacity(panelVisible ? 0.32 : 0), radius: 28, y: 12)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .padding(.horizontal, 20)

                if !reduceMotion {
                    scanline(in: geometry.size)
                        .opacity(isAdvancing ? 1 : 0)
                        .allowsHitTesting(false)
                }
            }
            .accessibilityElement(children: .contain)
        }
        .task(id: presentation.id) {
            await runPresentation()
        }
    }

    private var completionPanel: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(SciFiTheme.green.opacity(0.34), lineWidth: 2)
                    .frame(width: 86, height: 86)
                    .shadow(color: SciFiTheme.green.opacity(0.36), radius: 18)
                Image("KenneyCrosshairColorA")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 62, height: 62)
                    .rotationEffect(.degrees(crosshairSpinning && !reduceMotion ? 360 : 0))
                    .animation(
                        reduceMotion ? nil : .linear(duration: 2.4).repeatForever(autoreverses: false),
                        value: crosshairSpinning
                    )
            }
            .accessibilityHidden(true)

            VStack(spacing: 5) {
                Text("FIELD STABLE")
                    .font(.caption.weight(.black))
                    .foregroundStyle(SciFiTheme.green)
                    .tracking(1.1)
                Text("Level Complete")
                    .font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundStyle(SciFiTheme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Text("\(presentation.labCode) calibrated. Excellent work.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SciFiTheme.text.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }

            HStack(spacing: 8) {
                CompletionMetric(label: "Moves", value: "\(presentation.moves)")
                CompletionMetric(label: "Pulse", value: "\(presentation.pulses)/\(presentation.parPulses)")
                CompletionMetric(label: presentation.hasNextLevel ? "Next" : "Mode", value: presentation.nextLabCode ?? "Replay")
            }

            CountdownRail(progress: countdownProgress)
                .frame(height: 24)
                .padding(.top, 2)

            Button {
                Task {
                    await beginAdvance()
                }
            } label: {
                Label(ctaTitle, systemImage: presentation.hasNextLevel ? "arrow.right.circle.fill" : "arrow.clockwise.circle.fill")
                    .font(.headline.weight(.black))
                    .foregroundStyle(Color.black.opacity(0.86))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        Image("KenneyButtonRectangleDepth")
                            .resizable(capInsets: EdgeInsets(top: 32, leading: 72, bottom: 32, trailing: 72), resizingMode: .stretch)
                            .interpolation(.high)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(ctaTitle)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .background(
            Image("KenneyPanelGlassNotches")
                .resizable(capInsets: EdgeInsets(top: 38, leading: 38, bottom: 38, trailing: 38), resizingMode: .stretch)
                .interpolation(.high)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(SciFiTheme.labBlack.opacity(0.32))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(SciFiTheme.cyan.opacity(0.44), lineWidth: 1)
                )
        )
    }

    private func scanline(in size: CGSize) -> some View {
        let travel = size.width + 160
        let x = -80 + travel * scanlineProgress
        return ZStack {
            Rectangle()
                .fill(SciFiTheme.cyan.opacity(0.20))
                .frame(width: 92, height: size.height * 1.4)
                .blur(radius: 16)
                .offset(x: x - size.width / 2)
            Rectangle()
                .fill(SciFiTheme.cyan.opacity(0.74))
                .frame(width: 3, height: size.height * 1.4)
                .shadow(color: SciFiTheme.cyan.opacity(0.95), radius: 18)
                .offset(x: x - size.width / 2)
        }
    }

    @MainActor
    private func runPresentation() async {
        panelVisible = false
        crosshairSpinning = false
        countdownProgress = 0
        isAdvancing = false
        scanlineProgress = 0

        try? await Task.sleep(nanoseconds: reduceMotion ? 120_000_000 : 480_000_000)
        guard !Task.isCancelled else { return }

        withAnimation(reduceMotion ? .easeOut(duration: 0.14) : .spring(response: 0.34, dampingFraction: 0.78)) {
            panelVisible = true
        }
        crosshairSpinning = true

        withAnimation(.linear(duration: autoDelay)) {
            countdownProgress = 1
        }

        try? await Task.sleep(nanoseconds: UInt64(autoDelay * 1_000_000_000))
        guard !Task.isCancelled else { return }
        await beginAdvance()
    }

    @MainActor
    private func beginAdvance() async {
        guard !isAdvancing else { return }
        isAdvancing = true

        if reduceMotion {
            withAnimation(.easeOut(duration: 0.16)) {
                panelVisible = false
            }
            try? await Task.sleep(nanoseconds: 180_000_000)
        } else {
            withAnimation(.easeInOut(duration: 0.46)) {
                scanlineProgress = 1
                panelVisible = false
            }
            try? await Task.sleep(nanoseconds: 480_000_000)
        }

        guard !Task.isCancelled else { return }
        onAdvance()
    }
}

struct CompletionMetric: View {
    var label: String
    var value: String

    var body: some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(SciFiTheme.text.opacity(0.68))
            Text(value)
                .font(.caption.weight(.black))
                .foregroundStyle(SciFiTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.64)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(SciFiTheme.cyan.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(SciFiTheme.cyan.opacity(0.20), lineWidth: 1)
                )
        )
    }
}

struct CountdownRail: View {
    var progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Image("KenneyProgressRail")
                    .resizable(capInsets: EdgeInsets(top: 12, leading: 46, bottom: 12, trailing: 46), resizingMode: .stretch)
                    .interpolation(.high)
                    .opacity(0.46)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [SciFiTheme.green, SciFiTheme.cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(8, (proxy.size.width - 20) * progress), height: 7)
                    .padding(.horizontal, 10)
                    .shadow(color: SciFiTheme.green.opacity(0.55), radius: 8)
            }
        }
        .accessibilityHidden(true)
    }
}

struct ActionIconButtonStyle: ButtonStyle {
    var color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.heavy))
            .foregroundStyle(color)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(configuration.isPressed ? 0.20 : 0.11))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(color.opacity(0.48), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

#if DEBUG
struct DebugPanel: View {
    var controller: GameController
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                Label("Debug", systemImage: "wrench.and.screwdriver.fill")
                    .font(.caption.weight(.bold))
            }
            .buttonStyle(SecondaryLabButtonStyle())

            if isExpanded {
                InstrumentPanel(padding: 10) {
                    VStack(alignment: .leading, spacing: 10) {
                        Menu("Jump: \(controller.level.labCode)") {
                            ForEach(LevelCatalog.levels) { level in
                                Button("\(level.labCode) \(level.title)") {
                                    controller.load(level: level)
                                }
                            }
                        }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(SciFiTheme.text)

                        Toggle("Slow motion", isOn: Binding(
                            get: { controller.slowMotionEnabled },
                            set: { controller.setSlowMotion($0) }
                        ))
                        Toggle("Hitboxes", isOn: Binding(
                            get: { controller.hitboxesVisible },
                            set: { controller.setHitboxesVisible($0) }
                        ))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Magnetic force \(String(format: "%.2f", controller.magneticForceMultiplier))x")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(SciFiTheme.muted)
                            Slider(value: Binding(
                                get: { controller.magneticForceMultiplier },
                                set: { controller.setMagneticForceMultiplier($0) }
                            ), in: 0.55...1.65)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(SciFiTheme.text)
                    .tint(SciFiTheme.cyan)
                }
                .frame(maxWidth: 280)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
#endif
