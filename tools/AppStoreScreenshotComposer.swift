import AppKit
import Foundation
import ImageIO

struct ScreenshotSpec {
    let rawName: String
    let outputName: String
    let title: String
    let subtitle: String
}

struct LocaleSpec {
    let identifier: String
    let screenshots: [ScreenshotSpec]
}

let canvasWidth = 1320
let canvasHeight = 2868
let rawDirectory = URL(fileURLWithPath: "AppStore/Screenshots/raw/iPhone-17-Pro-Max", isDirectory: true)

let locales: [LocaleSpec] = [
    LocaleSpec(
        identifier: "en-US",
        screenshots: [
            ScreenshotSpec(
                rawName: "01-home.png",
                outputName: "01-flux-relay.png",
                title: "Flux Relay",
                subtitle: "Field Logic With Magnets"
            ),
            ScreenshotSpec(
                rawName: "02-tutorial-mr01.png",
                outputName: "02-shape-magnetic-fields.png",
                title: "Shape Magnetic Fields",
                subtitle: "Drag magnets. Pulse the grid."
            ),
            ScreenshotSpec(
                rawName: "03-solved-mr01.png",
                outputName: "03-lock-every-socket.png",
                title: "Lock Every Socket",
                subtitle: "Guide charged blocks into place."
            ),
            ScreenshotSpec(
                rawName: "04-advanced-mr12.png",
                outputName: "04-master-multi-polarity-grids.png",
                title: "Master Multi-Polarity Grids",
                subtitle: "Cyan, amber, and violet logic."
            ),
            ScreenshotSpec(
                rawName: "05-level-select.png",
                outputName: "05-pick-up-quick-lab-runs.png",
                title: "Pick Up Quick Lab Runs",
                subtitle: "Compact puzzles for short sessions."
            )
        ]
    ),
    LocaleSpec(
        identifier: "tr-TR",
        screenshots: [
            ScreenshotSpec(
                rawName: "01-home.png",
                outputName: "01-flux-relay.png",
                title: "Flux Relay",
                subtitle: "Mıknatıslarla Alan Mantığı"
            ),
            ScreenshotSpec(
                rawName: "02-tutorial-mr01.png",
                outputName: "02-manyetik-alanlari-sekillendir.png",
                title: "Manyetik Alanları Şekillendir",
                subtitle: "Mıknatısları sürükle. Izgarayı tetikle."
            ),
            ScreenshotSpec(
                rawName: "03-solved-mr01.png",
                outputName: "03-tum-soketleri-kilitle.png",
                title: "Tüm Soketleri Kilitle",
                subtitle: "Yüklü blokları doğru hedefe taşı."
            ),
            ScreenshotSpec(
                rawName: "04-advanced-mr12.png",
                outputName: "04-cok-kutuplu-izgaralar.png",
                title: "Çok Kutuplu Izgaralar",
                subtitle: "Camgöbeği, amber ve mor mantık."
            ),
            ScreenshotSpec(
                rawName: "05-level-select.png",
                outputName: "05-kisa-lab-turlari.png",
                title: "Kısa Lab Turları",
                subtitle: "Kısa molalara uygun bulmacalar."
            )
        ]
    )
]

func rectFromTop(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> NSRect {
    NSRect(x: x, y: CGFloat(canvasHeight) - y - height, width: width, height: height)
}

func color(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1) -> NSColor {
    NSColor(red: red, green: green, blue: blue, alpha: alpha)
}

func makeTextAttributes(size: CGFloat, weight: NSFont.Weight, color: NSColor) -> [NSAttributedString.Key: Any] {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    paragraph.lineBreakMode = .byClipping

    return [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color,
        .paragraphStyle: paragraph
    ]
}

func fittedFontSize(for text: String, startingAt size: CGFloat, weight: NSFont.Weight, maxWidth: CGFloat) -> CGFloat {
    var candidate = size
    while candidate > 36 {
        let attributes = makeTextAttributes(size: candidate, weight: weight, color: .white)
        let measured = (text as NSString).boundingRect(
            with: NSSize(width: CGFloat.greatestFiniteMagnitude, height: 160),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes
        )
        if measured.width <= maxWidth {
            return candidate
        }
        candidate -= 2
    }
    return candidate
}

func drawCenteredText(_ text: String, y: CGFloat, height: CGFloat, size: CGFloat, weight: NSFont.Weight, color: NSColor) {
    let maxWidth = CGFloat(canvasWidth - 160)
    let finalSize = fittedFontSize(for: text, startingAt: size, weight: weight, maxWidth: maxWidth)
    let attributes = makeTextAttributes(size: finalSize, weight: weight, color: color)
    let rect = rectFromTop(x: 80, y: y, width: maxWidth, height: height)
    (text as NSString).draw(in: rect, withAttributes: attributes)
}

func drawBackground(in context: CGContext) {
    context.saveGState()

    let baseSpace = CGColorSpaceCreateDeviceRGB()
    let colors = [
        color(red: 0.010, green: 0.014, blue: 0.020).cgColor,
        color(red: 0.020, green: 0.034, blue: 0.046).cgColor,
        color(red: 0.040, green: 0.026, blue: 0.052).cgColor
    ] as CFArray
    let gradient = CGGradient(colorsSpace: baseSpace, colors: colors, locations: [0.0, 0.58, 1.0])!
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: CGFloat(canvasHeight)),
        end: CGPoint(x: CGFloat(canvasWidth), y: 0),
        options: []
    )

    let glowColors = [
        color(red: 0.05, green: 0.82, blue: 0.95, alpha: 0.20).cgColor,
        color(red: 0.05, green: 0.82, blue: 0.95, alpha: 0.00).cgColor
    ] as CFArray
    let glow = CGGradient(colorsSpace: baseSpace, colors: glowColors, locations: [0.0, 1.0])!
    context.drawRadialGradient(
        glow,
        startCenter: CGPoint(x: CGFloat(canvasWidth) * 0.5, y: CGFloat(canvasHeight) * 0.45),
        startRadius: 40,
        endCenter: CGPoint(x: CGFloat(canvasWidth) * 0.5, y: CGFloat(canvasHeight) * 0.45),
        endRadius: 860,
        options: [.drawsAfterEndLocation]
    )

    context.restoreGState()
}

func drawPhoneScreen(_ image: NSImage, in rect: NSRect) {
    let shadowPath = NSBezierPath(roundedRect: rect, xRadius: 72, yRadius: 72)
    NSGraphicsContext.current?.saveGraphicsState()
    NSShadow().apply {
        $0.shadowColor = color(red: 0.02, green: 0.84, blue: 0.98, alpha: 0.18)
        $0.shadowOffset = NSSize(width: 0, height: -10)
        $0.shadowBlurRadius = 38
    }
    color(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.64).setFill()
    shadowPath.fill()
    NSGraphicsContext.current?.restoreGraphicsState()

    NSGraphicsContext.current?.saveGraphicsState()
    shadowPath.addClip()
    image.draw(in: rect, from: .zero, operation: .copy, fraction: 1.0)
    NSGraphicsContext.current?.restoreGraphicsState()

    color(red: 0.10, green: 0.78, blue: 0.92, alpha: 0.42).setStroke()
    shadowPath.lineWidth = 2
    shadowPath.stroke()
}

extension NSShadow {
    func apply(_ configure: (NSShadow) -> Void) {
        configure(self)
        set()
    }
}

func compose(_ spec: ScreenshotSpec, outputDirectory: URL) throws {
    let rawURL = rawDirectory.appendingPathComponent(spec.rawName)
    let outputURL = outputDirectory.appendingPathComponent(spec.outputName)

    guard let rawImage = NSImage(contentsOf: rawURL) else {
        throw NSError(domain: "ScreenshotComposer", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Unable to load raw screenshot at \(rawURL.path)"
        ])
    }

    NSGraphicsContext.saveGraphicsState()
    let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.noneSkipLast.rawValue
    guard let context = CGContext(
        data: nil,
        width: canvasWidth,
        height: canvasHeight,
        bitsPerComponent: 8,
        bytesPerRow: canvasWidth * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: bitmapInfo
    ) else {
        throw NSError(domain: "ScreenshotComposer", code: 2, userInfo: [
            NSLocalizedDescriptionKey: "Unable to create drawing context."
        ])
    }
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)

    drawBackground(in: context)

    drawCenteredText(spec.title, y: 144, height: 116, size: 82, weight: .black, color: color(red: 0.92, green: 0.97, blue: 1.0))
    drawCenteredText(spec.subtitle, y: 274, height: 66, size: 42, weight: .semibold, color: color(red: 0.58, green: 0.91, blue: 0.98))

    let screenWidth: CGFloat = 1016
    let screenHeight = screenWidth * CGFloat(canvasHeight) / CGFloat(canvasWidth)
    let screenRect = rectFromTop(
        x: (CGFloat(canvasWidth) - screenWidth) / 2,
        y: 570,
        width: screenWidth,
        height: screenHeight
    )
    drawPhoneScreen(rawImage, in: screenRect)

    NSGraphicsContext.restoreGraphicsState()

    guard let image = context.makeImage(),
          let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, "public.png" as CFString, 1, nil) else {
        throw NSError(domain: "ScreenshotComposer", code: 3, userInfo: [
            NSLocalizedDescriptionKey: "Unable to encode PNG for \(outputURL.path)"
        ])
    }

    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw NSError(domain: "ScreenshotComposer", code: 4, userInfo: [
            NSLocalizedDescriptionKey: "Unable to write PNG for \(outputURL.path)"
        ])
    }
}

for locale in locales {
    let outputDirectory = URL(fileURLWithPath: "AppStore/Screenshots/iPhone-6.9/\(locale.identifier)", isDirectory: true)
    try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

    for spec in locale.screenshots {
        try compose(spec, outputDirectory: outputDirectory)
        print(outputDirectory.appendingPathComponent(spec.outputName).path)
    }
}
