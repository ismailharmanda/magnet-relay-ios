fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios doctor

```sh
[bundle exec] fastlane ios doctor
```

Validate local release inputs without uploading.

### ios ensure_app_record

```sh
[bundle exec] fastlane ios ensure_app_record
```

Check Apple Developer bundle id and App Store Connect app record.

### ios release

```sh
[bundle exec] fastlane ios release
```

Build, upload metadata/screenshots, and optionally submit for App Review.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
