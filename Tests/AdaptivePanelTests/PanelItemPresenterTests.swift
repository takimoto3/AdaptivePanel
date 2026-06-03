//
//  PanelItemPresenterTests.swift
//  AdaptivePanel
//
//  Created by Masato Takimoto on 2026/05/24.
//

import Testing
import UIKit
import SwiftUI
@testable import AdaptivePanel

@Suite("PanelItemPresenter.Coordinator")
@MainActor
struct PanelItemPresenterCoordinatorTests {

    // MARK: - PanelItemPresenter onDismiss

    @Test func onDismiss_itemNotNil_setsItemToNil() {
        var item: Int? = 1
        let coordinator = PanelCoordinator<AnyView>()
        coordinator.onDismiss = {
            guard item != nil else { return }
            item = nil
        }

        coordinator.onDismiss?()
        #expect(item == nil)
    }

    @Test func onDismiss_itemNil_doesNothing() {
        var item: Int? = nil
        var onDismissCalled = false
        let coordinator = PanelCoordinator<AnyView>()
        coordinator.onDismiss = {
            guard item != nil else { return }
            item = nil
            onDismissCalled = true
        }

        coordinator.onDismiss?()
        #expect(onDismissCalled == false)
    }
}
