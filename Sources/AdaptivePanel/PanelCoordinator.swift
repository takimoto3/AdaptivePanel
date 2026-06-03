//
//  PanelCoordinator.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/05/31.
//  
//

import UIKit
import SwiftUI

@MainActor
final class PanelCoordinator<Content: View>: NSObject, UIViewControllerTransitioningDelegate {
    var onDismiss: (() -> Void)?

    func present(from uiViewController: UIViewController, content: @escaping () -> Content) {
        Task { @MainActor [weak uiViewController, weak self] in
            guard let self,
                  let viewController = uiViewController,
                  viewController.view.window != nil,
                  viewController.presentedViewController == nil else { return }

            let hosting = PanelHostingController(content: content)
            hosting.modalPresentationStyle = .custom
            hosting.transitioningDelegate = self

            viewController.present(hosting, animated: true)
        }
    }

    /// Creates the UIKit presentation controller and writes completed dismissals back to SwiftUI state.
    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        let presentationController = PanelPresentationController(
            presentedViewController: presented,
            presenting: presenting
        )
        presentationController.onDismiss = { [weak self] in
            guard let self else { return }
            self.onDismiss?()
        }
        return presentationController
    }
}
