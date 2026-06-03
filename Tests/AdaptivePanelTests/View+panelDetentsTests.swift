//
//  View+panelDetents.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/05/17.
//  
//

import Testing
import UIKit
@testable import AdaptivePanel


// MARK: - Tests

@Suite("PanelDetent")
@MainActor
struct PanelDetentTests {

    // MARK: - fraction

    @Test func fraction_normal() {
        let container = MockContainerView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        #expect(PanelDetent.fraction(0.5).calculate(in: container) == 422)
    }

    @Test func fraction_clampedToOne() {
        let container = MockContainerView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        #expect(PanelDetent.fraction(1.5).calculate(in: container) == 844)
    }

    @Test func fraction_clampedToZero() {
        let container = MockContainerView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        #expect(PanelDetent.fraction(-0.5).calculate(in: container) == 0)
    }

    // MARK: - height

    @Test func height_noSafeArea() {
        let container = MockContainerView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        #expect(PanelDetent.height(300).calculate(in: container) == 300)
    }

    @Test func height_withBottomSafeArea() {
        let container = MockContainerView(
            frame: CGRect(x: 0, y: 0, width: 390, height: 844),
            safeAreaInsets: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)
        )
        #expect(PanelDetent.height(300).calculate(in: container) == 334)
    }

    // MARK: - medium

    @Test func medium_isHalfHeight() {
        let container = MockContainerView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        #expect(PanelDetent.medium.calculate(in: container) == 422)
    }

    // MARK: - large

    @Test func large_withTopSafeArea() {
        let container = MockContainerView(
            frame: CGRect(x: 0, y: 0, width: 390, height: 844),
            safeAreaInsets: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)
        )
        #expect(PanelDetent.large.calculate(in: container) == 785) // 844 - 59
    }

    @Test func large_noSafeArea() {
        let container = MockContainerView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        #expect(PanelDetent.large.calculate(in: container) == 844) // 844 - 0
    }
    
    // MARK: - Equatable

    @Test func equality_sameId() {
        #expect(PanelDetent.medium == PanelDetent.medium)
    }

    @Test func equality_differentId() {
        #expect(PanelDetent.medium != PanelDetent.large)
    }

    @Test func equality_sameFraction() {
        #expect(PanelDetent.fraction(0.5) == PanelDetent.fraction(0.5))
    }

    @Test func equality_differentFraction() {
        #expect(PanelDetent.fraction(0.5) != PanelDetent.fraction(0.7))
    }

    // MARK: - id

    @Test func id_fraction() {
        #expect(PanelDetent.fraction(0.5).id == "fraction(0.5)")
    }

    @Test func id_height() {
        #expect(PanelDetent.height(300).id == "height(300.0)")
    }
    
    // MARK: - custom

    @Test func custom_returnsCalculatedHeight() {
        let container = MockContainerView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        
        struct TestDetent: CustomPanelDetent {
            static func height(in context: PanelDetent.Context) -> CGFloat? {
                context.maxDetentValue * 0.3
            }
        }
        
        let detent = PanelDetent.custom(TestDetent.self)
        let largeHeight = PanelDetent.large.calculate(in: container)
        #expect(detent.calculate(in: container) == largeHeight * 0.3)
    }

    @Test func custom_returnsNil_fallsBackToMaxDetentValue() {
        let container = MockContainerView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        
        struct NilDetent: CustomPanelDetent {
            static func height(in context: PanelDetent.Context) -> CGFloat? {
                nil
            }
        }
        
        let detent = PanelDetent.custom(NilDetent.self)
        let largeHeight = PanelDetent.large.calculate(in: container)
        #expect(detent.calculate(in: container) == largeHeight)
    }

    @Test func custom_sameType_sameId() {
        struct TestDetent: CustomPanelDetent {
            static func height(in context: PanelDetent.Context) -> CGFloat? { 300 }
        }
        
        #expect(PanelDetent.custom(TestDetent.self) == PanelDetent.custom(TestDetent.self))
    }

    @Test func custom_differentType_differentId() {
        struct DetentA: CustomPanelDetent {
            static func height(in context: PanelDetent.Context) -> CGFloat? { 300 }
        }
        struct DetentB: CustomPanelDetent {
            static func height(in context: PanelDetent.Context) -> CGFloat? { 300 }
        }
        
        #expect(PanelDetent.custom(DetentA.self) != PanelDetent.custom(DetentB.self))
    }
}
