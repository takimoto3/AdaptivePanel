//
//  View+panelDragIndicator.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/04/08.
//  
//

import SwiftUI

struct PanelDragIndicatorVisibleKey: PreferenceKey {
    static let defaultValue: Visibility = .automatic
    static func reduce(value: inout Visibility, nextValue: () -> Visibility) {
        let v = nextValue()
        value = v
    }
}

extension View {
    /// Sets the drag indicator visibility for the panel.
    public func panelDragIndicator(_ value: Visibility) -> some View {
        self.preference(key: PanelDragIndicatorVisibleKey.self, value: value)
    }
}
