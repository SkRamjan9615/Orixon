# Changelog

## [1.1.0] - 2026-11-19
### Added
- Migrated production Android & iOS Package/Bundle ID to `org.orixon.app`.
- Full iPhone & iPad (`ios/Runner/Info.plist`) permissions and background audio configuration.
- Modern AndroidX `FileProvider` for Android 14/15 system sharing and predictive back gesture support.
- 350ms debounced full-app hardware gyroscope rotation with Screen Lock pause and `SharedPreferences` sync.
- F-Droid / IzzyOnDroid reproducible build configuration (`includeInApk = false`) and `fastlane` metadata.
- Official Privacy Policy (`privacy.html`), Terms of Use (`terms.html`), and `SHA256SUMS.txt` release verification.

### Removed
- Removed legacy `StrictMode.VmPolicy` workaround, dead Nearby Share stubs, duplicate root SEO files, and temporary scripts.

## [1.0.0] - 2026-11-16
- Initial public release of ORIXON Smart TV OS Launcher, Live IPTV M3U Studio, 4K HDR10 & VR 360/3D Media Hub, File Hub, and DuckDuckGo WebX Browser.
