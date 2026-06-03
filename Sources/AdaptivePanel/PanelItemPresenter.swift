//
//  PanelItemPresenter.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/05/24.
//  
//

import SwiftUI
import UIKit

/// Bridges SwiftUI item-based presentation state to a UIKit custom presentation.
@MainActor
struct PanelItemPresenter<Item: Identifiable, Content: View>: UIViewControllerRepresentable {
    @Binding var item: Item?
    let onDismiss: (() -> Void)?
    let content: (Item) -> Content

    func makeCoordinator() -> PanelCoordinator<Content> {
        PanelCoordinator()
    }

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        context.coordinator.onDismiss = {
            if item != nil {
                item = nil
                onDismiss?()
            }
        }
        
        if let currentItem = item {
            if let hosting = uiViewController.presentedViewController as? PanelHostingController<Content> {
                hosting.update(content: { content(currentItem) })
            } else {
                guard uiViewController.presentedViewController == nil else { return }
                context.coordinator.present(from: uiViewController, content: { content(currentItem) })
            }
        } else {
            guard let presented = uiViewController.presentedViewController,
                  !presented.isBeingDismissed else { return }
            if presented is PanelHostingController<Content> {
                presented.dismiss(animated: true)
            }
        }
    }
}
