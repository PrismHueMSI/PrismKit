//
//  RGBModel+Utils.swift
//  PrismKit
//
//  Created by Erik Bautista on 12/1/21.
//

import Foundation

extension RGBColor {
    public override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? RGBColor {
            return red == object.red &&
                green == object.green &&
                blue == object.blue &&
                alpha == object.alpha
        }

        return false
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(red)
        hasher.combine(green)
        hasher.combine(blue)
        hasher.combine(alpha)
        return hasher.finalize()
    }
}

extension RGBColor {
    public var redUInt: UInt8 {
        return UInt8(round(red * 255))
    }

    public var greenUInt: UInt8 {
        return UInt8(round(green * 255))
    }

    public var blueUInt: UInt8 {
        return UInt8(round(blue * 255))
    }

    public var alphaUInt: UInt8 {
        return UInt8(round(alpha * 255))
    }
}

// MARK: Color Function Methods

extension RGBColor {
    public static func linearGradient(fromColor: RGBColor, toColor: RGBColor, percent: CGFloat) -> RGBColor {
        let red = lerp(fromValue: fromColor.red, toValue: toColor.red, percent: percent)
        let green = lerp(fromValue: fromColor.green, toValue: toColor.green, percent: percent)
        let blue = lerp(fromValue: fromColor.blue, toValue: toColor.blue, percent: percent)
        let alpha = lerp(fromValue: fromColor.alpha, toValue: toColor.alpha, percent: percent)
        return RGBColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    public static func blend(src: RGBColor, dest: RGBColor) -> RGBColor {
        let red = alphaOverlay(from: src.red, to: dest.red, alpha: src.alpha)
        let green = alphaOverlay(from: src.green, to: dest.green, alpha: src.alpha)
        let blue = alphaOverlay(from: src.blue, to: dest.blue, alpha: src.alpha)
        let alpha = 1 - (1 - src.alpha) * (1 - dest.alpha)
        return RGBColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    public static func lerp(fromValue: CGFloat, toValue: CGFloat, percent: CGFloat) -> CGFloat {
        return (toValue - fromValue) * percent + fromValue
    }

    public static func alphaOverlay(from src: CGFloat, to dest: CGFloat, alpha: CGFloat) -> CGFloat {
        return (1 - alpha) * dest + alpha * src
    }
}
