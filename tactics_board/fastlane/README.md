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

### ios upload_metadata

```sh
[bundle exec] fastlane ios upload_metadata
```

Upload metadata for a specific app (no binary)

### ios upload_all_metadata

```sh
[bundle exec] fastlane ios upload_all_metadata
```

Upload metadata for all 8 apps (no binary)

### ios upload_aso

```sh
[bundle exec] fastlane ios upload_aso
```

Upload version-level metadata only (keywords, promo, description)

### ios upload_all_aso

```sh
[bundle exec] fastlane ios upload_all_aso
```

Upload version-level metadata for all 8 apps

### ios upload_screenshots

```sh
[bundle exec] fastlane ios upload_screenshots
```

Upload screenshots for a specific app

### ios upload_all

```sh
[bundle exec] fastlane ios upload_all
```

Upload metadata + screenshots for a specific app (no binary)

### ios submit_review

```sh
[bundle exec] fastlane ios submit_review
```

Submit a specific app for review

### ios set_price_free

```sh
[bundle exec] fastlane ios set_price_free
```

Set price to free for a specific app

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
