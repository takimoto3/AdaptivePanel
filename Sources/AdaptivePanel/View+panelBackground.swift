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

struct BackgroundConfiguration: Equatable {
    let alignment: Alignment
    let content: () -> AnyView
    let id: UUID
    
    init(alignment: Alignment, content: @escaping () -> AnyView, id: UUID = UUID()) {
        self.alignment = alignment
        self.content = content
        self.id = id
    }
    
    static func == (lhs: BackgroundConfiguration, rhs: BackgroundConfiguration) -> Bool {
        lhs.id == rhs.id
    }
}

extension BackgroundConfiguration: @unchecked Sendable {}

struct PanelBackgroundStyleKey: PreferenceKey {
    static let defaultValue: BackgroundStyle = BackgroundStyle(Color(uiColor: .systemBackground))

    static func reduce(value: inout BackgroundStyle, nextValue: () -> BackgroundStyle) {
        value = nextValue()
    }
}

struct PanelBackgroundConfigurationKey: PreferenceKey {
    static let defaultValue: BackgroundConfiguration? = nil
    
    static func reduce(value: inout BackgroundConfiguration?, nextValue: () -> BackgroundConfiguration?) {
        value = nextValue()
    }
}

extension View {
    /// Sets the background style for the panel.
    public func panelBackground<S: ShapeStyle>(_ style: S) -> some View {
        self.preference(key: PanelBackgroundStyleKey.self, value: BackgroundStyle(style))
    }
    
    public func panelBackground<Content: View>(alignment: Alignment = .center, @ViewBuilder content: @escaping () -> Content) -> some View {
        self.preference(
            key: PanelBackgroundConfigurationKey.self,
            value: BackgroundConfiguration(alignment: alignment, content: {AnyView(content())})
        )
    }
}
