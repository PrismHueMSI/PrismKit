//
//  Color.swift
//  PrismKit
//
//  Created by Erik Bautista on 7/21/20.
//  Copyright © 2020 ErrorErrorError. All rights reserved.
//

import Foundation

public class RGB: NSObject, NSCopying, Codable {
    public var red: CGFloat {
        didSet { red.clamped(min: 0.0, max: 1.0) }
    }

    public var green: CGFloat {
        didSet { green.clamped(min: 0.0, max: 1.0) }
    }

    public var blue: CGFloat {
        didSet { blue.clamped(min: 0.0, max: 1.0) }
    }

    public var alpha: CGFloat {
        didSet { alpha.clamped(min: 0.0, max: 1.0) }
    }

    public convenience override init() {
        self.init(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    }

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1.0) {
        self.red = CGFloat(min(max(red, 0.0), 1.0))
        self.green = CGFloat(min(max(green, 0.0), 1.0))
        self.blue = CGFloat(min(max(blue, 0.0), 1.0))
        self.alpha = CGFloat(min(max(alpha, 0.0), 1.0))
    }

    public convenience init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8 = 255) {
        let rClamped = CGFloat(min(max(red, 0), 255))
        let gClamped = CGFloat(min(max(green, 0), 255))
        let bClamped = CGFloat(min(max(blue, 0), 255))
        let aClamped = CGFloat(min(max(alpha, 0), 255))
        self.init(red: rClamped / 255.0,
                  green: gClamped / 255.0,
                  blue: bClamped / 255.0,
                  alpha: aClamped / 255.0)
    }

    public convenience init(red: Int, green: Int, blue: Int, alpha: Int = 255) {
        self.init(red: UInt8(red),
                  green: UInt8(green),
                  blue: UInt8(blue),
                  alpha: UInt8(alpha))
    }

    public convenience init(hexString: String) {
        let hexString = hexString
        guard let hexInt = Int(hexString, radix: 16) else {
            self.init(red: 1.0, green: 1.0, blue: 1.0)
            return
        }

        self.init(red: CGFloat((hexInt >> 16) & 0xFF) / 255.0,
                  green: CGFloat((hexInt >> 8) & 0xFF) / 255.0,
                  blue: CGFloat((hexInt >> 0) & 0xFF) / 255.0,
                  alpha: 1.0)
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = RGB(red: red, green: green, blue: blue, alpha: alpha)
        return copy
    }

    public func delta(target: RGB, duration: UInt16) -> RGB {
        var duration = duration
        if duration < 0x21 {
            duration = 0x21
        }

        let divisible: CGFloat = CGFloat(duration * 16) / 0xff
        var deltaR = CGFloat(target.red - self.red) / divisible
        var deltaG = CGFloat(target.green - self.green) / divisible
        var deltaB = CGFloat(target.blue - self.blue) / divisible

        // Handle underflow
        if deltaR < 0.0 { deltaR += 1 }
        if deltaG < 0.0 { deltaG += 1 }
        if deltaB < 0.0 { deltaB += 1 }

        return RGB(red: deltaR, green: deltaG, blue: deltaB)
    }

    public func undoDelta(startColor: RGB, duration: UInt16) -> RGB {
        var duration = duration
        if duration < 0x21 {
            duration = 0x21
        }

        var valueR = self.red * CGFloat(duration) / 16
        var valueG = self.green * CGFloat(duration) / 16
        var valueB = self.blue * CGFloat(duration) / 16

        if valueR > 1.0 {
            valueR = ((self.red - 1.0) * CGFloat(duration) / 16)
        }

        valueR += startColor.red

        if valueG > 1.0 {
            valueG = ((self.green - 1.0) * CGFloat(duration) / 16)
        }

        valueG += startColor.green

        if valueB > 1.0 {
            valueB = ((self.blue - 1.0) * CGFloat(duration) / 16)
        }

        valueB += startColor.blue

        return RGB(red: valueR, green: valueG, blue: valueB)
    }
}

private extension CGFloat {
    mutating func clamped(min: CGFloat, max: CGFloat) {
        if self > max {
            self = max
        } else if self < min {
            self = min
        }
    }
}
