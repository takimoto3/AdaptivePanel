//
//  DimmingView.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/05/17.
//  
//

import UIKit

/// Handles background dimming and optional passthrough touches to the presenting view.
final class DimmingView: UIView {
    var isPassthrough = false
    var activePanelFrame: CGRect = .zero
    weak var presentingView: UIView?

    /// Forwards touches outside the panel to the presenting view when background interaction is enabled.
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)

        if isPassthrough, hitView == self, !activePanelFrame.contains(point) {
            if let presentingView {
                let convertedPoint = self.convert(point, to: presentingView)
                return presentingView.hitTest(convertedPoint, with: event)
            }
            return nil
        }

        return hitView
    }
}
