//
//  PerKeyTransition.swift
//  PrismKit
//
//  Created by Erik Bautista on 9/23/20.
//  Copyright © 2020 ErrorErrorError. All rights reserved.
//

import Foundation

public class PerKeyTransition: NSObject, Codable {
    public var color = RGB()
    public var position: CGFloat = 0x21 / 0xBB8

    public init(color: RGB, position: CGFloat) {
        self.color = color
        self.position = position
    }
}

extension PerKeyTransition {
    public override func isEqual(_ object: Any?) -> Bool {
        guard let otherTransition = object as? PerKeyTransition else { return false }
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
