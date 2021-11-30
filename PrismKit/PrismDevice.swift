//
//  PrismDevice.swift
//  PrismKit
//
//  Created by Erik Bautista on 9/19/21.
//

import Foundation

public class PrismDevice: Hashable, ObservableObject {
    public let name: String
    public let ssDevice: SSDevice

    internal let hidDevice: IOHIDDevice

    init(hidDevice: IOHIDDevice) throws {
        self.hidDevice = hidDevice
        self.ssDevice = try SSDevice(device: hidDevice)
        self.name = ssDevice.name
    }

    public func update(force: Bool) {
        if let controller = ssDevice.controller {
            controller.update(force: force)
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(hidDevice)
    }

    public static func == (lhs: PrismDevice, rhs: PrismDevice) -> Bool {
        return lhs.ssDevice.id == rhs.ssDevice.id
    }
}
