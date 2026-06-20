# Flux Relay iOS Guardrails

- Native iOS first: keep the slice iPhone portrait, iOS 17+, SwiftUI shell, SpriteKit gameplay.
- Do not import Construct or Phaser assets into this product repo. Procedural placeholders are acceptable until owned art is commissioned or verified.
- Keep puzzle rules deterministic in Swift model code; SpriteKit physics can create feel, but solved state must come from validated grid state.
- UI should feel like a sci-fi lab instrument panel: compact, readable, premium, and touch-friendly.
- When changing gameplay, update or add XCTest coverage for rules, snap logic, undo, progress, or physics tuning.
