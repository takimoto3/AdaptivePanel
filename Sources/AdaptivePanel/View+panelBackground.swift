//
//  View+panelBackground.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/04/08.
//  
//


import SwiftUI

struct BackgroundStyle: Equatable {
    let style: AnyShapeStyle
    let id: UUID
    
    init(_ style: any ShapeStyle, id: UUID = UUID()) {
        self.style = AnyShapeStyle(style)
        self.id = id
    }

    static func == (lhs: BackgroundStyle, rhs: BackgroundStyle) -> Bool {
        lhs.id == rhs.id
    }
}

struct PanelBackgroundStyleKey: PreferenceKey {
    static let defaultValue: BackgroundStyle = BackgroundStyle(Color(uiColor: .systemBackground))

    static func reduce(value: inout BackgroundStyle, nextValue: () -> BackgroundStyle) {
        value = nextValue()
    }
}

extension View {
    /// Sets the background style for the panel.
    public func panelBackground<S: ShapeStyle>(_ style: S) -> some View {
        self.preference(key: PanelBackgroundStyleKey.self, value: BackgroundStyle(style))
    }
}
