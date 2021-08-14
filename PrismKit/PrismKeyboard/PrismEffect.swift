//
//  PrismEffects.swift
//  PrismKit
//
//  Created by Erik Bautista on 8/15/20.
//  Copyright © 2020 ErrorErrorError. All rights reserved.
//

import Foundation

public enum PrismDirection: UInt8 {
    case xy = 0
    case x = 1
    case y = 2
}

public enum PrismControl: UInt8 {
    case inward = 0
    case outward = 1
}

public final class PrismEffect: NSObject {
    public let identifier: UInt8
    public var start = PrismRGB()
    public var transitions: [PrismTransition]
    public var duration: UInt16 = 0x12c
    public var waveActive = false {
        didSet {
            if !waveActive {
                direction = .xy
                control = .inward
                origin = CGPoint()
                pulse = 100
            }
        }
    }
    public var direction = PrismDirection.xy
    public var control = PrismControl.inward
    public var origin = CGPoint()
    public var pulse: UInt16 = 100

    public init(identifier: UInt8, transitions: [PrismTransition]) {
        self.identifier = identifier
        self.transitions = transitions
        self.start = transitions.first?.color ?? PrismRGB()
        waveActive = false
    }
}

public extension PrismEffect {
    override func isEqual(_ object: Any?) -> Bool {
        guard let otherEffect = object as? PrismEffect else { return false }
        return
            self.identifier == otherEffect.identifier &&
            self.start == otherEffect.start &&
            self.waveActive == otherEffect.waveActive &&
            self.direction == otherEffect.direction &&
            self.control == otherEffect.control &&
            self.origin == otherEffect.origin &&
            self.pulse == otherEffect.pulse &&
            self.duration == otherEffect.duration &&
            self.transitions == otherEffect.transitions
    }

    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(identifier)
        hasher.combine(start)
        hasher.combine(waveActive)
        hasher.combine(direction)
        hasher.combine(control)
        hasher.combine(Int(origin.x) + Int(origin.y))
        hasher.combine(duration)
        hasher.combine(pulse)
        hasher.combine(transitions)
        return hasher.finalize()
    }
}

extension PrismEffect: Codable {

    private enum CodingKeys: String, CodingKey {
        case identifier, start, waveActive, direction, control, origin, pulse, transitions, duration
    }

    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let identifier = try container.decode(UInt8.self, forKey: .identifier)
        let transitions = try container.decode([PrismTransition].self, forKey: .transitions)
        self.init(identifier: identifier, transitions: transitions)
        self.start = try container.decode(PrismRGB.self, forKey: .start)
        self.waveActive = try container.decode(Bool.self, forKey: .waveActive)
        self.direction = PrismDirection(rawValue: try container.decode(UInt8.self, forKey: .direction)) ?? .x
        self.control = PrismControl(rawValue: try container.decode(UInt8.self, forKey: .control)) ?? .inward
        self.origin = try container.decode(CGPoint.self, forKey: .origin)
        self.pulse = try container.decode(UInt16.self, forKey: .pulse)
        self.duration = try container.decode(UInt16.self, forKey: .duration)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(start, forKey: .start)
        try container.encode(waveActive, forKey: .waveActive)
        try container.encode(direction.rawValue, forKey: .direction)
        try container.encode(control.rawValue, forKey: .control)
        try container.encode(origin, forKey: .origin)
        try container.encode(pulse, forKey: .pulse)
        try container.encode(transitions, forKey: .transitions)
        try container.encode(duration, forKey: .duration)
    }
}
