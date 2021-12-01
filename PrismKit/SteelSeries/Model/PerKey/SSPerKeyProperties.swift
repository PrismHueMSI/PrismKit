//
//  SSPerKeyProperties.swift
//  PrismKit
//
//  Created by Erik Bautista on 9/18/21.
//

import Foundation

public final class SSPerKeyProperties: SSDeviceProperties {
    var keys = [SSKey]()
    var keysSelected = [SSKey]()
    var effects = [SSKeyEffect]()
    var origin = PrismPoint()
}
