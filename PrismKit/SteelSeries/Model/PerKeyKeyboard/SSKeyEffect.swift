//
//  SSKeyEffect.swift
//  PrismKit
//
//  Created by Erik Bautista on 8/15/20.
//  Copyright © 2020 ErrorErrorError. All rights reserved.
//

import Foundation
import Combine


public final class SSKeyEffect: NSObject {

    // MARK: Identifier

    public let id: UInt8

    // MARK: Start color

    public var start = RGB()

    // MARK: Transitions

    public var transitions: [SSPerKeyTransition]

    // MARK: Duration

    public var duration: UInt16 = 0x12c

    // MARK: Wave Settings

    public var waveActive = false {
        didSet {
            if !waveActive {
                direction = .xy
                control = .inward
                origin.x = 0
                origin.y = 0
                pulse = 100
            }
        }
    }
    public var direction = SSPerKeyDirection.xy
    public var control = SSPerKeyControl.inward
    public var origin = SSPoint()
    public var pulse: UInt16 = 100

    public init(identifier: UInt8, transitions: [SSPerKeyTransition]) {
        self.id = identifier
        self.transitions = transitions
        self.start = transitions.first?.color ?? RGB()
        waveActive = false
    }
}

extension SSKeyEffect {
    public struct SSPoint: Equatable, Codable {
        var x = 0
        var y = 0
    }

    public enum SSPerKeyDirection: UInt8 {
        case xy = 0
        case x = 1
        case y = 2
    }

    public enum SSPerKeyControl: UInt8 {
        case inward = 0
        case outward = 1
    }

    public class SSPerKeyTransition: NSObject, Codable {
        public var color = RGB()
        public var position: CGFloat = 0x21 / 0xBB8

        public init(color: RGB, position: CGFloat) {
            self.color = color
            self.position = position
        }

        public override func isEqual(_ object: Any?) -> Bool {
            guard let otherTransition = object as? SSPerKeyTransition else { return false }
            return self.color == otherTransition.color &&
                self.position == otherTransition.position
        }

        public override var hash: Int {
            var hasher = Hasher()
            hasher.combine(color)
            hasher.combine(position)
            return hasher.finalize()
        }
    }
}

// MARK: - Hash Extension

public extension SSKeyEffect {
    override func isEqual(_ object: Any?) -> Bool {
        guard let otherEffect = object as? SSKeyEffect else { return false }
        return
            self.id == otherEffect.id &&
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
        hasher.combine(id)
        hasher.combine(start)
        hasher.combine(waveActive)
        hasher.combine(direction)
        hasher.combine(control)
        hasher.combine(origin.x + origin.y)
        hasher.combine(duration)
        hasher.combine(pulse)
        hasher.combine(transitions)
        return hasher.finalize()
    }
}

// MARK: - Codable Extension

extension SSKeyEffect: Codable {

    private enum CodingKeys: String, CodingKey {
        case identifier, start, waveActive, direction, control, origin, pulse, transitions, duration
    }

    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let identifier = try container.decode(UInt8.self, forKey: .identifier)
        let transitions = try container.decode([SSPerKeyTransition].self, forKey: .transitions)
        self.init(identifier: identifier, transitions: transitions)
        self.start = try container.decode(RGB.self, forKey: .start)
        self.waveActive = try container.decode(Bool.self, forKey: .waveActive)
        self.direction = SSPerKeyDirection(rawValue: try container.decode(UInt8.self, forKey: .direction)) ?? .x
        self.control = SSPerKeyControl(rawValue: try container.decode(UInt8.self, forKey: .control)) ?? .inward
        self.origin = try container.decode(SSPoint.self, forKey: .origin)
        self.pulse = try container.decode(UInt16.self, forKey: .pulse)
        self.duration = try container.decode(UInt16.self, forKey: .duration)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .identifier)
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
