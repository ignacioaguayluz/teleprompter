import AVFoundation
import AudioToolbox
import Synchronization

/// Opens the microphone once and fans the same buffers out to every consumer
/// (speech recognition and optional recording, S11).
final class AudioInput: @unchecked Sendable {
    /// Called on the audio render thread. The buffer is only valid during the call:
    /// consumers that work asynchronously must copy it first.
    typealias Consumer = @Sendable (AVAudioPCMBuffer, AVAudioTime) -> Void

    enum Failure: Error {
        case deviceSelection(OSStatus)
    }

    private let engine = AVAudioEngine()
    private let consumers = Mutex<[UUID: Consumer]>([:])
    private let isRunning = Mutex(false)

    /// Native format of the selected input (sample rate and channel count, S10).
    var format: AVAudioFormat { engine.inputNode.outputFormat(forBus: 0) }

    @discardableResult
    func addConsumer(_ consumer: @escaping Consumer) -> UUID {
        let id = UUID()
        consumers.withLock { $0[id] = consumer }
        return id
    }

    func removeConsumer(_ id: UUID) {
        _ = consumers.withLock { $0.removeValue(forKey: id) }
    }

    /// Routes the engine's input to `device`. Stops the engine if it is running.
    func select(_ device: AudioDevice) throws {
        stop()
        guard let unit = engine.inputNode.audioUnit else { return }
        var id = device.id
        let status = AudioUnitSetProperty(
            unit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, 0,
            &id, UInt32(MemoryLayout<AudioDeviceID>.size)
        )
        guard status == noErr else { throw Failure.deviceSelection(status) }
    }

    func start() throws {
        guard !isRunning.withLock({ $0 }) else { return }
        let node = engine.inputNode
        node.installTap(onBus: 0, bufferSize: 1024, format: node.outputFormat(forBus: 0)) { [weak self] buffer, time in
            self?.deliver(buffer, at: time)
        }
        engine.prepare()
        do {
            try engine.start()
        } catch {
            node.removeTap(onBus: 0)
            throw error
        }
        isRunning.withLock { $0 = true }
    }

    private func deliver(_ buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        for consumer in consumers.withLock({ Array($0.values) }) {
            consumer(buffer, time)
        }
    }

    func stop() {
        guard isRunning.withLock({ $0 }) else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRunning.withLock { $0 = false }
    }
}
