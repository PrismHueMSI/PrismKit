//
//  SSKeyEffectStruct.swift
//  PrismKit
//
//  Created by Erik Bautista on 12/24/21.
//

import Foundation
import Combine


public struct SSKeyEffect {

    // MARK: Identifier
    // If id = -1, that means the identifier has not been set yet.
    public var id: UInt8

    // MARK: Transitions

    public var transitions: [SSPerKeyTransition]

    // MARK: Start color

    public var start = RGB()

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

    public init(id: UInt8, transitions: [SSPerKeyTransition]) {
        self.id = id
        self.transitions = transitions
        self.start = transitions.first?.color ?? RGB()
    }
}

public extension SSKeyEffect {
    enum SSPerKeyDirection: UInt8, CaseIterable, CustomStringConvertible, Codable {
        case xy = 0
        case x = 1
        case y = 2

        public var description: String {
            switch (self) {
            case .xy:
                return "XY"
            case .x:
                return "X"
            case .y:
                return "Y"
            }
        }
    }

    enum SSPerKeyControl: UInt8, CaseIterable, CustomStringConvertible, Codable {
        case inward = 0
        case outward = 1

        public var description: String {
            switch (self) {
            case .inward:
                return "Inward"
            case .outward:
                return "Outward"
            }
        }
    }

    struct SSPerKeyTransition: Codable, Hashable {
        public var color = RGB()
        public var position: CGFloat = 0x21 / 0xBB8

        public init(color: RGB, position: CGFloat) {
            self.color = color
            self.position = position
        }
    }

    struct SSPoint: Hashable, Codable {
        public var x: UInt16 = 0
        public var y: UInt16 = 0

        public init() {
            x = 0
            y = 0
        }

        public init(x: UInt16, y: UInt16) {
            self.x = x
            self.y = y
        }
    }
}

// MARK: - Codable Extension

extension SSKeyEffect: Codable {}

// MARK: - Hash Extension

extension SSKeyEffect: Hashable {
    func dataEqual(with effect: SSKeyEffect) -> Bool {
        return self.start == effect.start &&
        self.transitions == effect.transitions &&
        self.waveActive == effect.waveActive &&
        self.direction == effect.direction &&
        self.control == effect.control &&
        self.pulse == effect.pulse &&
        self.duration == effect.duration &&
        self.origin == effect.origin
    }
//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(id)
//        hasher.combine(transitions)
//        hasher.combine(start)
//        hasher.combine(duration)
//        hasher.combine(waveActive)
//        hasher.combine(direction)
//        hasher.combine(control)
//        hasher.combine(pulse)
//        hasher.combine(origin)
//    }
//
//    public static func == (lhs: SSKeyEffect, rhs: SSKeyEffect) -> Bool {
//        return lhs.id == rhs.id &&
//        lhs.transitions == rhs.transitions &&
//        lhs.start == rhs.start &&
//        lhs.duration == rhs.duration &&
//        lhs.waveActive == rhs.waveActive &&
//        lhs.direction == rhs.direction &&
//        lhs.control == rhs.control &&
//        lhs.pulse == rhs.pulse &&
//        lhs.origin == rhs.origin
//    }
}
