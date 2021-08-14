//
//  PrismDeviceKeyboard.swift
//  PrismKit
//
//  Created by Erik Bautista on 8/15/20.
//  Copyright © 2020 ErrorErrorError. All rights reserved.
//

import Foundation

public final class PrismDeviceKeyboard: PrismDevice {

    public static let packageSize = 0x20c

    // Keys array

    public var keys = [PrismKey]()

    // Selected keys array

    public var keysSelected = [PrismKey]()

    // Effects array

    public var effects = [PrismEffect]()

    // Origin

    public let origin = CGPoint()

    public override func update(forceUpdate: Bool = false) {
        if isKeyboardDevice, model != .threeRegion {
            updatePerKeyKeyboard(forceUpdate: forceUpdate)
        } else {
            // TODO: Update three region keyboard
            Log.error("This model is incompartible: Three Region Keyboard")
        }
    }

    override init(device: IOHIDDevice) throws {
        try super.init(device: device)
        guard isKeyboardDevice && model != .threeRegion  else {
            fatalError("This device is currently unsupported.")
        }

        let keyboardKeyNames = model == .perKey ? PrismDeviceKeyboard.perKeyNames : PrismDeviceKeyboard.perKeyGS65KeyNames
        let keycodeArray = (model == .perKey ? PrismDeviceKeyboard.perKeyRegionKeyCodes : PrismDeviceKeyboard.perKeyGS65RegionKeyCodes)

        for (rowIndex, row) in keycodeArray.enumerated() {
            for (columnIndex, value) in row.enumerated() {
                let keySymbol = keyboardKeyNames[rowIndex][columnIndex]
                let key = PrismKey(name: keySymbol, region: value.0, keycode: value.1)
                keys.append(key)
            }
        }
    }

    deinit {
        keys.removeAll()
        keysSelected.removeAll()
        effects.removeAll()
    }
}

// PerKeyKeyboard methods

extension PrismDeviceKeyboard {

    private func writeEffectsToKeyboard() -> IOReturn {
        let effects = effects
        guard effects.count > 0 else {
            Log.debug("No available effects found for: \(model)")
            return kIOReturnNotFound
        }

        for effect in effects {
            guard effect.transitions.count > 0 else {
                // Must have at least one transition or will return error
                Log.error("An effect has no transitions for \(model). Will not update keyboard with effect due to it can cause bricking keyboard.")
                return kIOReturnError
            }

            var data = Data(capacity: PrismDeviceKeyboard.packageSize)
            data.append([0x0b, 0x00], count: 2) // Start Packet

            let totalDuration = effect.duration

            // Transitions - each transition will take 8 bytes
            let transitions = effect.transitions
            for (index, transition) in transitions.enumerated() {
                let idx = UInt8(index)

                let nextTransition = (index + 1) < transitions.count ? transitions[index + 1] : transitions[0]

                var deltaPosition =  nextTransition.position - transition.position
                if deltaPosition < 0 { deltaPosition += 1.0 }

                let duration = UInt16((deltaPosition * CGFloat(totalDuration)) / 10)

                // Calculate color difference

                let colorDelta = transition.color.delta(target: nextTransition.color, duration: duration)

                data.append([index == 0 ? effect.identifier : idx,
                             0x0,
                             colorDelta.redUInt,
                             colorDelta.greenUInt,
                             colorDelta.blueUInt,
                             0x0,
                             UInt8(duration & 0x00ff),
                             UInt8(duration >> 8)
                ], count: 8)
            }

            // Fill spaces
            var fillZeros = [UInt8](repeating: 0x00, count: 0x84 - data.count)
            data.append(fillZeros, count: fillZeros.count)

            // Set starting color, each value will have 2 bytes
            data.append([(effect.start.redUInt & 0x0f) << 4,
                         (effect.start.redUInt & 0xf0) >> 4,
                         (effect.start.greenUInt & 0x0f) << 4,
                         (effect.start.greenUInt & 0xf0) >> 4,
                         (effect.start.blueUInt & 0x0f) << 4,
                         (effect.start.blueUInt & 0xf0) >> 4,
                         0xff,
                         0x00
            ], count: 8)

            // Wave mode

            if effect.waveActive {
                let origin = effect.origin

                data.append([UInt8(origin.xUInt16 & 0x00ff),
                             UInt8(origin.xUInt16 >> 8),
                             UInt8(origin.yUInt16 & 0x00ff),
                             UInt8(origin.yUInt16 >> 8),
                             effect.direction != .y ? 0x01 : 0x00,
                             0x00,
                             effect.direction != .x ? 0x01 : 0x00,
                             0x00,
                             UInt8(effect.pulse & 0x00ff),
                             UInt8(effect.pulse >> 8)
                ], count: 10)
            } else {
                fillZeros = [UInt8](repeating: 0x00, count: 10)
                data.append(fillZeros, count: fillZeros.count)
            }

            data.append([UInt8(effect.transitions.count),
                         0x00,
                         UInt8(effect.duration & 0x00ff),
                         UInt8(effect.duration >> 8),
                         effect.control.rawValue
            ], count: 5)

            // Fill remaining with zeros
            fillZeros = [UInt8](repeating: 0x00, count: PrismDeviceKeyboard.packageSize - data.count)
            data.append(fillZeros, count: fillZeros.count)

            let result = sendFeatureReport(data: data)
            guard result == kIOReturnSuccess else {
                Log.error("Could not send effect to \(model): \(String(cString: mach_error_string(result)))")
                return result
            }
        }
        return kIOReturnSuccess
    }

    private func updatePerKeyKeyboard(forceUpdate: Bool = false) {
        commandMutex.async {
            let keysSelected = self.keysSelected
            guard keysSelected.count > 0 || forceUpdate else { return }

            let updateModifiers = keysSelected.filter { $0.region == PrismDeviceKeyboard.regions[0] }
                                              .count > 0 || forceUpdate
            let updateAlphanums = keysSelected.filter { $0.region == PrismDeviceKeyboard.regions[1] }
                                              .count > 0 || forceUpdate
            let updateEnter = keysSelected.filter { $0.region == PrismDeviceKeyboard.regions[2] }
                                              .count > 0 || forceUpdate
            let updateSpecial = keysSelected.filter { $0.region == PrismDeviceKeyboard.regions[3] }
                                            .count > 0 || forceUpdate

            // Update effects first

            var result = self.writeEffectsToKeyboard()
            guard result == kIOReturnSuccess || result == kIOReturnNotFound else {
                Log.error("Cannot update effect for \(self.model): \(String(cString: mach_error_string(result)))")
                return
            }

            // Send feature report

            var lastByte: UInt8 = 0
            if updateModifiers {
                lastByte = 0x2d
                let result = self.writeKeysToKeyboard(region: PrismDeviceKeyboard.regions[0],
                                                      keycodes: PrismDeviceKeyboard.modifiers)
                if result != kIOReturnSuccess {
                    Log.error("Error sending feature report for modifiers; \(self.model): " +
                                "\(String(cString: mach_error_string(result)))")
                    return
                }
            }

            if updateAlphanums {
                lastByte = 0x08
                let result = self.writeKeysToKeyboard(region: PrismDeviceKeyboard.regions[1],
                                                      keycodes: PrismDeviceKeyboard.alphanums)
                if result != kIOReturnSuccess {
                    Log.error("Error sending feature report for alphanums; \(self.model): " +
                                "\(String(cString: mach_error_string(result)))")
                    return
                }
            }

            if updateEnter {
                lastByte = 0x87
                let result = self.writeKeysToKeyboard(region: PrismDeviceKeyboard.regions[2],
                                                      keycodes: PrismDeviceKeyboard.enter)
                if result != kIOReturnSuccess {
                    Log.error("Error sending feature report for enter key; \(self.model): " +
                                "\(String(cString: mach_error_string(result)))")
                    return
                }
            }

            if updateSpecial {
                lastByte = 0x44
                let result = self.writeKeysToKeyboard(region: PrismDeviceKeyboard.regions[3],
                                                      keycodes: self.model == .perKey ?
                                                        PrismDeviceKeyboard.special :
                                                        PrismDeviceKeyboard.specialGS65)
                if result != kIOReturnSuccess {
                    Log.error("Error sending feature report for special; \(self.model): " +
                                "\(String(cString: mach_error_string(result)))")
                    return
                }
            }

            // Update keyboard

            result = self.writeToPerKeyKeyboard(lastByte: lastByte)
            if result != kIOReturnSuccess {
                Log.error("Error writing to \(self.model): \(String(cString: mach_error_string(result)))")
            }
        }
    }

    private func writeToPerKeyKeyboard(lastByte: UInt8) -> IOReturn {
        var data = Data(capacity: 0x40)
        data.append([0x0d, 0x0, 0x02], count: 3)
        data.append([UInt8](repeating: 0, count: 60), count: 60)
        data.append([lastByte], count: 1)
        return write(data: data)
    }

    private func writeKeysToKeyboard(region: UInt8, keycodes: [UInt8]) -> IOReturn {
        var data = Data(capacity: PrismDeviceKeyboard.packageSize)

        // This array contains only the usable keys
        let keyboardKeys = keys.filter { $0.region == region }

        for keyCode in [region] + keycodes {
            if let key = keyboardKeys.filter({ $0.keycode == keyCode }).first {
                var mode: UInt8 = 0
                switch key.mode {
                case .steady:
                    mode = 0x01
                case .reactive:
                    mode = 0x08
                case .disabled:
                    mode = 0x03
                default:
                    mode = 0
                }

                if key.keycode == key.region {
                    data.append([0x0e, 0x0, key.keycode, 0x0], count: 4)
                } else {
                    data.append([0x0, key.keycode], count: 2)
                }

                data.append([key.main.redUInt,
                             key.main.greenUInt,
                             key.main.blueUInt,
                             key.active.redUInt,
                             key.active.greenUInt,
                             key.active.blueUInt,
                             UInt8(key.duration & 0x00ff),
                             UInt8(key.duration >> 8),
                             key.effect?.identifier ?? 0,
                             mode], count: 10)
            } else {
                data.append([0x0,
                             keyCode,
                             0, 0, 0, 0, 0, 0,
                             0x2c,
                             0x01,
                             0, 0], count: 12)
            }
        }

        // Fill rest of data with the remaining capacity
        let sizeRemaining = PrismDeviceKeyboard.packageSize - data.count
        data.append([UInt8](repeating: 0, count: sizeRemaining), count: sizeRemaining)
        return sendFeatureReport(data: data)
    }

    private func getRegionKey(_ char: String, keycode: UInt8) -> UInt8 {
        var region: UInt8
        if char.contains("ESC") {
            region = PrismDeviceKeyboard.regions[0]
        } else if char == "A" {
            region = PrismDeviceKeyboard.regions[1]
        } else if char.contains("ENTER") {
            region = PrismDeviceKeyboard.regions[2]
        } else if char == "F7" {
            region = PrismDeviceKeyboard.regions[3]
        } else {
            region = getRegionFromKeycode(keycode)
        }
        return region
    }

    private func getRegionFromKeycode(_ keycode: UInt8) -> UInt8 {
        for key in PrismDeviceKeyboard.modifiers where key == keycode {
            return PrismDeviceKeyboard.regions[0]
        }

        for key in PrismDeviceKeyboard.alphanums where key == keycode {
            return PrismDeviceKeyboard.regions[1]
        }

        for key in PrismDeviceKeyboard.enter where key == keycode {
            return PrismDeviceKeyboard.regions[2]
        }

        for key in PrismDeviceKeyboard.special where key == keycode {
            return PrismDeviceKeyboard.regions[3]
        }

        return 0
    }
}

enum PrismError: Error {
    case runtimeError(String)
}
