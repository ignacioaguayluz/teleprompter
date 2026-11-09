@preconcurrency import AVFoundation
import Synchronization
import TeleprompterCore

/// Writes tap buffers to a linear PCM WAV file at the input's native rate and channel count (S10).
final class WAVFileWriter: @unchecked Sendable {
    private let file: AVAudioFile

    init(url: URL, format: AVAudioFormat) throws {
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: format.sampleRate,
            AVNumberOfChannelsKey: format.channelCount,
            AVLinearPCMBitDepthKey: 24,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
        ]
        file = try AVAudioFile(
            forWriting: url, settings: settings,
            commonFormat: format.commonFormat, interleaved: format.isInterleaved
        )
    }

    func write(_ buffer: AVAudioPCMBuffer) throws {
        try file.write(from: buffer)
    }

    /// Flushes and closes the file.
    func close() {
        file.close()
    }
}

/// Records the shared microphone to `~/Movies/Teleprompter/teleprompter-YYYYMMDD-HHmmss.wav`.
final class WAVRecorder: AudioRecorder, @unchecked Sendable {
    private let input: AudioInput
    private let session = Mutex<(writer: WAVFileWriter, consumer: UUID)?>(nil)

    init(input: AudioInput) {
        self.input = input
    }

    func startRecording() throws -> String {
        stopRecording()
        let url = try Self.nextFileURL()
        let writer = try WAVFileWriter(url: url, format: input.format)
        let consumer = input.addConsumer { buffer, _ in
            try? writer.write(buffer)
        }
        session.withLock { $0 = (writer, consumer) }
        return url.path
    }

    func stopRecording() {
        guard let current = session.withLock({ value in defer { value = nil }; return value }) else { return }
        input.removeConsumer(current.consumer)
        current.writer.close()
    }

    static func nextFileURL(now: Date = Date()) throws -> URL {
        let movies = try FileManager.default.url(for: .moviesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let folder = movies.appendingPathComponent(RecordingFileName.folderName, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
        let stamp = RecordingTimestamp(
            year: parts.year ?? 0, month: parts.month ?? 0, day: parts.day ?? 0,
            hour: parts.hour ?? 0, minute: parts.minute ?? 0, second: parts.second ?? 0
        )
        return folder.appendingPathComponent(RecordingFileName.make(at: stamp))
    }
}
