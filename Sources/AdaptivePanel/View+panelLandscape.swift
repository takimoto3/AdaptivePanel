//
//  View+panelLandscape.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/04/26.
//  
//

import SwiftUI
import UIKit

// MARK: - Landscape Models

/// Alignment options for landscape mode.
public enum PanelLandscapeAlignment: Equatable, Hashable, Sendable {
    case leading(spacing: CGFloat = 0)
    case center
    case trailing(spacing: CGFloat = 0)
}

/// Width definitions for landscape mode panels.
public struct PanelLandscapeWidth: Equatable, Hashable, Sendable {
    private let resolver: @MainActor (UIView) -> CGFloat
    public let id: String

    private init(id: String, resolver: @escaping @MainActor (UIView) -> CGFloat) {
        self.id = id
        self.resolver = resolver
    }

    /// Expands to the full screen width, matching the default `sheet` behavior.
    public static let full = PanelLandscapeWidth(id: "full") { $0.bounds.width }

    /// Keeps the same width as portrait mode using the shorter screen side.
    public static let compact = PanelLandscapeWidth(id: "compact") {
        min($0.bounds.width, $0.bounds.height)
    }

    /// Specifies the width as a fraction of the screen width.
    public static func fraction(_ value: CGFloat) -> PanelLandscapeWidth {
        let f = max(0, min(value, 1))
        return PanelLandscapeWidth(id: "fraction(\(f))") { $0.bounds.width * f }
    }

    /// Specifies a fixed width.
    public static func width(_ value: CGFloat) -> PanelLandscapeWidth {
        return PanelLandscapeWidth(id: "width(\(value))") { _ in value }
    }

    @MainActor
    func calculate(in container: UIView) -> CGFloat {
        resolver(container)
    }

    public static func == (lhs: PanelLandscapeWidth, rhs: PanelLandscapeWidth) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Combined configuration for landscape mode.
struct PanelLandscapeConfiguration: Equatable, Sendable {
    var alignment: PanelLandscapeAlignment
    var width: PanelLandscapeWidth
    var ignoreSafeArea: Bool

    static let `default` = PanelLandscapeConfiguration(alignment: .center, width: .full, ignoreSafeArea: false)
}

// MARK: - Preference Key

struct PanelLandscapeKey: PreferenceKey {
    static let defaultValue: PanelLandscapeConfiguration = .default
    static func reduce(value: inout PanelLandscapeConfiguration, nextValue: () -> PanelLandscapeConfiguration) {
        value = nextValue()
    }
}

// MARK: - View Extension

extension View {
    /// Sets the panel alignment and width for landscape orientation.
    /// - Parameters:
    ///   - alignment: The panel alignment.
    ///   - width: The panel width. Defaults to the portrait-equivalent width.
    ///   - ignoreSafeArea: Whether the panel should ignore safe areas in landscape.
    @MainActor
    public func panelLandscapeLayout(_ alignment: PanelLandscapeAlignment, width: PanelLandscapeWidth = .full, ignoreSafeArea: Bool = false) -> some View {
        self.preference(key: PanelLandscapeKey.self, value: .init(alignment: alignment, width: width, ignoreSafeArea: ignoreSafeArea))
    }
}
