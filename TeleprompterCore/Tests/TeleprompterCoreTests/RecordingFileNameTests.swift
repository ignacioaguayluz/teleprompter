import Testing
@testable import TeleprompterCore

@Suite struct RecordingFileNameTests {
    @Test func usesTimestampWithZeroPadding() {
        let stamp = RecordingTimestamp(year: 2026, month: 3, day: 7, hour: 9, minute: 5, second: 2)
        #expect(RecordingFileName.make(at: stamp) == "teleprompter-20260307-090502.wav")
    }

    @Test func keepsTwoDigitFieldsAsIs() {
        let stamp = RecordingTimestamp(year: 2026, month: 11, day: 9, hour: 23, minute: 59, second: 30)
        #expect(RecordingFileName.make(at: stamp) == "teleprompter-20261109-235930.wav")
    }

    @Test func folderIsTeleprompterInsideMovies() {
        #expect(RecordingFileName.folderName == "Teleprompter")
    }
}
