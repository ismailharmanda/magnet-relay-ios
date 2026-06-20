# Flux Relay App Store Metadata

## Localized Listings

### English `en-US`

- App Store name: Flux Relay: Magnet Puzzle
- Subtitle: Field Logic With Magnets
- Keywords: grid,blocks,pulse,polarity,charge,socket,brain,teaser,levels,physics,lab
- Privacy URL: https://ismailharmanda.github.io/magnet-relay-ios/privacy.html
- Support URL: https://ismailharmanda.github.io/magnet-relay-ios/support.html
- Marketing URL: https://ismailharmanda.github.io/magnet-relay-ios/

### Turkish `tr-TR`

- App Store name: Flux Relay: Magnet Puzzle
- Subtitle: Mıknatıslarla Alan Mantığı
- Keywords: bulmaca,miknatis,alan,blok,puls,kutup,soket,zeka,seviye,mantik,fizik,lab
- Privacy URL: https://ismailharmanda.github.io/magnet-relay-ios/privacy.html
- Support URL: https://ismailharmanda.github.io/magnet-relay-ios/support.html
- Marketing URL: https://ismailharmanda.github.io/magnet-relay-ios/

## Validation

- English App Store name length: 25 / 30 characters
- Subtitle length: 24 / 30 characters
- Keywords length: 72 / 100 bytes
- Turkish subtitle length: 26 / 30 characters
- Turkish keywords length: 76 / 100 bytes

## Screenshot Set

- Locales: `en-US`, `tr-TR`
- Device family: iPhone 6.9"
- Final size: 1320x2868 PNG, RGB, no alpha
- Raw captures: `AppStore/Screenshots/raw/iPhone-17-Pro-Max/`
- Final exports: `AppStore/Screenshots/iPhone-6.9/{locale}/`
- Composer: `swift tools/AppStoreScreenshotComposer.swift`

### English

| File | Title | Subtitle | Source screen |
|---|---|---|---|
| `01-flux-relay.png` | Flux Relay | Field Logic With Magnets | Home |
| `02-shape-magnetic-fields.png` | Shape Magnetic Fields | Drag magnets. Pulse the grid. | MR-01 tutorial gameplay |
| `03-lock-every-socket.png` | Lock Every Socket | Guide charged blocks into place. | MR-01 solved gameplay |
| `04-master-multi-polarity-grids.png` | Master Multi-Polarity Grids | Cyan, amber, and violet logic. | MR-12 advanced gameplay |
| `05-pick-up-quick-lab-runs.png` | Pick Up Quick Lab Runs | Compact puzzles for short sessions. | Level select |

### Turkish

| File | Title | Subtitle | Source screen |
|---|---|---|---|
| `01-flux-relay.png` | Flux Relay | Mıknatıslarla Alan Mantığı | Home |
| `02-manyetik-alanlari-sekillendir.png` | Manyetik Alanları Şekillendir | Mıknatısları sürükle. Izgarayı tetikle. | MR-01 tutorial gameplay |
| `03-tum-soketleri-kilitle.png` | Tüm Soketleri Kilitle | Yüklü blokları doğru hedefe taşı. | MR-01 solved gameplay |
| `04-cok-kutuplu-izgaralar.png` | Çok Kutuplu Izgaralar | Camgöbeği, amber ve mor mantık. | MR-12 advanced gameplay |
| `05-kisa-lab-turlari.png` | Kısa Lab Turları | Kısa molalara uygun bulmacalar. | Level select |

## Notes

- Public display name in the app binary: Flux Relay
- Internal target/module names remain MagnetRelay for now.
- Primary category: Games. Subcategory: Puzzle. Age rating target: 4+.
- v1 privacy stance: no data collected, no tracking, no account, no ads/IAP.
- Privacy source: `fastlane/app_privacy_details.json` (`DATA_NOT_COLLECTED`); published in ASC on 2026-06-21 with the GitHub Pages privacy URL.
- Age rating automation source: `fastlane/app_rating_config.json` (all content descriptors `NONE`, no gambling, no unrestricted web access, no 17+ flag).
- Preflight name check on 2026-06-20 found no exact `Flux Relay` software title in the US Apple Search API results; this is not a reservation or legal clearance.
- Run final App Store Connect reservation and trademark clearance before submission.
