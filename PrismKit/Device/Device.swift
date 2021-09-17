//
//  Device.swift
//  PrismKit
//
//  Created by Erik Bautista on 7/20/20.
//  Copyright © 2020 ErrorErrorError. All rights reserved.
//

import Foundation

public class Device {
    public typealias RawDevice = WriteDevice & FeatureReportDevice

    // MARK: Device information

    // Private

    private let device: RawDevice

    // Public

    public let id: Int
    public let name: String
    public var isKeyboardDevice: Bool {
        return [DeviceModels.perKey,
                DeviceModels.perKeyGS65,
                DeviceModels.threeRegion].contains(model)
    }

    // Internal

    internal let commandMutex = DispatchQueue(label: "prism-device-mutex")
    internal let vendorId: Int
    internal let versionNumber: Int
    internal let productId: Int
    internal let primaryUsagePage: Int

    // MARK: PrismDeviceModel

    public var model: DeviceModels {
        let product = DeviceModels.allCases.first(where: {
            $0.vendorId == self.vendorId &&
                $0.productId == self.productId &&
                $0.versionNumber == self.versionNumber &&
                $0.primaryUsagePage == self.primaryUsagePage
        })
        return product ?? .unknown
    }


    internal init(device: IOHIDDevice) throws {
        self.device = device
        id = try device.getProperty(key: kIOHIDLocationIDKey)
        name = try device.getProperty(key: kIOHIDProductKey)
        vendorId = try device.getProperty(key: kIOHIDVendorIDKey)
        productId = try device.getProperty(key: kIOHIDProductIDKey)
        primaryUsagePage = try device.getProperty(key: kIOHIDPrimaryUsagePageKey)
        versionNumber = try device.getProperty(key: kIOHIDVersionNumberKey)
    }

    public func update(force: Bool = false) {
        Log.error("Update unknown device not implemented for: \(name):\(id)")
        fatalError("Subclasses need to implement the \(#function) method.")
    }
}

// MARK: Send Feature Report / Write

internal extension Device {
    func sendFeatureReport(data: Data) -> IOReturn {
        return device.sendFeatureReport(data: data)
    }

    func write(data: Data) -> IOReturn {
        return device.write(data: data)
    }
}

// MARK: Comparison

extension Device: Equatable {
    public static func == (lhs: Device, rhs: Device) -> Bool {
        lhs.id == rhs.id
    }
}

extension Device: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


// MARK: String

extension Device: CustomStringConvertible {
    public var description: String {
        var description = ""
        description += "\nDevice: (\(name))\n"
        description += "\tID: \(id)\n"
        description += "\tVendor ID: \(vendorId)\n"
        description += "\tProduct ID: \(productId)\n"
        description += "\tPrimary Usage: \(primaryUsagePage)\n"
        description += "\tVersion Numbae: \(versionNumber)\n"
        return description
    }
}
