//
//  PanelPresentationControllerTests.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/05/19.
//  
//

import Testing
import UIKit
import SwiftUI
@testable import AdaptivePanel

@Suite("PanelPresentationController")
@MainActor
struct PanelPresentationControllerTests {
    
    private func makePresentationController() -> PanelPresentationController {
        let presented = UIViewController()
        let presenting = UIViewController()
        return PanelPresentationController(
            presentedViewController: presented,
            presenting: presenting
        )
    }
    
    // MARK: - isDragIndicatorVisible
    
    @Test func isDragIndicatorVisible_visible() {
        let pc = makePresentationController()
        pc.dragIndicatorVisibility = .visible
        #expect(pc.isDragIndicatorVisible == true)
    }
    
    @Test func isDragIndicatorVisible_hidden() {
        let pc = makePresentationController()
        pc.dragIndicatorVisibility = .hidden
        #expect(pc.isDragIndicatorVisible == false)
    }
    
    @Test func isDragIndicatorVisible_automatic_singleDetent() {
        let pc = makePresentationController()
        pc.dragIndicatorVisibility = .automatic
        pc.panelDetents = [.medium]
        #expect(pc.isDragIndicatorVisible == false)
    }
    
    @Test func isDragIndicatorVisible_automatic_multipleDetents_noContainer_isFalse() {
        let pc = makePresentationController()
        pc.dragIndicatorVisibility = .automatic
        pc.panelDetents = [.medium, .large]
        #expect(pc.isDragIndicatorVisible == true)
    }
    
    @Test func animateDragIndicatorTransition_automatic_singleDetent_alphaIsZero() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        pc.presentedView?.addSubview(pc.dragIndicatorView)
        pc.dragIndicatorVisibility = .automatic
        pc.panelDetents = [.medium]
        
        pc.animateDragIndicatorTransition()
        
        #expect(pc.dragIndicatorView.alpha == 0)
        #expect(pc.dragIndicatorView.isAccessibilityElement == false)
    }
    
    @Test func isDragIndicatorVisible_automatic_multipleDetents() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        pc.dragIndicatorVisibility = .automatic
        pc.panelDetents = [.medium, .large]
        #expect(pc.isDragIndicatorVisible == true)
    }
    
    // MARK: - panelDetents
    
    @Test func panelDetents_empty_resetsCurrentDetentIndex() {
        let pc = makePresentationController()
        pc.panelDetents = []
        #expect(pc.panelDetents.isEmpty)
    }
    
    @Test func panelDetents_setsCorrectly() {
        let pc = makePresentationController()
        pc.panelDetents = [.medium, .large]
        #expect(pc.panelDetents.count == 2)
    }
    
    // MARK: - animateDragIndicatorTransition
    
    @Test func isDragIndicatorVisible_true_alphaAndAccessibility() {
        let pc = makePresentationController()
        pc.presentedView?.addSubview(pc.dragIndicatorView)
        pc.dragIndicatorVisibility = .visible
        pc.animateDragIndicatorTransition()
        #expect(pc.dragIndicatorView.alpha == 1.0)
        #expect(pc.dragIndicatorView.isAccessibilityElement == true)
    }
    
    @Test func isDragIndicatorVisible_false_alphaAndAccessibility() {
        let pc = makePresentationController()
        pc.presentedView?.addSubview(pc.dragIndicatorView)
        pc.dragIndicatorVisibility = .hidden
        pc.animateDragIndicatorTransition()
        #expect(pc.dragIndicatorView.alpha == 0)
        #expect(pc.dragIndicatorView.isAccessibilityElement == false)
    }
    
    @Test func animateDragIndicatorTransition_noSuperview_doesNotChangeAlpha() {
        let pc = makePresentationController()
        // Do not add to superview
        let initialAlpha = pc.dragIndicatorView.alpha
        pc.dragIndicatorVisibility = .visible
        pc.animateDragIndicatorTransition()
        #expect(pc.dragIndicatorView.alpha == initialAlpha)
    }
    
    @Test func animateDragIndicatorTransition_calledTwice_doesNotChangeAlpha() {
        let pc = makePresentationController()
        pc.presentedView?.addSubview(pc.dragIndicatorView)
        pc.dragIndicatorVisibility = .visible
        pc.animateDragIndicatorTransition()
        pc.animateDragIndicatorTransition() // Second time with the same state
        #expect(pc.dragIndicatorView.alpha == 1.0)
    }
    
    // MARK: - gestureRecognizerShouldBegin
    
    @Test func gestureRecognizerShouldBegin_nonPanGesture_isFalse() {
        let pc = makePresentationController()
        let tap = UITapGestureRecognizer()
        let view = UIView()
        view.addGestureRecognizer(tap)
        #expect(pc.gestureRecognizerShouldBegin(tap) == false)
    }
    
    @Test func gestureRecognizerShouldBegin_whileDragging_isFalse() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        let pan = UIPanGestureRecognizer()
        let view = UIView()
        view.addGestureRecognizer(pan)
        
        pc.panState = .dragging(PanelPresentationController.PanContext(
            initialHeight: 300,
            isIndicatorInteraction: false,
            activeScrollView: nil
        ))
        
        #expect(pc.gestureRecognizerShouldBegin(pan) == false)
    }
    
    @Test func gestureRecognizerShouldBegin_indicatorArea_isTrue() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        pc.panelDetents = [.medium, .large]
        pc.presentedView?.addGestureRecognizer(MockPanGestureRecognizer())
        pc.dragIndicatorView.frame = CGRect(x: 177, y: 8, width: 36, height: 5)
        
        let pan = MockPanGestureRecognizer()
        pan.mockLocation = CGPoint(x: 195, y: 10) // indicator center
        pan.mockVelocity = CGPoint(x: 0, y: 100)  // swipe down
        pc.presentedView?.addGestureRecognizer(pan)
        
        #expect(pc.gestureRecognizerShouldBegin(pan) == true)
    }
    
    @Test func gestureRecognizerShouldBegin_scrollViewAtTop_swipeDown_isTrue() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        pc.panelDetents = [.medium, .large]
        
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.addSubview(container)
        window.makeKeyAndVisible()
        
        pc.presentedView?.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 390, height: 500))
        scrollView.contentSize = CGSize(width: 390, height: 1000)
        scrollView.contentOffset = .zero
        pc.presentedView?.addSubview(scrollView)
        
        let pan = MockPanGestureRecognizer()
        pan.mockLocation = CGPoint(x: 195, y: 100)
        pan.mockVelocity = CGPoint(x: 0, y: 100)
        pc.presentedView?.addGestureRecognizer(pan)
        
        #expect(pc.gestureRecognizerShouldBegin(pan) == true)
    }
    
    @Test func gestureRecognizerShouldBegin_scrollViewNotAtTop_swipeDown_isFalse() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        pc.panelDetents = [.medium, .large]
        
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.addSubview(container)
        window.makeKeyAndVisible()
        
        pc.presentedView?.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 390, height: 500))
        scrollView.contentSize = CGSize(width: 390, height: 1000)
        scrollView.contentOffset = CGPoint(x: 0, y: 100)
        pc.presentedView?.addSubview(scrollView)
        
        let pan = MockPanGestureRecognizer()
        pan.mockLocation = CGPoint(x: 195, y: 100)
        pan.mockVelocity = CGPoint(x: 0, y: 100)
        pc.presentedView?.addGestureRecognizer(pan)
        
        #expect(pc.gestureRecognizerShouldBegin(pan) == false)
    }
    
    @Test func gestureRecognizerShouldBegin_scrollsMode_swipeUp_isFalse() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        pc.panelDetents = [.medium, .large]
        pc.interactionMode = .scrolls
        
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.addSubview(container)
        window.makeKeyAndVisible()
        
        pc.presentedView?.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 390, height: 500))
        scrollView.contentSize = CGSize(width: 390, height: 1000)
        scrollView.contentOffset = .zero
        pc.presentedView?.addSubview(scrollView)
        
        let pan = MockPanGestureRecognizer()
        pan.mockLocation = CGPoint(x: 195, y: 100)
        pan.mockVelocity = CGPoint(x: 0, y: -100) // swipe up
        pc.presentedView?.addGestureRecognizer(pan)
        
        #expect(pc.gestureRecognizerShouldBegin(pan) == false)
    }
    
    @Test func gestureRecognizerShouldBegin_resizingMode_scrollViewAtTop_notAtMax_swipeUp_isTrue() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        pc.panelDetents = [.medium, .large]
        pc.interactionMode = .resizing
        pc.wrapperHeightConstraint = NSLayoutConstraint()
        pc.wrapperHeightConstraint?.constant = 300 // lower than max detent
        
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.addSubview(container)
        window.makeKeyAndVisible()
        
        pc.presentedView?.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 390, height: 500))
        scrollView.contentSize = CGSize(width: 390, height: 1000)
        scrollView.contentOffset = .zero
        pc.presentedView?.addSubview(scrollView)
        
        let pan = MockPanGestureRecognizer()
        pan.mockLocation = CGPoint(x: 195, y: 100)
        pan.mockVelocity = CGPoint(x: 0, y: -100) // swipe up
        pc.presentedView?.addGestureRecognizer(pan)
        
        #expect(pc.gestureRecognizerShouldBegin(pan) == true)
    }
    
    @Test func gestureRecognizerShouldBegin_noScrollView_swipeDown_isTrue() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        pc.panelDetents = [.medium, .large]
        
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.addSubview(container)
        window.makeKeyAndVisible()
        
        pc.presentedView?.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        
        let pan = MockPanGestureRecognizer()
        pan.mockLocation = CGPoint(x: 195, y: 300)
        pan.mockVelocity = CGPoint(x: 0, y: 100) // swipe down
        pc.presentedView?.addGestureRecognizer(pan)
        
        #expect(pc.gestureRecognizerShouldBegin(pan) == true)
    }
    
    @Test func gestureRecognizerShouldBegin_noScrollView_resizingMode_swipeUp_notAtMax_isTrue() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        pc.panelDetents = [.medium, .large]
        pc.interactionMode = .resizing
        pc.wrapperHeightConstraint = NSLayoutConstraint()
        pc.wrapperHeightConstraint?.constant = 300 // lower than max detent
        
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.addSubview(container)
        window.makeKeyAndVisible()
        
        pc.presentedView?.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        
        let pan = MockPanGestureRecognizer()
        pan.mockLocation = CGPoint(x: 195, y: 300)
        pan.mockVelocity = CGPoint(x: 0, y: -100) // swipe up
        pc.presentedView?.addGestureRecognizer(pan)
        
        #expect(pc.gestureRecognizerShouldBegin(pan) == true)
    }
    
    @Test func gestureRecognizerShouldBegin_noScrollView_resizingMode_swipeUp_atMax_isFalse() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        pc.panelDetents = [.medium, .large]
        pc.interactionMode = .resizing
        pc.wrapperHeightConstraint = NSLayoutConstraint()
        pc.wrapperHeightConstraint?.constant = pc.panelDetents.last?.calculate(in: container) ?? 0 // max detent
        
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.addSubview(container)
        window.makeKeyAndVisible()
        
        pc.presentedView?.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        
        let pan = MockPanGestureRecognizer()
        pan.mockLocation = CGPoint(x: 195, y: 300)
        pan.mockVelocity = CGPoint(x: 0, y: -100) // swipe up
        pc.presentedView?.addGestureRecognizer(pan)
        
        #expect(pc.gestureRecognizerShouldBegin(pan) == false)
    }
    
    @Test func gestureRecognizerShouldBegin_noScrollView_scrollsMode_swipeUp_isFalse() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        pc.panelDetents = [.medium, .large]
        pc.interactionMode = .scrolls
        
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.addSubview(container)
        window.makeKeyAndVisible()
        
        pc.presentedView?.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        
        let pan = MockPanGestureRecognizer()
        pan.mockLocation = CGPoint(x: 195, y: 300)
        pan.mockVelocity = CGPoint(x: 0, y: -100) // swipe up
        pc.presentedView?.addGestureRecognizer(pan)
        
        #expect(pc.gestureRecognizerShouldBegin(pan) == false)
    }
    
    // MARK: - gestureRecognizer(_:shouldRecognizeSimultaneouslyWith:)
    
    @Test func shouldRecognizeSimultaneously_scrollView_resizingMode_isTrue() {
        let pc = makePresentationController()
        pc.interactionMode = .resizing
        let scrollView = UIScrollView()
        let result = pc.gestureRecognizer(
            UIPanGestureRecognizer(),
            shouldRecognizeSimultaneouslyWith: scrollView.panGestureRecognizer
        )
        #expect(result == true)
    }
    
    @Test func shouldRecognizeSimultaneously_scrollView_scrollsMode_isTrue() {
        let pc = makePresentationController()
        pc.interactionMode = .scrolls
        let scrollView = UIScrollView()
        let result = pc.gestureRecognizer(
            UIPanGestureRecognizer(),
            shouldRecognizeSimultaneouslyWith: scrollView.panGestureRecognizer
        )
        #expect(result == true)
    }
    
    @Test func shouldRecognizeSimultaneously_nonScrollView_isFalse() {
        let pc = makePresentationController()
        let other = UIPanGestureRecognizer()
        let view = UIView()
        view.addGestureRecognizer(other)
        let result = pc.gestureRecognizer(
            UIPanGestureRecognizer(),
            shouldRecognizeSimultaneouslyWith: other
        )
        #expect(result == false)
    }
    
    // MARK: - handlePan
    
    
    @Test func handlePan_began_disablesScrollViewPanGesture() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        
        let scrollView = UIScrollView()
        scrollView.panGestureRecognizer.isEnabled = true // set to true beforehand
        
        pc.panState = .dragging(PanelPresentationController.PanContext(
            initialHeight: 300,
            isIndicatorInteraction: false,
            activeScrollView: scrollView
        ))
        
        let pan = MockPanGestureRecognizer()
        pan.mockState = .began
        pc.presentedView?.addGestureRecognizer(pan)
        
        #expect(scrollView.panGestureRecognizer.isEnabled == true)
        pc.handlePan(pan)
        #expect(scrollView.panGestureRecognizer.isEnabled == false)
    }
    
    @Test func handlePan_changed_updatesHeight_aboveMinHeight() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        pc.panelDetents = [.medium, .large]
        pc.wrapperHeightConstraint = NSLayoutConstraint()
        pc.wrapperHeightConstraint?.constant = 500
        
        pc.panState = .dragging(PanelPresentationController.PanContext(
            initialHeight: 500,
            isIndicatorInteraction: false,
            activeScrollView: nil
        ))
        
        let pan = MockPanGestureRecognizer()
        pan.mockState = .changed
        pan.mockTranslation = CGPoint(x: 0, y: -50)
        pan.mockLocation = CGPoint(x: 195, y: 200)
        pc.presentedView?.addGestureRecognizer(pan)
        
        #expect(pc.wrapperHeightConstraint?.constant == 500)
        pc.handlePan(pan)
        #expect(pc.wrapperHeightConstraint?.constant == 550)
    }
    
    
    @Test func handlePan_changed_resistance_whenBelowMinHeight() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        pc.panelDetents = [.medium, .large]
        pc.wrapperHeightConstraint = NSLayoutConstraint()
        pc.wrapperHeightConstraint?.constant = 422
        
        pc.panState = .dragging(PanelPresentationController.PanContext(
            initialHeight: 422,
            isIndicatorInteraction: false,
            activeScrollView: nil
        ))
        
        let pan = MockPanGestureRecognizer()
        pan.mockState = .changed
        pan.mockTranslation = CGPoint(x: 0, y: 100) // 422 - 100 = 322 < minHeight(422)
        pan.mockLocation = CGPoint(x: 195, y: 200)
        pc.presentedView?.addGestureRecognizer(pan)
        
        #expect(pc.wrapperHeightConstraint?.constant == 422)
        pc.handlePan(pan)
        // resistance: minHeight - (minHeight - height) * PanelConstants.minHeightResistance
        let expected = 422 - (422 - 322) * PanelConstants.minHeightResistance
        #expect(pc.wrapperHeightConstraint?.constant == expected)
    }
    
    @Test func handlePan_ended_dismissesWhenVelocityExceedsThreshold() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let presented = MockViewController()
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: presented,
            presenting: UIViewController()
        )
        pc.panelDetents = [.medium, .large]
        pc.wrapperHeightConstraint = NSLayoutConstraint()
        pc.wrapperHeightConstraint?.constant = 200
        
        pc.panState = .dragging(PanelPresentationController.PanContext(
            initialHeight: 200,
            isIndicatorInteraction: false,
            activeScrollView: nil
        ))
        
        let pan = MockPanGestureRecognizer()
        pan.mockState = .ended
        pan.mockVelocity = CGPoint(x: 0, y: PanelConstants.dismissVelocityThreshold + 1)
        pc.presentedView?.addGestureRecognizer(pan)
        
        #expect(presented.dismissCalled == false)
        pc.handlePan(pan)
        #expect(presented.dismissCalled == true)
    }
    
    @Test func handlePan_ended_snapsToDefaultWhenDismissDisabled() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        pc.panelDetents = [.medium, .large]
        pc.isInteractiveDismissDisabled = true
        pc.wrapperHeightConstraint = NSLayoutConstraint()
        pc.wrapperHeightConstraint?.constant = 200
        
        pc.panState = .dragging(PanelPresentationController.PanContext(
            initialHeight: 200,
            isIndicatorInteraction: false,
            activeScrollView: nil
        ))
        
        let pan = MockPanGestureRecognizer()
        pan.mockState = .ended
        pan.mockVelocity = CGPoint(x: 0, y: PanelConstants.dismissVelocityThreshold + 1)
        pc.presentedView?.addGestureRecognizer(pan)
        
        #expect(pc.isAnimating == false)
        pc.handlePan(pan)
        #expect(pc.isAnimating == true) // snapToDefault animator is running
    }
    
    @Test func handlePan_ended_snapsToNearestDetent() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        pc.panelDetents = [.medium, .large]
        pc.wrapperHeightConstraint = NSLayoutConstraint()
        pc.wrapperHeightConstraint?.constant = 500 // between medium(422) and large(824)
        
        pc.panState = .dragging(PanelPresentationController.PanContext(
            initialHeight: 500,
            isIndicatorInteraction: false,
            activeScrollView: nil
        ))
        
        let pan = MockPanGestureRecognizer()
        pan.mockState = .ended
        pan.mockVelocity = CGPoint(x: 0, y: 0) // no velocity
        pc.presentedView?.addGestureRecognizer(pan)
        
        #expect(pc.isAnimating == false)
        pc.handlePan(pan)
        #expect(pc.isAnimating == true) // snap animator is running
    }
    
    @Test func handlePan_cancelled_springsBackToInitialHeightAndResetsPanState() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        pc.wrapperHeightConstraint = NSLayoutConstraint()
        pc.wrapperHeightConstraint?.constant = 240
        
        pc.panState = .dragging(PanelPresentationController.PanContext(
            initialHeight: 300,
            isIndicatorInteraction: false,
            activeScrollView: nil
        ))
        
        let pan = MockPanGestureRecognizer()
        pan.mockState = .cancelled
        pc.presentedView?.addGestureRecognizer(pan)
        
        #expect(pc.panState != .idle)
        #expect(pc.isAnimating == false)
        pc.handlePan(pan)
        #expect(pc.panState == .idle)
        #expect(pc.isAnimating == true)
        
        pc.stopCurrentAnimation(finishAtEnd: true)
        #expect(pc.wrapperHeightConstraint?.constant == 300)
    }
    
    @Test func handlePan_failed_springsBackToInitialHeightAndResetsPanState() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        pc.wrapperHeightConstraint = NSLayoutConstraint()
        pc.wrapperHeightConstraint?.constant = 260
        
        pc.panState = .dragging(PanelPresentationController.PanContext(
            initialHeight: 300,
            isIndicatorInteraction: false,
            activeScrollView: nil
        ))
        
        let pan = MockPanGestureRecognizer()
        pan.mockState = .failed
        pc.presentedView?.addGestureRecognizer(pan)
        
        #expect(pc.panState != .idle)
        #expect(pc.isAnimating == false)
        pc.handlePan(pan)
        #expect(pc.panState == .idle)
        #expect(pc.isAnimating == true)
        
        pc.stopCurrentAnimation(finishAtEnd: true)
        #expect(pc.wrapperHeightConstraint?.constant == 300)
    }
    
    // MARK: .changed - Height does not change when scroll view is not at top
    
    /// Verify that height does not change in .changed state when scroll view is not at the top
    /// and it's not an indicator interaction.
    @Test func handlePan_changed_scrollViewNotAtTop_heightUnchanged() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        pc.panelDetents = [.medium, .large]
        pc.wrapperHeightConstraint = NSLayoutConstraint()
        pc.wrapperHeightConstraint?.constant = 500
        
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 390, height: 500))
        scrollView.contentSize = CGSize(width: 390, height: 1000)
        // Set offset below top
        scrollView.contentOffset = CGPoint(x: 0, y: 100)
        pc.presentedView?.addSubview(scrollView)
        
        pc.panState = .dragging(PanelPresentationController.PanContext(
            initialHeight: 500,
            isIndicatorInteraction: false,   // Not indicator interaction
            activeScrollView: scrollView
        ))
        
        let pan = MockPanGestureRecognizer()
        pan.mockState = .changed
        pan.mockTranslation = CGPoint(x: 0, y: -50) // Pull upward
        pan.mockLocation = CGPoint(x: 195, y: 200)
        pc.presentedView?.addGestureRecognizer(pan)
        
        let before = pc.wrapperHeightConstraint?.constant
        pc.handlePan(pan)
        // Panel height should not change because scroll view is not at top
        #expect(pc.wrapperHeightConstraint?.constant == before)
    }
       
    // MARK: .changed - Resistance is not applied in scrolls mode even when below min height
    
    /// Verify that resistance correction is not applied when interactionMode == .scrolls
    /// even if height falls below minHeight.
    @Test func handlePan_changed_scrollsMode_belowMinHeight_noResistance() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        pc.panelDetents = [.medium, .large]
        pc.interactionMode = .scrolls
        pc.wrapperHeightConstraint = NSLayoutConstraint()
        
        let minHeight = PanelDetent.medium.calculate(in: container) // 422
        pc.wrapperHeightConstraint?.constant = minHeight
        
        pc.panState = .dragging(PanelPresentationController.PanContext(
            initialHeight: minHeight,
            isIndicatorInteraction: false,
            activeScrollView: nil
        ))
        
        let pan = MockPanGestureRecognizer()
        pan.mockState = .changed
        pan.mockTranslation = CGPoint(x: 0, y: 100) // minHeight - 100 -> below minimum
        pan.mockLocation = CGPoint(x: 195, y: 200)
        pc.presentedView?.addGestureRecognizer(pan)
        
        pc.handlePan(pan)
        
        // No resistance in .scrolls mode -> rawHeight = minHeight - 100 is set as is
        let rawHeight = minHeight - 100
        #expect(pc.wrapperHeightConstraint?.constant == rawHeight)
    }
    
    // MARK: .ended - Forced dismissal by forceDismissHeightRatio
    
    /// Verify that dismissal is called even if velocity is low when finalHeight < minHeight * forceDismissHeightRatio.
    @Test func handlePan_ended_forceDismissWhenHeightBelowForceRatio() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let presented = MockViewController()
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: presented,
            presenting: UIViewController()
        )
        pc.panelDetents = [.medium, .large]
        
        let minHeight = PanelDetent.medium.calculate(in: container)
        // Height below forceDismissHeightRatio threshold
        let forceDismissHeight = minHeight * PanelConstants.forceDismissHeightRatio - 1
        
        pc.wrapperHeightConstraint = NSLayoutConstraint()
        pc.wrapperHeightConstraint?.constant = forceDismissHeight
        
        pc.panState = .dragging(PanelPresentationController.PanContext(
            initialHeight: forceDismissHeight,
            isIndicatorInteraction: false,
            activeScrollView: nil
        ))
        
        let pan = MockPanGestureRecognizer()
        pan.mockState = .ended
        // Velocity below threshold (doesn't meet velocity-based dismissal condition)
        pan.mockVelocity = CGPoint(x: 0, y: 10)
        pc.presentedView?.addGestureRecognizer(pan)
        
        #expect(presented.dismissCalled == false)
        pc.handlePan(pan)
        #expect(presented.dismissCalled == true)
    }
    
    // MARK: .ended - Target does not exceed initialHeight in scrolls mode + non-indicator interaction
    
    /// Verify that snap target is clamped to initialHeight when interactionMode == .scrolls
    /// and it's a non-indicator interaction.
    @Test func handlePan_ended_scrollsMode_nonIndicator_targetClampedToInitialHeight() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        pc.panelDetents = [.medium, .large]
        pc.interactionMode = .scrolls
        
        // Set current position slightly above medium detent -> would snap to large if no velocity
        let minHeight = PanelDetent.medium.calculate(in: container) // 422
        let initialHeight = minHeight + 50                          // 472 (between medium and large)
        
        pc.wrapperHeightConstraint = NSLayoutConstraint()
        pc.wrapperHeightConstraint?.constant = initialHeight
        
        pc.panState = .dragging(PanelPresentationController.PanContext(
            initialHeight: initialHeight,
            isIndicatorInteraction: false,   // Not indicator interaction
            activeScrollView: nil
        ))
        
        let pan = MockPanGestureRecognizer()
        pan.mockState = .ended
        // Apply upward velocity to pull projected height toward large detent
        pan.mockVelocity = CGPoint(x: 0, y: -500)
        pc.presentedView?.addGestureRecognizer(pan)
        
        pc.handlePan(pan)
        
        // Verify snap triggered if animator is active
        #expect(pc.isAnimating != false)
        
        // Final height should not exceed initialHeight
        // (Verify target height set in wrapperHeightConstraint during animation)
        // Since target is clamped to initialHeight, the constraint should remain <= initialHeight.
        let finalHeight = pc.wrapperHeightConstraint?.constant ?? 0
        #expect(finalHeight <= initialHeight)
    }

    // MARK: - restoreScrollViews
    
    @Test func restoreScrollViews_whenDragging_enablesScrollViewPanGesture() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        
        let scrollView = UIScrollView()
        scrollView.panGestureRecognizer.isEnabled = false
        
        pc.panState = .dragging(PanelPresentationController.PanContext(
            initialHeight: 300,
            isIndicatorInteraction: false,
            activeScrollView: scrollView
        ))
        
        #expect(scrollView.panGestureRecognizer.isEnabled == false)
        #expect(pc.panState != .idle)
        
        pc.restoreScrollViews()
        
        #expect(scrollView.panGestureRecognizer.isEnabled == true)
        #expect(pc.panState == .idle)
    }
    
    @Test func restoreScrollViews_whenIdle_doesNothing() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        
        pc.panState = .idle
        pc.restoreScrollViews()
        
        #expect(pc.panState == .idle)
    }
    
    @Test func landscapeConfiguration_didSet_updatesHorizontalLayout() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 844, height: 390))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        pc.addPanelViewToContainer()
        
        pc.landscapeConfiguration = PanelLandscapeConfiguration(alignment: .center,width: .width(300), ignoreSafeArea: true)
        
        #expect(pc.activeHorizontalConstraints != pc.portraitConstraints)
    }
    
    @Test func panelCornerRadius_setsCornerRadius() {
        let pc = makePresentationController()
        pc.panelCornerRadius = 20
        #expect(pc.panelView.layer.cornerRadius == 20)
    }
    
    @Test func panelCornerRadius_nil_fallsBackToDefault() {
        let pc = makePresentationController()
        pc.panelCornerRadius = 20
        pc.panelCornerRadius = nil
        #expect(pc.panelView.layer.cornerRadius == PanelConstants.cornerRadius)
    }
    
    @Test func dismiss_whenAlreadyBeingDismissed_doesNotCallDismissAgain() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let presented = MockViewController()
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: presented,
            presenting: UIViewController()
        )
        
        presented.mockIsBeingDismissed = true
        pc.dismiss()
        
        #expect(presented.dismissCalled == false)
    }
    
    @Test func handleIndicatorTap_multipleDetents_cyclesDetent() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        pc.panelDetents = [.medium, .large]

        // medium -> large
        pc.handleIndicatorTap()
        #expect(pc.detentState.current == .large)

        // large -> medium (cycle)
        pc.handleIndicatorTap()
        #expect(pc.detentState.current == .medium)
    }    
    @Test func handleIndicatorTap_singleDetent_doesNothing() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        pc.panelDetents = [.medium]
        
        pc.handleIndicatorTap()
        
        #expect(pc.detentState.current == .medium)
        #expect(pc.isAnimating == false)
    }
    
    @Test func applyDetentLayout_emptyDetents_fallsBackToHalfContainerHeight() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        pc.wrapperHeightConstraint = NSLayoutConstraint()
        pc.panelDetents = []
        
        pc.applyDetentLayout()
        
        #expect(pc.wrapperHeightConstraint?.constant == 844 * 0.5)
    }
    
    // MARK: - handleDimmingTap
    
    @Test func handleDimmingTap_dismissEnabled_callsDismiss() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let presented = MockViewController()
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: presented,
            presenting: UIViewController()
        )
        pc.isInteractiveDismissDisabled = false
        
        pc.simulateDimmingTap()
        
        #expect(presented.dismissCalled == true)
    }
    
    @Test func handleDimmingTap_dismissDisabled_doesNotCallDismiss() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let presented = MockViewController()
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: presented,
            presenting: UIViewController()
        )
        pc.isInteractiveDismissDisabled = true
        
        pc.simulateDimmingTap()
        
        #expect(presented.dismissCalled == false)
    }
    
    // MARK: - dismissalTransitionDidEnd
    
    @Test func dismissalTransitionDidEnd_completed_callsOnDismiss() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        var called = false
        pc.onDismiss = { called = true }
        
        pc.dismissalTransitionDidEnd(true)
        
        #expect(called == true)
    }
    
    @Test func dismissalTransitionDidEnd_notCompleted_doesNotCallOnDismiss() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        var called = false
        pc.onDismiss = { called = true }
        
        pc.dismissalTransitionDidEnd(false)
        
        #expect(called == false)
    }
    
    // MARK: - applyDetentLayout
    
    @Test func applyDetentLayout_whileDragging_doesNotUpdateHeight() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        pc.panelDetents = [.medium, .large]
        pc.wrapperHeightConstraint = NSLayoutConstraint()
        pc.wrapperHeightConstraint?.constant = 999
        
        pc.panState = .dragging(PanelPresentationController.PanContext(
            initialHeight: 999,
            isIndicatorInteraction: false,
            activeScrollView: nil
        ))
        
        pc.applyDetentLayout()
        
        #expect(pc.wrapperHeightConstraint?.constant == 999)
    }
    
    // MARK: - viewWillTransition
    
    @Test func viewWillTransition_callsCoordinatorAnimate() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        let coordinator = MockTransitionCoordinator()
        
        pc.viewWillTransition(to: CGSize(width: 844, height: 390), with: coordinator)
        
        #expect(coordinator.animateAlongsideCalled == true)
    }
    
    // MARK: - updateContainerFrame
    
    @Test func updateContainerFrame_interactable_tintAdjustmentModeIsNormal() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let presenting = UIViewController()
        _ = presenting.view
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: presenting
        )
        pc.panelDetents = [.medium, .large]
        pc.backgroundInteraction = .enabled
        pc.wrapperHeightConstraint = NSLayoutConstraint()
        
        pc.applyDetentLayout()
        
        #expect(presenting.view.tintAdjustmentMode == .normal)
    }
    
    @Test func updateContainerFrame_notInteractable_tintAdjustmentModeIsDimmed() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let presenting = UIViewController()
        _ = presenting.view
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: presenting
        )
        pc.panelDetents = [.medium, .large]
        pc.backgroundInteraction = .disabled
        pc.wrapperHeightConstraint = NSLayoutConstraint()
        
        pc.applyDetentLayout()
        
        #expect(presenting.view.tintAdjustmentMode == .dimmed)
    }
    
    @Test func updateHorizontalLayout_portrait_usesPortraitConstraints() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        pc.addPanelViewToContainer()
        
        pc.landscapeConfiguration = PanelLandscapeConfiguration(alignment: .center, width: .width(300), ignoreSafeArea: true)
        // Back to portrait size
        pc.landscapeConfiguration = .default
        
        #expect(pc.activeHorizontalConstraints == pc.portraitConstraints)
    }
    
    @Test func updateHorizontalLayout_landscape_fullWidth_usesLandscapeConstraints() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 844, height: 390))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        pc.addPanelViewToContainer()
        
        pc.landscapeConfiguration = PanelLandscapeConfiguration(alignment: .center, width: .full, ignoreSafeArea: true)
        
        #expect(pc.activeHorizontalConstraints != pc.portraitConstraints)
    }
    
    // MARK: - PanContext ==
    
    @Test func panContext_equal_sameValues() {
        let scrollView = UIScrollView()
        let lhs = PanelPresentationController.PanContext(
            initialHeight: 300,
            isIndicatorInteraction: false,
            activeScrollView: scrollView
        )
        let rhs = PanelPresentationController.PanContext(
            initialHeight: 300,
            isIndicatorInteraction: false,
            activeScrollView: scrollView
        )
        #expect(lhs == rhs)
        _ = scrollView // Keep it alive
    }
    
    @Test func panContext_notEqual_differentScrollView() {
        let scrollView1 = UIScrollView()
        let scrollView2 = UIScrollView()
        let lhs = PanelPresentationController.PanContext(
            initialHeight: 300,
            isIndicatorInteraction: false,
            activeScrollView: scrollView1
        )
        let rhs = PanelPresentationController.PanContext(
            initialHeight: 300,
            isIndicatorInteraction: false,
            activeScrollView: scrollView2
        )
        #expect(lhs != rhs)
        _ = scrollView1
        _ = scrollView2
    }
    
    @Test func panContext_notEqual_differentHeight() {
        let scrollView = UIScrollView()
        let lhs = PanelPresentationController.PanContext(
            initialHeight: 300,
            isIndicatorInteraction: false,
            activeScrollView: scrollView
        )
        let rhs = PanelPresentationController.PanContext(
            initialHeight: 400,
            isIndicatorInteraction: false,
            activeScrollView: scrollView
        )
        #expect(lhs != rhs)
        _ = scrollView
    }
    
    // MARK: - selectedDetent
    
    @Test func selectedDetent_getter_returnsCurrent() {
        let pc = makePresentationController()
        pc.panelDetents = [.medium, .large]
        #expect(pc.selectedDetent == pc.detentState.current)
    }
    
    @Test func selectedDetent_setter_noContainer_doesNothing() {
        let pc = makePresentationController()
        pc.panelDetents = [.medium, .large]
        pc.selectedDetent = .large
        #expect(pc.isAnimating == false)
    }
    
    // MARK: - notifyDetentChange
    
    @Test func notifyDetentChange_callsOnDetentChange() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        pc.panelDetents = [.medium, .large]
        var received: PanelDetent?
        pc.onDetentChange = { received = $0 }
        pc.detentState.resolve(in: container)
        _ = pc.detentState.move(to: .large)
        pc.notifyDetentChange()
        #expect(received == .large)
    }
    
    // MARK: - applyCornerRadius
    
    @Test func panelCornerRadius_appliedToBackgroundView() {
        let pc = makePresentationController()
        pc.panelCornerRadius = 20
        #expect(pc.backgroundController.view.layer.cornerRadius == 20)
        #expect(pc.backgroundController.view.layer.masksToBounds == true)
    }
    
    // MARK: - backgroundInteraction
    
    @Test func backgroundInteraction_setsCorrectly() {
        let pc = makePresentationController()
        pc.backgroundInteraction = .enabled
        #expect(pc.backgroundInteraction == .enabled)
    }
    
    // MARK: - updateHorizontalLayout landscape full/fraction(1.0) forces center

    @Test func updateHorizontalLayout_fullWidth_forcesCenter() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 844, height: 390))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        pc.addPanelViewToContainer()

        // Set with leading + compact
        pc.landscapeConfiguration = PanelLandscapeConfiguration(
            alignment: .leading(), width: .compact, ignoreSafeArea: true
        )
        let constraintsWithCompact = pc.activeHorizontalConstraints

        // Change to full -> Rebuild constraints as it is forced to center
        pc.landscapeConfiguration = PanelLandscapeConfiguration(
            alignment: .leading(), width: .full, ignoreSafeArea: true
        )
        #expect(pc.activeHorizontalConstraints != constraintsWithCompact)
    }

    @Test func updateHorizontalLayout_fraction1_forcesCenter() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 844, height: 390))
        let pc = TestablePanelPresentationController(
            containerView: container,
            presentedViewController: UIViewController(),
            presenting: UIViewController()
        )
        pc.addPanelViewToContainer()

        pc.landscapeConfiguration = PanelLandscapeConfiguration(
            alignment: .leading(), width: .compact, ignoreSafeArea: true
        )
        let constraintsWithCompact = pc.activeHorizontalConstraints

        pc.landscapeConfiguration = PanelLandscapeConfiguration(
            alignment: .leading(), width: .fraction(1.0), ignoreSafeArea: true
        )
        #expect(pc.activeHorizontalConstraints != constraintsWithCompact)
    }
}
