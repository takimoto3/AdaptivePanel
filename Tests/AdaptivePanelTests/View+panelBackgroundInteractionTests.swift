//
//  View+panelBackgroundInteractionTests.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/05/17.
//  
//

import Testing
import UIKit
@testable import AdaptivePanel

@Suite("PanelBackgroundInteraction")
@MainActor
struct PanelBackgroundInteractionTests {
    private let container = MockContainerView(
        frame: CGRect(x: 0, y: 0, width: 390, height: 844)
    )

    // MARK: - disabled

    @Test func disabled_alwaysReturnsFalse() {
        #expect(!PanelBackgroundInteraction.disabled.isInteractable(currentHeight: 0, in: container))
        #expect(!PanelBackgroundInteraction.disabled.isInteractable(currentHeight: 422, in: container))
        #expect(!PanelBackgroundInteraction.disabled.isInteractable(currentHeight: 844, in: container))
    }

    // MARK: - enabled (no upThrough)

    @Test func enabled_alwaysReturnsTrue() {
        #expect(PanelBackgroundInteraction.enabled.isInteractable(currentHeight: 0, in: container))
        #expect(PanelBackgroundInteraction.enabled.isInteractable(currentHeight: 422, in: container))
        #expect(PanelBackgroundInteraction.enabled.isInteractable(currentHeight: 844, in: container))
    }

    // MARK: - enabled(upThrough:)

    @Test func enabled_upThrough_belowLimit() {
        let interaction = PanelBackgroundInteraction.enabled(upThrough: .fraction(0.5))
        // medium = 422, currentHeight = 300 -> true
        #expect(interaction.isInteractable(currentHeight: 300, in: container))
    }

    @Test func enabled_upThrough_atLimit() {
        let interaction = PanelBackgroundInteraction.enabled(upThrough: .fraction(0.5))
        // medium = 422, currentHeight = 422 -> true (with 1.0 margin)
        #expect(interaction.isInteractable(currentHeight: 422, in: container))
    }

    @Test func enabled_upThrough_aboveLimit() {
        let interaction = PanelBackgroundInteraction.enabled(upThrough: .fraction(0.5))
        // medium = 422, currentHeight = 500 -> false
        #expect(!interaction.isInteractable(currentHeight: 500, in: container))
    }
}
