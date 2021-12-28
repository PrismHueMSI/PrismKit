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

public final class PrismDriver: NSObject {

    // MARK: Public

    public static let shared: PrismDriver = PrismDriver()
    public var deviceSubject: PassthroughSubject<SSDevice, Never> = .init()

    // MARK: Protected

    internal var models = SSModels.allCases.map({ $0.productInformation() })

    // MARK: Private

    private var monitoringThread: Thread?

    private override init() {}

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
            this.add(rawDevice: device)
        }

        let removalCallback: IOHIDDeviceCallback = { inContext, _, _, device in
            let this = unsafeBitCast(inContext, to: PrismDriver.self)
            this.remove(rawDevice: device)
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

    private func add(rawDevice: IOHIDDevice) {
        do {
            let device = try SSDevice(device: rawDevice)
            DispatchQueue.main.async {
                self.deviceSubject.send(device)
            }
        } catch {
            Log.error("\(error)")
        }
    }

    private func remove(rawDevice: IOHIDDevice) {
        do {
            let _ = try SSDevice(device: rawDevice)
            DispatchQueue.main.async {
//                self.deviceSubject.send(device)
                // TODO: Notify when a device is removed.
            }
        } catch {
            Log.error("\(error)")
        }
    }

    deinit {
        stop()
    }
}
