//
//  PanelPresenter.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/05/17.
//  
//

import SwiftUI
import UIKit

/// Bridges SwiftUI presentation state to a UIKit custom presentation.
@MainActor
struct PanelPresenter<Content: View>: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onDismiss: (() -> Void)?
    let content: () -> Content

    func makeCoordinator() -> PanelCoordinator<Content> {
        PanelCoordinator()
    }

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    /// Synchronizes panel presentation, content updates, and dismissal with SwiftUI updates.
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        context.coordinator.onDismiss = {
            if isPresented {
                isPresented = false
                onDismiss?()
            }
        }
        
        if isPresented {
            if let hosting = uiViewController.presentedViewController as? PanelHostingController<Content> {
                hosting.update(content: content)
                return
            }
            guard uiViewController.presentedViewController == nil else { return }
            context.coordinator.present(from: uiViewController, content: content)
        } else {
            guard let presented = uiViewController.presentedViewController,
                  !presented.isBeingDismissed else { return }
            if presented is PanelHostingController<Content> {
                presented.dismiss(animated: true)
            }
        }
    }
}
