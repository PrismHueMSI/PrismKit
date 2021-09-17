//
//  PrismDriver.swift
//  PrismKit
//
//  Created by Erik Bautista on 7/14/20.
//  Copyright © 2020 ErrorErrorError. All rights reserved.
//
// From https://github.com/Sherlouk/Codedeck/blob/master/Sources/HIDSwift/HIDDeviceMonitor.swift

import IOKit.hid
import Combine

public class PrismDriver: ObservableObject {

    // MARK: Public

    public static let shared: PrismDriver = PrismDriver()

    @Published public var selectedDevice: Device?
    @Published public var devices: [Device] = [Device]()

    // MARK: Protected

    internal var models = DeviceModels.allCases.map({ $0.productInformation() })

    // MARK: Private

    private var monitoringThread: Thread?

    private init() {}

    public func start() {
        if monitoringThread == nil {
            monitoringThread = Thread(target: self, selector: #selector(startInternal), object: nil)
            monitoringThread?.start()
        }
    }

    @objc private func startInternal() {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        manager.setDeviceMatchingMultiple(products: models)
        manager.scheduleWithRunLoop(with: CFRunLoopGetCurrent())
        manager.open()

        let matchingCallback: IOHIDDeviceCallback = { inContext, _, _, device in
            let this = unsafeBitCast(inContext, to: PrismDriver.self)
            this.added(rawDevice: device)
        }

        let removalCallback: IOHIDDeviceCallback = { inContext, _, _, device in
            let this = unsafeBitCast(inContext, to: PrismDriver.self)
            this.removed(rawDevice: device)
        }

        let context = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
        manager.registerDeviceMatchingCallback(matchingCallback, context: context)
        manager.registerDeviceRemovalCallback(removalCallback, context: context)

        RunLoop.current.run()
    }

    public func stop() {
        monitoringThread?.cancel()
        monitoringThread = nil
    }

    // MARK: Private Methods

    private func added(rawDevice: IOHIDDevice) {
        do {
            var device = try Device(device: rawDevice)
            if device.isKeyboardDevice && device.model != .threeRegion {
                device = try PerKeyKeyboardDevice(device: rawDevice)
            }

            DispatchQueue.main.async {
                self.devices.append(device)
            }
        } catch {
            Log.error("\(error)")
        }
    }

    private func removed(rawDevice: IOHIDDevice) {
        do {
            let device = try Device(device: rawDevice)
            DispatchQueue.main.async {
                self.devices.removeAll { dev in
                    dev.id == device.id
                }
            }
        } catch {
            Log.error("\(error)")
        }
    }

    deinit {
        stop()
    }
}
