//
//  SSDevice.swift
//  PrismKit
//
//  Created by Erik Bautista on 9/17/21.
//

import Foundation
import IOKit

public class SSDevice {
    let device: IOHIDDevice

    internal let id: Int
    internal let name: String
    internal let vendorId: Int
    internal let productId: Int
    internal let versionNumber: Int
    internal let primaryUsagePage: Int

    var controller: SSDeviceController?

    init(device: IOHIDDevice) throws {
        self.device = device
        id = try device.getProperty(key: kIOHIDLocationIDKey)
        name = try device.getProperty(key: kIOHIDProductKey)
        vendorId = try device.getProperty(key: kIOHIDVendorIDKey)
        productId = try device.getProperty(key: kIOHIDProductIDKey)
        versionNumber = try device.getProperty(key: kIOHIDVersionNumberKey)
        primaryUsagePage = try device.getProperty(key: kIOHIDPrimaryUsagePageKey)

        if model == .perKey || model == .perKeyGS65 {
            controller = SSPerKeyController(device: device, model: model)
        } else {
            // TODO: Handle devices with no controllers, meaning not supported
        }
    }

    public var model: SSModels {
        let product = SSModels.allCases.first(where: {
            $0.vendorId == self.vendorId &&
                $0.productId == self.productId &&
                $0.versionNumber == self.versionNumber &&
                $0.primaryUsagePage == self.primaryUsagePage
        })
        return product ?? .unknown
    }

    public func update(force: Bool) {
        if let controller = controller {
            controller.update(force: force)
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(device)
    }

    public static func == (lhs: SSDevice, rhs: SSDevice) -> Bool {
        return lhs.id == rhs.id
    }
}
