//
//  DragIndicatorView.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/05/17.
//  
//

import UIKit

/// Provides the visible drag indicator and an expanded touch area.
internal final class DragIndicatorView: UIView {
    init() {
        super.init(frame: .zero)
        backgroundColor = .tertiaryLabel
        layer.cornerRadius = 2.5
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = true
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 34),
            heightAnchor.constraint(equalToConstant: 5)
        ])
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = NSLocalizedString(
            "panel.dragIndicator.label",
            comment: "Accessibility label for panel drag indicator"
        )
        accessibilityHint = NSLocalizedString(
            "panel.dragIndicator.hint",
            comment: "Accessibility hint for panel drag indicator"
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Allows dragging and tapping beyond the visible indicator bounds.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let touchArea = bounds.inset(by: PanelConstants.dragIndicatorHitArea)
        return touchArea.contains(point)
    }
}
