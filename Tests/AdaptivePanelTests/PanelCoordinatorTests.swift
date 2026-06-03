//
//  PanelCoordinatorTests.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/05/31.
//  
//

import Testing
import UIKit
import SwiftUI
@testable import AdaptivePanel

@Suite("PanelCoordinator")
@MainActor
struct PanelCoordinatorTests {

    // MARK: - presentationController

    @Test func presentationController_returnsPanelPresentationController() {
        let coordinator = PanelCoordinator<AnyView>()
        let presented = UIViewController()
        let presenting = UIViewController()

        let pc = coordinator.presentationController(
            forPresented: presented,
            presenting: presenting,
            source: presenting
        )

        #expect(pc is PanelPresentationController)
    }

    @Test func presentationController_onDismiss_callsOnDismiss() {
        let coordinator = PanelCoordinator<AnyView>()
        var onDismissCalled = false
        coordinator.onDismiss = { onDismissCalled = true }

        let presented = UIViewController()
        let presenting = UIViewController()

        let pc = coordinator.presentationController(
            forPresented: presented,
            presenting: presenting,
            source: presenting
        ) as? PanelPresentationController

        pc?.onDismiss?()
        #expect(onDismissCalled == true)
    }

    @Test func presentationController_onDismiss_nilCallback_doesNotCrash() {
        let coordinator = PanelCoordinator<AnyView>()
        coordinator.onDismiss = nil

        let presented = UIViewController()
        let presenting = UIViewController()

        let pc = coordinator.presentationController(
            forPresented: presented,
            presenting: presenting,
            source: presenting
        ) as? PanelPresentationController

        pc?.onDismiss?()
        #expect(pc != nil)
    }

    // MARK: - present

    @Test func present_withWindow_presentsPanelHostingController() async {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let vc = UIViewController()
        window.rootViewController = vc
        window.makeKeyAndVisible()

        let coordinator = PanelCoordinator<AnyView>()
        coordinator.present(from: vc, content: { AnyView(EmptyView()) })

        await Task.yield()

        #expect(vc.presentedViewController is PanelHostingController<AnyView>)
    }

    @Test func present_withoutWindow_doesNotPresent() async {
        let vc = UIViewController()
        let coordinator = PanelCoordinator<AnyView>()

        coordinator.present(from: vc, content: { AnyView(EmptyView()) })

        await Task.yield()

        #expect(vc.presentedViewController == nil)
    }

    @Test func present_alreadyPresenting_doesNotPresentAgain() async {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let vc = UIViewController()
        window.rootViewController = vc
        window.makeKeyAndVisible()

        let alreadyPresentedVC = UIViewController()
        vc.present(alreadyPresentedVC, animated: false)

        await Task.yield()

        let coordinator = PanelCoordinator<AnyView>()
        coordinator.present(from: vc, content: { AnyView(EmptyView()) })

        await Task.yield()

        #expect(vc.presentedViewController === alreadyPresentedVC)
    }

    @Test func present_deallocatedViewController_doesNotCrash() async {
        let coordinator = PanelCoordinator<AnyView>()

        var vc: UIViewController? = UIViewController()
        coordinator.present(from: vc!, content: { AnyView(EmptyView()) })
        vc = nil

        await Task.yield()
        #expect(true) // OK if it doesn't crash
    }
}
