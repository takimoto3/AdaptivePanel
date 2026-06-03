//
//  DragIndicatorViewTests.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/05/17.
//  
//

import Testing
import UIKit
@testable import AdaptivePanel

@Suite("DragIndicatorView")
@MainActor
struct DragIndicatorViewTests {

    private func makeIndicatorView() -> DragIndicatorView {
        let view = DragIndicatorView()
        // Set frame directly instead of using constraints to make it testable
        view.frame = CGRect(x: 0, y: 0, width: 34, height: 5)
        return view
    }

    // MARK: - point(inside:with:)

    @Test func pointInside_withinVisibleBounds() {
        let view = makeIndicatorView()
        #expect(view.point(inside: CGPoint(x: 17, y: 2), with: nil))
    }

    @Test func pointInside_withinExpandedHitArea() {
        let view = makeIndicatorView()
        // hitArea is top: -20, left: -40, bottom: -20, right: -40
        #expect(view.point(inside: CGPoint(x: -30, y: -10), with: nil))
    }

    @Test func pointInside_outsideExpandedHitArea() {
        let view = makeIndicatorView()
        #expect(!view.point(inside: CGPoint(x: -50, y: 0), with: nil))
    }

    @Test func pointInside_outsideVerticalHitArea() {
        let view = makeIndicatorView()
        #expect(!view.point(inside: CGPoint(x: 17, y: -30), with: nil))
    }

    // MARK: - Accessibility

    @Test func accessibilityElement_isEnabled() {
        let view = makeIndicatorView()
        #expect(view.isAccessibilityElement)
    }

    @Test func accessibilityTraits_isButton() {
        let view = makeIndicatorView()
        #expect(view.accessibilityTraits == .button)
    }
}
