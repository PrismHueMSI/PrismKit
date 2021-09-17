//
//  main.swift
//  PrismKitTest
//
//  Created by Erik Bautista on 8/6/21.
//

import Foundation
import PrismKit
import Combine

var cancellables: Set<AnyCancellable> = .init()

let driver = PrismDriver.shared

driver.deviceSubject.sink { device in
    print("received device: " + device.name)
    if let keyboard = device as? PerKeyKeyboardDevice {
        _ = keyboard.keys.map { key -> [UInt8:UInt8] in
            print(String(format: "[0x%02x:0x%02X],", key.region, key.keycode), terminator: "")
            return [key.region:key.keycode]
        }
    }
}
.store(in: &cancellables)

driver.start()

Thread.sleep(forTimeInterval: 5)
