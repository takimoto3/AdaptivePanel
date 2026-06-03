//
//  DimmingViewTests.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/05/17.
//  
//

import Testing
import UIKit
@testable import AdaptivePanel

@Suite("DimmingView")
@MainActor
struct DimmingViewTests {

    private func makeDimmingView(
        frame: CGRect = CGRect(x: 0, y: 0, width: 390, height: 844),
        panelFrame: CGRect = CGRect(x: 0, y: 400, width: 390, height: 444)
    ) -> DimmingView {
        let view = DimmingView(frame: frame)
        view.activePanelFrame = panelFrame
        return view
    }

    // MARK: - Cases where super.hitTest returns nil

    @Test func hitTest_outsideFrame_returnsNil() {
        let dimmingView = makeDimmingView()
        dimmingView.isPassthrough = false

        let result = dimmingView.hitTest(CGPoint(x: 500, y: 900), with: nil)
        #expect(result == nil)
    }

    @Test func hitTest_passthrough_outsideFrame_returnsNil() {
        let dimmingView = makeDimmingView()
        dimmingView.isPassthrough = true

        let result = dimmingView.hitTest(CGPoint(x: 500, y: 900), with: nil)
        #expect(result == nil)
    }

    // MARK: - isPassthrough = false

    @Test func hitTest_notPassthrough_returnsHitView() {
        let dimmingView = makeDimmingView()
        dimmingView.isPassthrough = false

        let result = dimmingView.hitTest(CGPoint(x: 100, y: 100), with: nil)
        #expect(result == dimmingView)
    }

    // MARK: - isPassthrough = true, inside panel

    @Test func hitTest_passthrough_insidePanel_returnsDimmingView() {
        let dimmingView = makeDimmingView()
        dimmingView.isPassthrough = true

        // Touch inside activePanelFrame
        let result = dimmingView.hitTest(CGPoint(x: 100, y: 500), with: nil)
        #expect(result == dimmingView)
    }

    // MARK: - isPassthrough = true, outside panel, no presentingView

    @Test func hitTest_passthrough_outsidePanel_noPresentingView_returnsNil() {
        let dimmingView = makeDimmingView()
        dimmingView.isPassthrough = true
        dimmingView.presentingView = nil

        // Touch outside activePanelFrame
        let result = dimmingView.hitTest(CGPoint(x: 100, y: 100), with: nil)
        #expect(result == nil)
    }

    // MARK: - isPassthrough = true, outside panel, with presentingView

    @Test func hitTest_passthrough_outsidePanel_forwardsToPresentingView() {
        let dimmingView = makeDimmingView()
        dimmingView.isPassthrough = true

        let presentingView = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let targetView = UIView(frame: CGRect(x: 50, y: 50, width: 100, height: 100))
        presentingView.addSubview(targetView)
        dimmingView.presentingView = presentingView

        // Touch outside activePanelFrame and inside targetView
        let result = dimmingView.hitTest(CGPoint(x: 100, y: 100), with: nil)
        #expect(result == targetView)
    }
    
    @Test func hitTest_passthrough_outsidePanel_missesTargetView_returnsNil() {
        let dimmingView = makeDimmingView()
        dimmingView.isPassthrough = true

        let presentingView = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        presentingView.isUserInteractionEnabled = false
        let targetView = UIView(frame: CGRect(x: 50, y: 50, width: 100, height: 100))
        presentingView.addSubview(targetView)
        dimmingView.presentingView = presentingView

        let result = dimmingView.hitTest(CGPoint(x: 10, y: 10), with: nil)
        #expect(result == nil)
    }

    // MARK: - Coordinate Conversion

    @Test func hitTest_passthrough_correctCoordinateConversion() {
        // Place dimmingView at an offset
        let dimmingView = makeDimmingView(
            frame: CGRect(x: 50, y: 50, width: 390, height: 844),
            panelFrame: CGRect(x: 0, y: 400, width: 390, height: 444)
        )
        dimmingView.isPassthrough = true

        let presentingView = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let targetView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        presentingView.addSubview(targetView)
        dimmingView.presentingView = presentingView

        // Touch in dimmingView coordinate system -> should reach targetView converted to presentingView coordinate system
        let result = dimmingView.hitTest(CGPoint(x: 10, y: 10), with: nil)
        #expect(result == targetView)
    }
}
