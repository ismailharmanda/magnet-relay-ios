# Flux Relay Native Slice Status

## Build Target

- Bundle ID: `com.ismailharmanda.magnetrelay`
- Display name: `Flux Relay`
- Internal target/module name: `MagnetRelay`
- Platform: iPhone portrait, iOS 17+
- Version: `1.0` build `1`
- Apple Developer Team ID: `97D3P28B69`

## Release Notes

- This repo now contains the durable App Store release source of truth: Fastlane metadata, localized screenshots, legal/support pages, GitHub Actions release workflow, and XcodeGen config.
- App Store privacy answers are source-controlled as `fastlane/app_privacy_details.json`; ASC is published as "Data Not Collected" with the GitHub Pages privacy URL.
- Age rating answers are source-controlled as `fastlane/app_rating_config.json` with all content descriptors set to `NONE` and required safety flags set to `false`.
- The App Store version copyright is source-controlled as `fastlane/metadata/copyright.txt`; use `bundle exec fastlane ios submit_metadata` to resubmit metadata for an already selected build without uploading a duplicate binary.
- Monetization surfaces remain future hooks only; AdMob/IAP credentials and SDKs are intentionally absent from v1.
- App Store Connect credentials must be stored in GitHub Actions Secrets, not plaintext repo files.
- Apple currently exposes App Privacy editing through ASC web/Apple-ID session, not the API-key-only release lane; the questionnaire was completed and published in ASC on 2026-06-21.
- App Store submission completed on 2026-06-21: ASC API verified version `1.0`, build `1`, state `WAITING_FOR_REVIEW`.
