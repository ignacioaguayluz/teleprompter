import CoreAudio

/// An audio input device as reported by CoreAudio. `uid` is stable across launches; `id` is not.
struct AudioDevice: Identifiable, Hashable, Sendable {
    let id: AudioDeviceID
    let uid: String
    let name: String
}

/// Reads the system's audio input devices from CoreAudio.
enum AudioDeviceCatalog {
    static func inputDevices() -> [AudioDevice] {
        let ids: [AudioDeviceID] = readArray(
            object: AudioObjectID(kAudioObjectSystemObject),
            selector: kAudioHardwarePropertyDevices
        )
        return ids.compactMap { id in
            guard inputChannelCount(of: id) > 0,
                  let uid = readString(object: id, selector: kAudioDevicePropertyDeviceUID),
                  let name = readString(object: id, selector: kAudioObjectPropertyName)
            else { return nil }
            return AudioDevice(id: id, uid: uid, name: name)
        }
    }

    static func defaultInputDevice() -> AudioDevice? {
        var id = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = propertyAddress(kAudioHardwarePropertyDefaultInputDevice)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &id
        )
        guard status == noErr else { return nil }
        return inputDevices().first { $0.id == id }
    }

    static func device(withUID uid: String) -> AudioDevice? {
        inputDevices().first { $0.uid == uid }
    }

    private static func inputChannelCount(of device: AudioDeviceID) -> Int {
        var address = propertyAddress(kAudioDevicePropertyStreamConfiguration, scope: kAudioObjectPropertyScopeInput)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(device, &address, 0, nil, &size) == noErr, size > 0 else { return 0 }
        let raw = UnsafeMutableRawPointer.allocate(byteCount: Int(size), alignment: MemoryLayout<AudioBufferList>.alignment)
        defer { raw.deallocate() }
        guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, raw) == noErr else { return 0 }
        let list = UnsafeMutableAudioBufferListPointer(raw.assumingMemoryBound(to: AudioBufferList.self))
        return list.reduce(0) { $0 + Int($1.mNumberChannels) }
    }

    private static func readString(object: AudioObjectID, selector: AudioObjectPropertySelector) -> String? {
        var address = propertyAddress(selector)
        var value: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        guard AudioObjectGetPropertyData(object, &address, 0, nil, &size, &value) == noErr,
              let value else { return nil }
        return value.takeRetainedValue() as String
    }

    private static func readArray<T>(object: AudioObjectID, selector: AudioObjectPropertySelector) -> [T] {
        var address = propertyAddress(selector)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(object, &address, 0, nil, &size) == noErr else { return [] }
        let count = Int(size) / MemoryLayout<T>.stride
        let pointer = UnsafeMutablePointer<T>.allocate(capacity: count)
        defer { pointer.deallocate() }
        guard AudioObjectGetPropertyData(object, &address, 0, nil, &size, pointer) == noErr else { return [] }
        return Array(UnsafeBufferPointer(start: pointer, count: count))
    }

    private static func propertyAddress(
        _ selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal
    ) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain)
    }
}
