//
//  Helpers.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/05/17.
//  
//

import UIKit
import SwiftUI
import UIKit.UIGestureRecognizerSubclass

@testable import AdaptivePanel

// MARK: - Mock

final class MockContainerView: UIView {
    private let mockSafeAreaInsets: UIEdgeInsets

    init(frame: CGRect, safeAreaInsets: UIEdgeInsets = .zero) {
        self.mockSafeAreaInsets = safeAreaInsets
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) { fatalError() }

    override var safeAreaInsets: UIEdgeInsets {
        mockSafeAreaInsets
    }
}

@MainActor
final class MockPanelPreferenceReceiver: PanelPreferenceReceiver {
    
    var panelDetents: [PanelDetent] = []
    var landscapeConfiguration: PanelLandscapeConfiguration = .default
    var interactionMode: PanelInteraction = .resizing
    var dragIndicatorVisibility: Visibility = .automatic
    var isInteractiveDismissDisabled: Bool = false
    var panelCornerRadius: CGFloat? = nil
    var backgroundInteraction: PanelBackgroundInteraction = PanelBackgroundInteractionKey.defaultValue
    var updatedBackgroundStyle: AnyShapeStyle? = nil
    var selectedDetent: PanelDetent? = nil
    var onDetentChange: ((PanelDetent) -> Void)? = nil

    func updateBackgroundStyle(_ style: AnyShapeStyle) {
        updatedBackgroundStyle = style
    }
    
    func updateBackground<Content>(alignment: Alignment, content: () -> Content) where Content : View {
        
    }
}

@MainActor
final class TestablePanelHostingController<Content: View>: PanelHostingController<Content> {
    let mockReceiver: MockPanelPreferenceReceiver

    init(mockReceiver: MockPanelPreferenceReceiver, @ViewBuilder content: @escaping () -> Content) {
        self.mockReceiver = mockReceiver
        super.init(content: content)
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func applyPresenter(_ apply: (PanelPreferenceReceiver) -> Void) {
        apply(mockReceiver)
    }
}

@MainActor
class TestablePanelPresentationController: PanelPresentationController {
    private let _containerView: UIView
    private let _presentingViewController: UIViewController
    
    override var containerView: UIView? { _containerView }
    override var presentingViewController: UIViewController { _presentingViewController }
    
    init(containerView: UIView, presentedViewController: UIViewController, presenting: UIViewController?) {
        self._containerView = containerView
        self._presentingViewController = presenting ?? UIViewController()
        super.init(presentedViewController: presentedViewController, presenting: presenting)
    }
    
    func addPanelViewToContainer() {
        containerView?.addSubview(panelView)
    }
    
    func simulateDimmingTap() {
        perform(NSSelectorFromString("handleDimmingTap"))
    }
}

@MainActor
final class MockPanGestureRecognizer: UIPanGestureRecognizer {
    var mockVelocity: CGPoint = .zero
    var mockLocation: CGPoint = .zero
    var mockTranslation: CGPoint = .zero
    var mockState: UIGestureRecognizer.State = .possible
    
    override var state: UIGestureRecognizer.State {
        get { mockState }
        set { mockState = newValue }
    }
  
    override func velocity(in view: UIView?) -> CGPoint { mockVelocity }
    override func location(in view: UIView?) -> CGPoint { mockLocation }
    override func translation(in view: UIView?) -> CGPoint { mockTranslation }
}

@MainActor
class MockViewController: UIViewController {
    var dismissCalled = false
    
    var mockIsBeingDismissed = false
    override var isBeingDismissed: Bool { mockIsBeingDismissed }
    
    override func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        dismissCalled = true
    }
}

@MainActor
final class MockTransitionCoordinator: NSObject, UIViewControllerTransitionCoordinator {
    func animate(alongsideTransition animation: ((any UIViewControllerTransitionCoordinatorContext) -> Void)?, completion: ((any UIViewControllerTransitionCoordinatorContext) -> Void)? = nil) -> Bool {
        animateAlongsideCalled = true
        return true
    }
    
    func animateAlongsideTransition(in view: UIView?, animation: ((any UIViewControllerTransitionCoordinatorContext) -> Void)?, completion: ((any UIViewControllerTransitionCoordinatorContext) -> Void)? = nil) -> Bool {
        animateAlongsideCalled = true
        return true
    }
    
    var animateAlongsideCalled = false

    // Mandatory implementation but not used in this test.
    var isAnimated: Bool { false }
    var presentationStyle: UIModalPresentationStyle { .none }
    var initiallyInteractive: Bool { false }
    var isInterruptible: Bool { false }
    var isInteractive: Bool { false }
    var isCancelled: Bool { false }
    var transitionDuration: TimeInterval { 0 }
    var percentComplete: CGFloat { 0 }
    var completionVelocity: CGFloat { 0 }
    var completionCurve: UIView.AnimationCurve { .linear }
    var targetTransform: CGAffineTransform { .identity }
    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? { nil }
    func view(forKey key: UITransitionContextViewKey) -> UIView? { nil }
    func notifyWhenInteractionChanges(_ handler: @escaping (UIViewControllerTransitionCoordinatorContext) -> Void) {}
    func notifyWhenInteractionEnds(_ handler: @escaping (UIViewControllerTransitionCoordinatorContext) -> Void) {}
    var containerView: UIView { UIView() }
}
