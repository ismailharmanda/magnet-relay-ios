# Flux Relay Native Slice Status

## Build Target

- Bundle ID: `com.ismailharmanda.magnetrelay`
- Display name: `Flux Relay`
- Internal target/module name: `MagnetRelay`
- Platform: iPhone portrait, iOS 17+
- Version: `1.0.0` build `1`
- Apple Developer Team ID: `97D3P28B69`

## Release Notes

- This repo now contains the durable App Store release source of truth: Fastlane metadata, localized screenshots, legal/support pages, GitHub Actions release workflow, and XcodeGen config.
- Monetization surfaces remain future hooks only; AdMob/IAP credentials and SDKs are intentionally absent from v1.
- App Store Connect credentials must be stored in GitHub Actions Secrets, not plaintext repo files.
