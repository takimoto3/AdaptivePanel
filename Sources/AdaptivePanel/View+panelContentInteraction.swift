//
//  View+panelContentInteraction.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/04/08.
//  
//

import SwiftUI

/// Describes how the panel content should respond to user interaction.
public struct PanelInteraction: Sendable, Equatable {
    internal enum Kind: Sendable {
        case scrolls
        case resizes
    }
    internal let kind: Kind

    /// Lets the content scroll while the panel stays fixed.
    public static let scrolls = PanelInteraction(kind: .scrolls)
    /// Lets the panel resize instead of scrolling the content.
    public static let resizing = PanelInteraction(kind: .resizes)
}

struct PanelInteractionKey: PreferenceKey {
    static let defaultValue: PanelInteraction = .resizing
    static func reduce(value: inout PanelInteraction, nextValue: () -> PanelInteraction) {
        value = nextValue()
    }
}

extension View {
    /// Sets whether the panel content scrolls or resizes.
    public func panelContentInteraction(_ interaction: PanelInteraction) -> some View {
        self.preference(key: PanelInteractionKey.self, value: interaction)
    }
}
