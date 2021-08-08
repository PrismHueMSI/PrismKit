//
//  PrismController.swift
//  PrismKit
//
//  Created by Erik Bautista on 7/14/20.
//  Copyright © 2020 ErrorErrorError. All rights reserved.
//
// From https://github.com/Sherlouk/Codedeck/blob/master/Sources/HIDSwift/HIDDeviceMonitor.swift

import Cocoa
import IOKit.hid

public class PrismDriver: NSObject {

    // MARK: Public

    public static let shared = PrismDriver()
    public var currentDevice: PrismDevice?
    public var devices = [PrismDevice]()

    // MARK: Protected

    internal var models = PrismDeviceModel.allCases.map({ $0.productInformation() })

    // MARK: Private

    private var monitoringThread: Thread?

    private override init() {
        super.init()
        monitoringThread = Thread(target: self, selector: #selector(start), object: nil)
        monitoringThread?.start()
    }

    @objc func start() {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        manager.setDeviceMatchingMultiple(products: models)
        manager.scheduleWithRunLoop(with: CFRunLoopGetCurrent())
        manager.open()

        let matchingCallback: IOHIDDeviceCallback = { inContext, _, _, device in
            let this = unsafeBitCast(inContext, to: PrismDriver.self)
            this.deviceAdded(rawDevice: device)
        }

        let removalCallback: IOHIDDeviceCallback = { inContext, _, _, device in
            let this = unsafeBitCast(inContext, to: PrismDriver.self)
            this.deviceRemoved(rawDevice: device)
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

    private func deviceAdded(rawDevice: IOHIDDevice) {
        do {
            var prismDevice = try PrismDevice(device: rawDevice)
            if prismDevice.isKeyboardDevice {
                prismDevice = try PrismDeviceKeyboard(device: rawDevice)
            }
            self.devices.append(prismDevice)
            Log.debug("Added device: \(prismDevice)")
            NotificationCenter.default.post(name: .prismDeviceAdded, object: prismDevice)
        } catch {
            Log.error("\(error)")
        }
    }

    private func deviceRemoved(rawDevice: IOHIDDevice) {
        do {
            let prismDevice = try PrismDevice(device: rawDevice)
            let deviceIndex = devices.firstIndex { device in
                prismDevice.identification == device.identification
            }
            if let deviceInArray = deviceIndex {
                self.devices.remove(at: deviceInArray)
                Log.debug("Removed device: \(prismDevice)")
                NotificationCenter.default.post(name: .prismDeviceRemoved, object: deviceInArray)
            }
        } catch {
            Log.error("\(error)")
        }
    }

    deinit {
        stop()
    }
}

public extension Notification.Name {
    static let prismDeviceAdded = Notification.Name(rawValue: "prismDeviceAdded")
    static let prismDeviceRemoved = Notification.Name(rawValue: "prismDeviceRemoved")
}
