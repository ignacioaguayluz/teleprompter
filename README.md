# Teleprompter

Native macOS teleprompter that follows your voice locally (SpeechAnalyzer, es-MX).

## Build

```sh
brew install xcodegen
xcodegen generate          # creates Teleprompter.xcodeproj from project.yml
open Teleprompter.xcodeproj
```

Core tests: `cd TeleprompterCore && swift test`.

## License

MIT — see [LICENSE](LICENSE).
