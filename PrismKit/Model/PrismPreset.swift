//
//  Preset.swift
//  PrismKit
//
//  Created by Erik Bautista on 9/22/20.
//  Copyright © 2020 ErrorErrorError. All rights reserved.
//

import Cocoa

public class PrismPreset: NSObject {
    public var title: String = ""
    public var type: PresetType = .defaultPreset
    public var url: URL?
    public var children = [PrismPreset]()

    public init(title: String = "", type: PresetType = .defaultPreset) {
        self.title = title
        self.type = type
    }
}

public enum PresetType: Int, CaseIterable, Codable {
    case defaultPreset
    case customPreset
}

public extension PrismPreset {
    var isDirectory: Bool {
        url?.hasDirectoryPath ?? true
    }

    @objc var count: Int {
        children.count
    }

    @objc var isLeaf: Bool {
        children.isEmpty && !isDirectory
    }
}
