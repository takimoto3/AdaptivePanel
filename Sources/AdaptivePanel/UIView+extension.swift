//
//  UIView+extension.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/04/08.
//  
//

import UIKit

// MARK: - UIView Extension

internal extension UIView {
    func findScrollView(point: CGPoint) -> UIScrollView? {
        let touchedView = self.hitTest(point, with: nil)
        return sequence(first: touchedView, next: { $0?.superview })
            .compactMap { $0 as? UIScrollView }
            .first(where: { $0.isVerticalScrollable })
    }
}

internal extension UIScrollView {
    /// Whether this scroll view is vertically scrollable.
    var isVerticalScrollable: Bool {
        let vertical = contentSize.height > bounds.height || alwaysBounceVertical
        let horizontalOnly = contentSize.width > bounds.width && !alwaysBounceVertical
        return vertical && !horizontalOnly
    }
}

