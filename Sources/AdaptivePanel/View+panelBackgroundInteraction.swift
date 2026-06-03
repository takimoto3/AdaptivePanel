//
//  View+panelBackgroundInteraction.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/04/19.
//  
//

import SwiftUI
import UIKit

public struct PanelBackgroundInteraction: Equatable, Sendable {
    internal enum InteractionType: Equatable, Sendable {
        case disabled
        case enabled(upThrough: PanelDetent?)
    }
    internal let type: InteractionType

    /// Disables background interaction behind the panel.
    public static var disabled: Self { .init(type: .disabled) }
    /// Enables background interaction behind the panel.
    public static var enabled: Self { .init(type: .enabled(upThrough: nil)) }

    /// Enables background interaction only up to the specified detent.
    public static func enabled(upThrough detent: PanelDetent) -> Self {
        .init(type: .enabled(upThrough: detent))
    }

    @MainActor
    internal func isInteractable(currentHeight: CGFloat, in container: UIView) -> Bool {
        switch self.type {
        case .disabled:
            return false
        case .enabled(let upThrough?):
            return currentHeight <= upThrough.calculate(in: container) + 1.0
        case .enabled(nil):
            return true
        }
    }
}

struct PanelBackgroundInteractionKey: PreferenceKey {
    static let defaultValue: PanelBackgroundInteraction = .disabled
    
    static func reduce(value: inout PanelBackgroundInteraction, nextValue: () -> PanelBackgroundInteraction) {
        value = nextValue()
    }
}

extension View {
    /// Sets how background interaction behaves behind the panel.
    public func panelBackgroundInteraction(_ interaction: PanelBackgroundInteraction) -> some View {
        self.preference(key: PanelBackgroundInteractionKey.self, value: interaction)
    }
}
