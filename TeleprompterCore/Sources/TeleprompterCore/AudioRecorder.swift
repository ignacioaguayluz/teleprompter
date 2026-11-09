/// Port for the optional audio recording that runs alongside tracking (S10).
public protocol AudioRecorder: Sendable {
    /// Starts writing the microphone audio and returns the path of the new file.
    func startRecording() throws -> String
    func stopRecording()
}

/// Local date and time used to name a recording.
public struct RecordingTimestamp: Sendable, Equatable {
    public let year, month, day, hour, minute, second: Int

    public init(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int) {
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.minute = minute
        self.second = second
    }
}

/// Naming rules for recordings: `~/Movies/Teleprompter/teleprompter-YYYYMMDD-HHmmss.wav`.
public enum RecordingFileName {
    public static let folderName = "Teleprompter"

    public static func make(at stamp: RecordingTimestamp) -> String {
        let date = padded(stamp.year, 4) + padded(stamp.month) + padded(stamp.day)
        let time = padded(stamp.hour) + padded(stamp.minute) + padded(stamp.second)
        return "teleprompter-\(date)-\(time).wav"
    }

    private static func padded(_ value: Int, _ width: Int = 2) -> String {
        let digits = String(value)
        return String(repeating: "0", count: max(0, width - digits.count)) + digits
    }
}
