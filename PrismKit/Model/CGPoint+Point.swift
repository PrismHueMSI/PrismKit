//
//  CGPoint+PrismPoint.swift
//  PrismKit
//
//  Created by Erik Bautista on 9/23/20.
//  Copyright © 2020 ErrorErrorError. All rights reserved.
//

import Foundation

extension CGPoint {
    public init(xPoint: UInt16, yPoint: UInt16) {
        self.init(x: CGFloat(xPoint) / 0x105C, y: CGFloat(yPoint) / 0x040D)
    }

    public var xUInt16: UInt16 {
        return min(UInt16.max, max(UInt16(x * 0x105C), 0))
    }

    public var yUInt16: UInt16 {
        return min(UInt16.max, max(UInt16(y * 0x040D), 0))
    }
}
