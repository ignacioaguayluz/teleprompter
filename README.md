# Teleprompter

Native macOS teleprompter that follows your voice locally (SpeechAnalyzer, es-MX).

## Build

```sh
brew install xcodegen
xcodegen generate          # creates Teleprompter.xcodeproj from project.yml
open Teleprompter.xcodeproj
```

Core tests: `cd TeleprompterCore && swift test`.

## Known limitations

- **First run needs the es-MX speech model.** The app asks macOS to download it
  (`AssetInventory`), so the first launch may show a download progress message.
  The app's sandbox does not include `com.apple.security.network.client`, because
  the system performs the download. This has **not** been verified on a clean
  install; if the download fails for you, please open an issue.
- Numbers spoken vs. written (for example "2026" vs. "dos mil veintiséis") are not
  matched by the voice tracker.

## License

MIT — see [LICENSE](LICENSE).
