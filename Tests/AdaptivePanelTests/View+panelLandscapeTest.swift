//
//  View+panelLandscapeTest.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/05/17.
//  
//

import Testing
import UIKit
@testable import AdaptivePanel

@Suite("PanelLandscapeWidth")
@MainActor
struct PanelLandscapeWidthTests {

    private let container = MockContainerView(
        frame: CGRect(x: 0, y: 0, width: 844, height: 390) // landscape
    )

    // MARK: - full

    @Test func full_returnsFullWidth() {
        #expect(PanelLandscapeWidth.full.calculate(in: container) == 844)
    }

    // MARK: - compact

    @Test func compact_returnsShorterSide() {
        #expect(PanelLandscapeWidth.compact.calculate(in: container) == 390)
    }

    // MARK: - fraction

    @Test func fraction_normal() {
        #expect(PanelLandscapeWidth.fraction(0.5).calculate(in: container) == 422)
    }

    @Test func fraction_clampedToOne() {
        #expect(PanelLandscapeWidth.fraction(1.5).calculate(in: container) == 844)
    }

    @Test func fraction_clampedToZero() {
        #expect(PanelLandscapeWidth.fraction(-0.5).calculate(in: container) == 0)
    }

    // MARK: - width

    @Test func width_fixedValue() {
        #expect(PanelLandscapeWidth.width(300).calculate(in: container) == 300)
    }

    // MARK: - Equatable

    @Test func equality_sameId() {
        #expect(PanelLandscapeWidth.full == PanelLandscapeWidth.full)
    }

    @Test func equality_differentId() {
        #expect(PanelLandscapeWidth.full != PanelLandscapeWidth.compact)
    }

    @Test func equality_sameFraction() {
        #expect(PanelLandscapeWidth.fraction(0.5) == PanelLandscapeWidth.fraction(0.5))
    }

    @Test func equality_differentFraction() {
        #expect(PanelLandscapeWidth.fraction(0.5) != PanelLandscapeWidth.fraction(0.7))
    }

    // MARK: - id

    @Test func id_full() {
        #expect(PanelLandscapeWidth.full.id == "full")
    }

    @Test func id_compact() {
        #expect(PanelLandscapeWidth.compact.id == "compact")
    }

    @Test func id_fraction() {
        #expect(PanelLandscapeWidth.fraction(0.5).id == "fraction(0.5)")
    }

    @Test func id_width() {
        #expect(PanelLandscapeWidth.width(300).id == "width(300.0)")
    }
}
