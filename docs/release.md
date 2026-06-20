# Flux Relay Release Runbook

This repo is the durable source of truth for the iOS release. A new Mac should be able to clone the repo and rebuild the App Store package without needing hidden local files.

## Repository Source Of Truth

- Xcode project source: `project.yml`
- Generated Xcode project: `MagnetRelay.xcodeproj`
- App Store metadata: `fastlane/metadata`
- Catalog screenshots: `AppStore/Screenshots/iPhone-6.9`
- Screenshot composer: `tools/AppStoreScreenshotComposer.swift`
- Legal/support pages: `docs`
- Release workflow: `.github/workflows/ios-release.yml`

## GitHub Secrets

Set these repository secrets before running the release workflow:

- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_KEY_P8_BASE64`

Create the base64 value without printing it:

```sh
base64 -i /path/to/AuthKey_XXXXXXXXXX.p8 | gh secret set APP_STORE_CONNECT_KEY_P8_BASE64 --repo ismailharmanda/magnet-relay-ios --body-file -
```

Then set the text secrets:

```sh
printf '%s' 'KEY_ID_HERE' | gh secret set APP_STORE_CONNECT_KEY_ID --repo ismailharmanda/magnet-relay-ios --body-file -
printf '%s' 'ISSUER_ID_HERE' | gh secret set APP_STORE_CONNECT_ISSUER_ID --repo ismailharmanda/magnet-relay-ios --body-file -
```

Do not commit plaintext `.p8` files or `.env.release`.

## Local Recovery On A New Mac

```sh
git clone https://github.com/ismailharmanda/magnet-relay-ios.git
cd magnet-relay-ios
bundle install
xcodegen generate
swift tools/AppStoreScreenshotComposer.swift
xcodebuild test -scheme MagnetRelay -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

If the exact simulator name is unavailable, use the nearest installed iPhone Pro simulator.

## Release

Preferred path:

1. Push `main`.
2. Confirm GitHub Pages is live at `https://ismailharmanda.github.io/magnet-relay-ios/`.
3. Confirm the App Store Connect app record exists once:
   - Name: `Flux Relay: Magnet Puzzle`
   - Bundle ID: `com.ismailharmanda.magnetrelay`
   - SKU: `flux-relay-ios`
   - Primary locale: `en-US`
4. Run the `iOS App Store Release` workflow from GitHub Actions.
5. Leave `submit_for_review` enabled for automatic App Review submission.

The Apple Developer bundle ID can be created by Fastlane with the ASC key. The App Store Connect app record currently requires an Apple web session or Apple ID auth because API-key access cannot create `apps` resources for this account.

Local fallback:

```sh
source .env.release
bundle exec fastlane ios doctor
bundle exec fastlane ios release submit_for_review:true
```

The release lane builds `Flux Relay` version `1.0.0`, chooses the next available App Store Connect build number unless `FLUX_RELAY_BUILD_NUMBER` is set, uploads EN/TR metadata and screenshots, and requests automatic release after approval.
