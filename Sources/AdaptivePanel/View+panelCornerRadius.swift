//
//  View+panelCornerRadius.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/04/08.
//  
//

import SwiftUI

struct PanelCornerRadiusKey: PreferenceKey {
    static let defaultValue: CGFloat? = nil
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = nextValue() ?? value
    }
}

extension View {
    /// Sets the corner radius for the panel.
    public func panelCornerRadius(_ radius: CGFloat?) -> some View {
        self.preference(key: PanelCornerRadiusKey.self, value: radius)
    }
}
