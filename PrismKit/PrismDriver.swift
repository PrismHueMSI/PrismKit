//
//  PrismController.swift
//  PrismKit
//
//  Created by Erik Bautista on 7/14/20.
//  Copyright © 2020 ErrorErrorError. All rights reserved.
//
// From https://github.com/Sherlouk/Codedeck/blob/master/Sources/HIDSwift/HIDDeviceMonitor.swift

import IOKit.hid
import Combine

public class PrismDriver {

    // MARK: Public

    public static let shared: PrismDriver = .init()

    public var deviceSubject: PassthroughSubject<PrismDevice, Never> = .init()
    public var deviceRemovalSubject: PassthroughSubject<PrismDevice, Never> = .init()
    
    // MARK: Protected

    internal var models = PrismDeviceModel.allCases.map({ $0.productInformation() })

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
            deviceSubject.send(prismDevice)
        } catch {
            Log.error("\(error)")
        }
    }

    private func deviceRemoved(rawDevice: IOHIDDevice) {
        do {
            let prismDevice = try PrismDevice(device: rawDevice)
            deviceRemovalSubject.send(prismDevice)
        } catch {
            Log.error("\(error)")
        }
    }

    deinit {
        stop()
    }
}
