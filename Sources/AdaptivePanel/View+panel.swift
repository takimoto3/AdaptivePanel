//
//  View+panel.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/05/17.
//  
//

import SwiftUI

public extension View {
    /// Presents a custom panel with the specified SwiftUI content.
    /// - Parameters:
    ///   - isPresented: A binding that controls whether the panel is presented.
    ///   - onDismiss The closure to execute when dismissing the sheet.
    ///   - content: The content to display inside the panel.
    func panel<Content>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View where Content : View {
        self.background(PanelPresenter(isPresented: isPresented, onDismiss: onDismiss, content: content))
    }
    
    /// Presents a custom panel using the given item as a data source for the panel's content.
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the panel. When item is non-nil, the system passes the item's content to the modifier's closure. If item changes, the system dismisses the panel and replaces it with a new one.
    ///   - onDismiss: The closure to execute when dismissing the panel.
    ///   - content: A closure returning the content of the panel.
    func panel<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        self.background(PanelItemPresenter(item: item, onDismiss: onDismiss, content: content))
    }
}
