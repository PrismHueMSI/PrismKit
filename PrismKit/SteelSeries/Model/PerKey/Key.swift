//
//  Key.swift
//  PrismKit
//
//  Created by Erik Bautista on 7/15/20.
//  Copyright © 2020 ErrorErrorError. All rights reserved.
//

import Foundation
import Combine

public final class Key: NSObject, ObservableObject {
    public static let empty = Key(name: "", region: 0, keycode: 0)

    public let region: UInt8
    public let keycode: UInt8
    public var name: String

    public var effect: PerKeyEffect? {
        didSet {
            if let start = effect?.transitions.first?.color {
                main = start
            }
        }
    }
    public var duration: UInt16 = 0x012c
    public var main = RGB(red: 1.0, green: 0.0, blue: 0.0)
    public var active = RGB()
    public var mode = PerKeyKeyboardModes.steady {
        willSet(value) {
            self.effect = nil
            self.duration = 0x012c
            self.main = RGB()
            self.active = RGB()
        }
    }

    public init(name: String, region: UInt8, keycode: UInt8) {
        self.name = name
        self.region = region
        self.keycode = keycode
    }
}

extension Key: Codable {
    private enum CodingKeys: CodingKey {
        case name, region, keycode, effect, duration, main, active, mode
    }

    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let region = try container.decode(UInt8.self, forKey: .region)
        let keycode = try container.decode(UInt8.self, forKey: .keycode)
        self.init(name: name, region: region, keycode: keycode)
        mode = try container.decode(PerKeyKeyboardModes.self, forKey: .mode)
        effect = try container.decodeIfPresent(PerKeyEffect.self, forKey: .effect)
        duration = try container.decode(UInt16.self, forKey: .duration)
        main = try container.decode(RGB.self, forKey: .main)
        active = try container.decode(RGB.self, forKey: .active)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(region, forKey: .region)
        try container.encode(keycode, forKey: .keycode)
        try container.encode(effect, forKey: .effect)
        try container.encode(duration, forKey: .duration)
        try container.encode(main, forKey: .main)
        try container.encode(active, forKey: .active)
        try container.encode(mode, forKey: .mode)
    }
}
