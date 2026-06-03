//
//  View+panelInteractiveDismissDisabled.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/04/08.
//  
//

import SwiftUI

struct PanelInteractiveDismissDisabledKey: PreferenceKey {
    static let defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}

extension View {
    /// Disables or enables interactive dismissal for the panel.
    public func panelInteractiveDismissDisabled(_ isDisabled: Bool = true) -> some View {
        self.preference(key: PanelInteractiveDismissDisabledKey.self, value: isDisabled)
    }
}
