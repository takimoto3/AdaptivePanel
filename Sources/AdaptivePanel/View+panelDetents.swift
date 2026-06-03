//
//  View+panelDetents.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/04/08.
//  
//

import SwiftUI
import UIKit

/// A protocol for defining a custom height for a panel detent.
public protocol CustomPanelDetent {
    /// Returns the height for the detent given the presentation context.
    /// - Parameter context: The context in which the detent is calculated.
    /// - Returns: The height in points, or nil to fallback to the maximum possible height.
    static func height(in context: PanelDetent.Context) -> CGFloat?
}

public struct PanelDetent: Equatable, Hashable, Sendable {
    /// Contextual information used during custom detent calculation.
    public struct Context {
        /// The maximum allowed height for the panel (equivalent to .large).
        public let maxDetentValue: CGFloat
    }
    
    private let resolver: @MainActor (UIView) -> CGFloat
    public let id: String

    private init(id: String, resolver: @escaping @MainActor (UIView) -> CGFloat) {
        self.id = id
        self.resolver = resolver
    }

    /// Displays the panel at about half the screen height.
    public static let medium = PanelDetent(id: "medium", resolver: fraction(0.5).resolver)

    /// Displays the panel at the maximum screen height.
    public static let large = PanelDetent(id: "large") {
        return $0.bounds.height - $0.safeAreaInsets.top
    }

    /// Specifies the panel height as a fraction of the full screen height.
    /// - Parameter value: A ratio from 0.0 to 1.0, based on the screen height including safe areas.
    /// - Note: `fraction(1.0)` is equivalent to `large` because values exceeding `large` are clamped.
    public static func fraction(_ value: CGFloat) -> PanelDetent {
        let f = max(0, min(value, 1))
        return PanelDetent(id: "fraction(\(f))") { container in
            return (container.bounds.height * f)
        }
    }

    /// Specifies the panel height as a fixed value.
    public static func height(_ value: CGFloat) -> PanelDetent {
        return PanelDetent(id: "height(\(value))") { container in
            return value + container.safeAreaInsets.bottom
        }
    }
    
    /// Specifies a custom detent using a type that conforms to `CustomPanelDetent`.
    /// - Parameter type: The custom detent type.
    public static func custom<D: CustomPanelDetent>(_ type: D.Type) -> PanelDetent {
        PanelDetent(id: "\(type)") { container in
            let maxDetentValue = PanelDetent.large.calculate(in: container)
            let context = Context(maxDetentValue: maxDetentValue)
            return D.height(in: context) ?? maxDetentValue
        }
    }

    @MainActor
    func calculate(in container: UIView) -> CGFloat {
        resolver(container)
    }

    public static func == (lhs: PanelDetent, rhs: PanelDetent) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public var debugDescription: String {
        return "PanelDetent(id: \(id))"
    }
}

struct PanelDetentSelection: Equatable {
    let binding: Binding<PanelDetent>
    let detent: PanelDetent

    init(_ binding: Binding<PanelDetent>) {
        self.binding = binding
        self.detent = binding.wrappedValue
    }

    static func == (lhs: PanelDetentSelection, rhs: PanelDetentSelection) -> Bool {
        lhs.detent == rhs.detent
    }
}

struct PanelDetentKey: PreferenceKey {
    static let defaultValue: [PanelDetent] = [.large]
    static func reduce(value: inout [PanelDetent], nextValue: () -> [PanelDetent]) {
        value = nextValue()
    }
}

struct PanelDetentSelectionKey: PreferenceKey {
    static let defaultValue: PanelDetentSelection? = nil
    static func reduce(value: inout PanelDetentSelection?, nextValue: () -> PanelDetentSelection?) {
        value = nextValue() ?? value
    }
}

extension View {
    @ViewBuilder
    /// Sets the available detents for the panel.
    public func panelDetents(_ detents: Set<PanelDetent>) -> some View {
        if detents.isEmpty {
            self
        } else {
            self.preference(key: PanelDetentKey.self, value: Array(detents))
        }
    }

    @ViewBuilder
    public func panelDetents(_ detents: Set<PanelDetent>, selection: Binding<PanelDetent>) -> some View {
        if detents.isEmpty {
            self
        } else {
            self
                .panelDetents(detents)
                .preference(key: PanelDetentSelectionKey.self, value: PanelDetentSelection(selection))
        }
    }
}
