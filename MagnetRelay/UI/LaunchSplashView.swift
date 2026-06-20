import SwiftUI

struct LaunchSplashView: View {
    var reduceMotion: Bool
    var isActive: Bool
    var onFinished: () -> Void

    @State private var isCharged = false
    @State private var isHandingOff = false
    @State private var didStart = false
    @State private var ringRotation = 0.0
    @State private var sweepOffset = 0.0

    var body: some View {
        GeometryReader { proxy in
            let logoSide = min(proxy.size.width * 0.58, proxy.size.height * 0.28)

            ZStack {
                SplashLabBackground(isCharged: isCharged, isHandingOff: isHandingOff)

                SplashFieldGeometry(
                    isCharged: isCharged,
                    isHandingOff: isHandingOff,
                    ringRotation: ringRotation,
                    sweepOffset: sweepOffset
                )

                VStack(spacing: 20) {
                    Spacer()

                    Image("FluxRelaySplashLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: logoSide, height: logoSide)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(SciFiTheme.cyan.opacity(isCharged ? 0.38 : 0.14), lineWidth: 1.2)
                        )
                        .scaleEffect(isHandingOff ? 1.42 : (isCharged ? 1.0 : 0.84))
                        .opacity(isHandingOff ? 0.0 : 1.0)
                        .shadow(color: SciFiTheme.cyan.opacity(isCharged ? 0.72 : 0.22), radius: isCharged ? 42 : 18)
                        .shadow(color: SciFiTheme.violet.opacity(isCharged ? 0.34 : 0.10), radius: isCharged ? 30 : 10)

                    Text("FLUX RELAY")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(SciFiTheme.text)
                        .opacity(isHandingOff ? 0.0 : (isCharged ? 0.92 : 0.0))
                        .shadow(color: SciFiTheme.cyan.opacity(0.40), radius: 16)

                    Spacer()
                }
                .offset(y: isHandingOff ? -28 : 0)
            }
        }
        .ignoresSafeArea()
        .accessibilityLabel("Flux Relay launch screen")
        .task(id: isActive) {
            await startIfReady()
        }
    }

    @MainActor
    private func startIfReady() async {
        guard isActive, !didStart else { return }
        didStart = true
        try? await Task.sleep(nanoseconds: reduceMotion ? 80_000_000 : 160_000_000)
        await runSequence()
    }

    @MainActor
    private func runSequence() async {
        if reduceMotion {
            withAnimation(.easeOut(duration: 0.14)) {
                isCharged = true
            }
            try? await Task.sleep(nanoseconds: 350_000_000)
            withAnimation(.easeInOut(duration: 0.18)) {
                isHandingOff = true
            }
            try? await Task.sleep(nanoseconds: 180_000_000)
            onFinished()
            return
        }

        withAnimation(.spring(response: 0.46, dampingFraction: 0.78)) {
            isCharged = true
        }
        withAnimation(.linear(duration: 1.15).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }
        withAnimation(.easeInOut(duration: 0.82).repeatForever(autoreverses: true)) {
            sweepOffset = 1
        }

        try? await Task.sleep(nanoseconds: 1_020_000_000)
        withAnimation(.easeInOut(duration: 0.38)) {
            isHandingOff = true
        }
        try? await Task.sleep(nanoseconds: 380_000_000)
        onFinished()
    }
}

private struct SplashLabBackground: View {
    var isCharged: Bool
    var isHandingOff: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.008, green: 0.012, blue: 0.018),
                    Color(red: 0.018, green: 0.030, blue: 0.040),
                    Color(red: 0.040, green: 0.024, blue: 0.052)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Canvas { context, size in
                var grid = Path()
                let spacing: CGFloat = 28
                for x in stride(from: CGFloat.zero, through: size.width, by: spacing) {
                    grid.move(to: CGPoint(x: x, y: 0))
                    grid.addLine(to: CGPoint(x: x, y: size.height))
                }
                for y in stride(from: CGFloat.zero, through: size.height, by: spacing) {
                    grid.move(to: CGPoint(x: 0, y: y))
                    grid.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(grid, with: .color(SciFiTheme.cyan.opacity(0.045)), lineWidth: 0.8)
            }

            RadialGradient(
                colors: [
                    SciFiTheme.cyan.opacity(isCharged ? 0.32 : 0.08),
                    SciFiTheme.violet.opacity(isCharged ? 0.13 : 0.04),
                    Color.clear
                ],
                center: .center,
                startRadius: 16,
                endRadius: isHandingOff ? 680 : 420
            )

            Color.black
                .opacity(isHandingOff ? 0.0 : 0.08)
        }
    }
}

private struct SplashFieldGeometry: View {
    var isCharged: Bool
    var isHandingOff: Bool
    var ringRotation: Double
    var sweepOffset: Double

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width * 0.86, proxy.size.height * 0.44)
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)

            ZStack {
                SplashScanBeam(offset: sweepOffset)
                    .opacity(isHandingOff ? 0.0 : (isCharged ? 0.9 : 0.0))

                ForEach(0..<4, id: \.self) { index in
                    let scale = 0.68 + CGFloat(index) * 0.19
                    Circle()
                        .stroke(SciFiTheme.cyan.opacity(0.20 - Double(index) * 0.025), lineWidth: 1.2)
                        .frame(width: side * scale, height: side * scale)
                        .scaleEffect(isHandingOff ? 2.6 : (isCharged ? 1.0 : 0.72))
                        .opacity(isHandingOff ? 0.0 : (isCharged ? 1.0 : 0.0))
                        .position(center)
                }

                ForEach(0..<3, id: \.self) { index in
                    let color = [SciFiTheme.cyan, SciFiTheme.amber, SciFiTheme.violet][index]
                    Ellipse()
                        .trim(from: 0.035, to: 0.965)
                        .stroke(
                            color.opacity(isCharged ? 0.82 : 0.18),
                            style: StrokeStyle(lineWidth: 3.4, lineCap: .round)
                        )
                        .frame(width: side * 1.08, height: side * 0.42)
                        .rotationEffect(.degrees(Double(index) * 60 + ringRotation * (index == 1 ? -0.35 : 0.25)))
                        .scaleEffect(isHandingOff ? 1.95 : (isCharged ? 1.0 : 0.78))
                        .opacity(isHandingOff ? 0.0 : 1.0)
                        .shadow(color: color.opacity(0.42), radius: 16)
                        .position(center)
                }

                Circle()
                    .trim(from: 0.08, to: 0.34)
                    .stroke(
                        SciFiTheme.cyan.opacity(0.95),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .frame(width: side * 0.94, height: side * 0.94)
                    .rotationEffect(.degrees(ringRotation))
                    .scaleEffect(isHandingOff ? 2.2 : (isCharged ? 1.0 : 0.72))
                    .opacity(isHandingOff ? 0.0 : (isCharged ? 1.0 : 0.0))
                    .shadow(color: SciFiTheme.cyan.opacity(0.58), radius: 22)
                    .position(center)
            }
        }
    }
}

private struct SplashScanBeam: View {
    var offset: Double

    var body: some View {
        GeometryReader { proxy in
            let y = proxy.size.height * (0.34 + CGFloat(offset) * 0.32)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            SciFiTheme.cyan.opacity(0.26),
                            Color.white.opacity(0.18),
                            SciFiTheme.cyan.opacity(0.26),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .position(x: proxy.size.width / 2, y: y)
                .shadow(color: SciFiTheme.cyan.opacity(0.55), radius: 18)
        }
    }
}
