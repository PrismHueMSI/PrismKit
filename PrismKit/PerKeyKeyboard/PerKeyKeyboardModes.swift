//
//  PerKeyKeyboardModes.swift
//  PrismKit
//
//  Created by Erik Bautista on 9/16/21.
//

import Foundation

public enum PerKeyKeyboardModes: UInt32, Codable {
    case steady
    case colorShift
    case breathing
    case reactive
    case disabled
}

extension PerKeyKeyboardModes: CustomStringConvertible {
    public var description: String {
        switch self {
        case .steady: return "Steady"
        case .colorShift: return "ColorShift"
        case .breathing: return "Breathing"
        case .reactive: return "Reactive"
        case .disabled: return "Disabled"
        }
    }
}
