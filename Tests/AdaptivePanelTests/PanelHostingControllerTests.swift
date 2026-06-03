//
//  PanelHostingControllerTests.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/05/18.
//  
//

import Testing
import SwiftUI
import UIKit
@testable import AdaptivePanel

@Suite("PanelHostingController")
@MainActor
struct PanelHostingControllerTests {

    private func makeWindow(with vc: UIViewController) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = vc
        window.makeKeyAndVisible()
        return window
    }

    private func waitForRendering() {
        RunLoop.main.run(until: Date())
    }

    // MARK: - Initialization

    @Test func backgroundColor_isClear() {
        let vc = PanelHostingController { Text("test") }
        #expect(vc.view.backgroundColor == .clear)
    }

    @Test func insetsLayoutMarginsFromSafeArea_isFalse() {
        let vc = PanelHostingController { Text("test") }
        #expect(vc.view.insetsLayoutMarginsFromSafeArea == false)
    }

    @Test func sizingOptions_isEmpty() {
        let vc = PanelHostingController { Text("test") }
        #expect(vc.sizingOptions == [])
    }

    // MARK: - update

    @Test func update_preservesOwnerBox() {
        let vc = PanelHostingController { Text("test") }
        let ownerBox = vc.rootView.ownerBox
        vc.update { Text("updated") }
        #expect(vc.rootView.ownerBox === ownerBox)
    }

    // MARK: - onPreferenceChange

    @Test func preferenceChange_panelDetents() {
        let mock = MockPanelPreferenceReceiver()
        let vc = TestablePanelHostingController(mockReceiver: mock) {
            Text("test").panelDetents([.medium, .large])
        }
        let _ = makeWindow(with: vc)
        waitForRendering()
        #expect(mock.panelDetents.count == 2)
    }

    @Test func preferenceChange_interactionMode() {
        let mock = MockPanelPreferenceReceiver()
        let vc = TestablePanelHostingController(mockReceiver: mock) {
            Text("test").panelContentInteraction(.scrolls)
        }
        let _ = makeWindow(with: vc)
        waitForRendering()
        #expect(mock.interactionMode == .scrolls)
    }

    @Test func preferenceChange_isInteractiveDismissDisabled() {
        let mock = MockPanelPreferenceReceiver()
        let vc = TestablePanelHostingController(mockReceiver: mock) {
            Text("test").panelInteractiveDismissDisabled(true)
        }
        let _ = makeWindow(with: vc)
        waitForRendering()
        #expect(mock.isInteractiveDismissDisabled == true)
    }

    @Test func preferenceChange_backgroundInteraction() {
        let mock = MockPanelPreferenceReceiver()
        let vc = TestablePanelHostingController(mockReceiver: mock) {
            Text("test").panelBackgroundInteraction(.enabled)
        }
        let _ = makeWindow(with: vc)
        waitForRendering()
        #expect(mock.backgroundInteraction == .enabled)
    }

    @Test func preferenceChange_dragIndicatorVisibility() {
        let mock = MockPanelPreferenceReceiver()
        let vc = TestablePanelHostingController(mockReceiver: mock) {
            Text("test").panelDragIndicator(.visible)
        }
        let _ = makeWindow(with: vc)
        waitForRendering()
        #expect(mock.dragIndicatorVisibility == .visible)
    }

    @Test func preferenceChange_cornerRadius() {
        let mock = MockPanelPreferenceReceiver()
        let vc = TestablePanelHostingController(mockReceiver: mock) {
            Text("test").panelCornerRadius(16)
        }
        let _ = makeWindow(with: vc)
        waitForRendering()
        #expect(mock.panelCornerRadius == CGFloat(16))
    }

    @Test func preferenceChange_backgroundStyle() {
        let mock = MockPanelPreferenceReceiver()
        let vc = TestablePanelHostingController(mockReceiver: mock) {
            Text("test").panelBackground(Color.red)
        }
        let _ = makeWindow(with: vc)
        waitForRendering()
        #expect(mock.updatedBackgroundStyle != nil)
    }

    @Test func preferenceChange_landscapeConfiguration() {
        let mock = MockPanelPreferenceReceiver()
        let vc = TestablePanelHostingController(mockReceiver: mock) {
            Text("test").panelLandscapeLayout(.leading(), width: .compact)
        }
        let _ = makeWindow(with: vc)
        waitForRendering()
        #expect(mock.landscapeConfiguration.width == .compact)
        #expect(mock.landscapeConfiguration.alignment == .leading())
    }
    
    @Test func preferenceChange_detentSelection() {
        var selection: PanelDetent = .large
        let binding = Binding(get: { selection }, set: { selection = $0 })
        let mock = MockPanelPreferenceReceiver()
        let vc = TestablePanelHostingController(mockReceiver: mock) {
            Text("test").panelDetents([.medium, .large], selection: binding)
        }
        let _ = makeWindow(with: vc)
        waitForRendering()
        #expect(mock.selectedDetent == .large)
        #expect(mock.onDetentChange != nil)
    }
}
