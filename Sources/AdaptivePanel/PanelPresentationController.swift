//
//  PanelPresentationController.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/05/17.
//  
//

import SwiftUI
import UIKit

@MainActor
protocol PanelPreferenceReceiver: AnyObject {
    var panelDetents: [PanelDetent] { get set }
    var landscapeConfiguration: PanelLandscapeConfiguration { get set }
    var interactionMode: PanelInteraction { get set }
    var dragIndicatorVisibility: Visibility { get set }
    var isInteractiveDismissDisabled: Bool { get set }
    var panelCornerRadius: CGFloat? { get set }
    var backgroundInteraction: PanelBackgroundInteraction { get set }
    var selectedDetent: PanelDetent? { get set }
    var onDetentChange: ((PanelDetent) -> Void)? { get set }
    var backgroundController: PanelBackgroundHostingController { get }

    func updateBackgroundStyle(_ style: AnyShapeStyle)
    func updateBackground<Content: View>(alignment: Alignment, @ViewBuilder content: () -> Content)
}

/// Controls panel layout, background behavior, drag interaction, and dismissal.
@MainActor
internal class PanelPresentationController: UIPresentationController, PanelPreferenceReceiver, UIGestureRecognizerDelegate {
    let dimmedColor = UIColor.black.withAlphaComponent(0.3)

    internal enum PanState: Equatable {
        case idle
        case dragging(PanContext)
    }

    internal struct PanContext: Equatable {
        let initialHeight: CGFloat
        let isIndicatorInteraction: Bool
        weak var activeScrollView: UIScrollView?
        
        static func == (lhs: PanContext, rhs: PanContext) -> Bool {
            lhs.initialHeight == rhs.initialHeight &&
            lhs.isIndicatorInteraction == rhs.isIndicatorInteraction &&
            lhs.activeScrollView === rhs.activeScrollView
        }
    }
    
    internal var panState: PanState = .idle
    internal var portraitConstraints: [NSLayoutConstraint] = []
    private var widthConstraint: NSLayoutConstraint?
    private var alignmentConstraint: NSLayoutConstraint?
    private var cachedAlignment: PanelLandscapeAlignment?

    internal var activeHorizontalConstraints: [NSLayoutConstraint] = [] {
        didSet {
            guard oldValue != activeHorizontalConstraints else { return }
            NSLayoutConstraint.deactivate(oldValue)
            NSLayoutConstraint.activate(activeHorizontalConstraints)
        }
    }

    var landscapeConfiguration: PanelLandscapeConfiguration = .default {
        didSet {
            cachedAlignment = nil
            if let container = containerView {
                updateHorizontalLayout(for: container.bounds.size)
                container.setNeedsLayout()
            }
        }
    }

    private var lastIndicatorVisible: Bool?

    var interactionMode: PanelInteraction = .resizing
    
    var detentState = DetentState(detents: PanelDetentKey.defaultValue)
    
    var panelDetents: [PanelDetent] {
        get { detentState.detents }
        set {
            detentState.detents = newValue
            if let container = containerView {
                detentState.resolve(in: container)
            }
            containerView?.setNeedsLayout()
        }
    }
    
    var selectedDetent: PanelDetent? {
        get { detentState.current }
        set {
            guard let newValue, let height = detentState.move(to: newValue) else { return }
            animateTo(height: height)
        }
    }
    
    var onDetentChange: ((PanelDetent) -> Void)?

    internal func notifyDetentChange() {
        guard let detent = selectedDetent else { return }
        onDetentChange?(detent)
    }

    var dragIndicatorVisibility: Visibility = PanelDragIndicatorVisibleKey.defaultValue {
        didSet { animateDragIndicatorTransition() }
    }

    var isDragIndicatorVisible: Bool {
        dragIndicatorVisibility == .visible ||
        (dragIndicatorVisibility == .automatic && detentState.count > 1)
    }

    var isInteractiveDismissDisabled = false
    var panelCornerRadius: CGFloat? {
        didSet {
            applyCornerRadius(panelCornerRadius ?? PanelConstants.cornerRadius)
        }
    }
    
    private func applyCornerRadius(_ radius: CGFloat) {
        panelView.layer.cornerRadius = radius
        panelView.layer.masksToBounds = false
        panelView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        for view in [backgroundController.view, presentedViewController.view] {
            view?.layer.cornerRadius = radius
            view?.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            view?.layer.masksToBounds = true
        }
    }
    
    var onDismiss: (() -> Void)?
    var backgroundInteraction: PanelBackgroundInteraction = PanelBackgroundInteractionKey.defaultValue
    
    internal lazy var heightAnimator: HeightAnimator = {
        let animator = HeightAnimator(
            dampingRatio: PanelConstants.snapDampingRatio
        )
        animator.onUpdate = { [weak self] height in
            self?.updateContainerFrame(height: height)
        }
        animator.onCompletion = { [weak self] in
            self?.notifyDetentChange()
        }
        return animator
    }()
    
    internal var wrapperHeightConstraint: NSLayoutConstraint?
    internal let dragIndicatorView: UIView

    internal let panelView = UIView()
    private let dimmingView = DimmingView()

    private lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        gesture.delegate = self
        gesture.cancelsTouchesInView = false
        return gesture
    }()
    
    override var presentedView: UIView? { panelView }

    internal init(presentedViewController: UIViewController, presenting: UIViewController?, dragIndicator: UIView? = nil) {
        self.dragIndicatorView = dragIndicator ?? DragIndicatorView()
        super.init(presentedViewController: presentedViewController, presenting: presenting)
        self.panelDetents = PanelDetentKey.defaultValue
        setupViews()
    }
    
    internal let backgroundController = PanelBackgroundHostingController()
        
    /// Updates only the background style while preserving the presentation hierarchy.
    func updateBackgroundStyle(_ style: AnyShapeStyle) {
        backgroundController.updateBackgroundStyle(style)
    }
    
    func updateBackground<Content: View>(alignment: Alignment, @ViewBuilder content: () -> Content) {
        backgroundController.updateBackground(alignment: alignment, content: content)
    }

    private func setupViews() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleIndicatorTap))
        dragIndicatorView.addGestureRecognizer(tap)
        dimmingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDimmingTap)))
        dimmingView.backgroundColor = .clear
        dragIndicatorView.accessibilityLabel = "Resize panel"
        dragIndicatorView.accessibilityHint = "Tap to cycle through sizes"
    }

    /// Toggles only the visual indicator; the drag hit area remains active when hidden.
    func animateDragIndicatorTransition() {
        guard dragIndicatorView.superview != nil else { return }
        let target = isDragIndicatorVisible
        guard target != lastIndicatorVisible else { return }
        lastIndicatorVisible = target
        dragIndicatorView.isAccessibilityElement = target
        UIView.animate(withDuration: PanelConstants.indicatorAnimationDuration) {
            self.dragIndicatorView.alpha = target ? 1.0 : 0
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        stopCurrentAnimation(finishAtEnd: true)        
        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let self, let container = self.containerView else { return }
            self.updateHorizontalLayout(for: size)
            container.layoutIfNeeded()
        })
    }

    override func presentationTransitionWillBegin() {
        guard let container = containerView, let contentView = presentedViewController.view else { return }
        contentView.backgroundColor = .clear

        dimmingView.presentingView = presentingViewController.view
        dimmingView.alpha = 0
        backgroundController.view.isUserInteractionEnabled = false

        container.addSubview(dimmingView)
        container.addSubview(panelView)
        panelView.addSubview(backgroundController.view)
        panelView.addSubview(contentView)
        panelView.addSubview(dragIndicatorView)
        applyCornerRadius(panelCornerRadius ?? PanelConstants.cornerRadius)

        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        panelView.translatesAutoresizingMaskIntoConstraints = false
        backgroundController.view.translatesAutoresizingMaskIntoConstraints = false
        dragIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        container.keyboardLayoutGuide.usesBottomSafeArea = false

        // The panel height is driven by the content view height constraint.
        let heightConstraint = panelView.heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.priority = UILayoutPriority(999)
        self.wrapperHeightConstraint = heightConstraint

        NSLayoutConstraint.activate([
            dimmingView.topAnchor.constraint(equalTo: container.topAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            panelView.bottomAnchor.constraint(equalTo: container.keyboardLayoutGuide.topAnchor),
            panelView.topAnchor.constraint(greaterThanOrEqualTo: container.safeAreaLayoutGuide.topAnchor),
            heightConstraint,

            backgroundController.view.topAnchor.constraint(equalTo: panelView.topAnchor),
            backgroundController.view.leadingAnchor.constraint(equalTo: panelView.leadingAnchor),
            backgroundController.view.trailingAnchor.constraint(equalTo: panelView.trailingAnchor),
            backgroundController.view.bottomAnchor.constraint(equalTo: panelView.bottomAnchor),

            dragIndicatorView.topAnchor.constraint(equalTo: panelView.topAnchor, constant: PanelConstants.dragIndicatorTopPadding),
            dragIndicatorView.centerXAnchor.constraint(equalTo: panelView.centerXAnchor),

            contentView.topAnchor.constraint(equalTo: panelView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: panelView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: panelView.trailingAnchor),
            contentView.heightAnchor.constraint(equalTo: panelView.heightAnchor),
            contentView.bottomAnchor.constraint(equalTo: container.keyboardLayoutGuide.topAnchor),
        ])

        portraitConstraints = [
            panelView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            panelView.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ]

        panelView.bringSubviewToFront(dragIndicatorView)
        panelView.addGestureRecognizer(panGesture)
        updateHorizontalLayout(for: container.bounds.size)

        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] _ in
            self?.dimmingView.alpha = 1
        })
    }

    override func dismissalTransitionWillBegin() {
        stopCurrentAnimation(finishAtEnd: false)
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] _ in
            self?.dimmingView.alpha = 0
            self?.presentingViewController.view.tintAdjustmentMode = .automatic
        })
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        if completed {
            onDismiss?()
        }
    }

    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        if let containerView {
            detentState.resolve(in: containerView)
        }
        applyDetentLayout()
        dimmingView.activePanelFrame = panelView.frame
     }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        guard other.view is UIScrollView else { return false }
        return [.resizing, .scrolls].contains(interactionMode)
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
              let view = gestureRecognizer.view,
              case .idle = panState else { return false }

        let location = pan.location(in: view)
        let velocity = pan.velocity(in: view)
        let currentHeight = wrapperHeightConstraint?.constant ?? panelView.frame.height
        let isSwipingDown = velocity.y > 0
        let maxHeight = detentState.maxHeight
        let isAtMax = currentHeight >= maxHeight - 1
        let indicatorArea = dragIndicatorView.frame.inset(by: PanelConstants.dragIndicatorHitArea)
        let isIndicator = indicatorArea.contains(location)
        let targetScroll = view.findScrollView(point: location)

        if !isIndicator {
            if let scroll = targetScroll {
                let isScrollTop = scroll.contentOffset.y <= -scroll.adjustedContentInset.top + 1.0
                guard isScrollTop || !isSwipingDown else { return false }
                guard interactionMode != .scrolls || isSwipingDown else { return false }
                guard isSwipingDown || !isAtMax else { return false }
            } else {
                guard isSwipingDown || (interactionMode == .resizing && !isAtMax) else { return false }
            }
        }

        panState = .dragging(PanContext(
            initialHeight: currentHeight,
            isIndicatorInteraction: isIndicator,
            activeScrollView: targetScroll
        ))
        return true
    }

    func restoreScrollViews() {
        if case .dragging(let context) = panState {
            context.activeScrollView?.panGestureRecognizer.isEnabled = true
            panState = .idle
        }
    }


    private func updateHorizontalLayout(for size: CGSize) {
        guard let container = containerView else { return }
        let isLandscape = size.width > size.height

        if isLandscape {
            let isFull = landscapeConfiguration.width == .full
                || landscapeConfiguration.width == .fraction(1.0)
            let effectiveAlignment: PanelLandscapeAlignment = isFull ? .center : landscapeConfiguration.alignment

            if cachedAlignment != effectiveAlignment {
                rebuildAlignmentConstraint(in: container, alignment: effectiveAlignment)
            }
            widthConstraint?.constant = landscapeConfiguration.width.calculate(in: container)
            activeHorizontalConstraints = [widthConstraint, alignmentConstraint].compactMap { $0 }
        } else {
            activeHorizontalConstraints = portraitConstraints
            widthConstraint = nil
            alignmentConstraint = nil
            cachedAlignment = nil
        }
    }

    private func rebuildAlignmentConstraint(in container: UIView, alignment: PanelLandscapeAlignment) {
        let leadingWall = landscapeConfiguration.ignoreSafeArea ? container.leadingAnchor : container.safeAreaLayoutGuide.leadingAnchor
        let trailingWall = landscapeConfiguration.ignoreSafeArea ? container.trailingAnchor : container.safeAreaLayoutGuide.trailingAnchor

        if widthConstraint == nil {
            widthConstraint = panelView.widthAnchor.constraint(equalToConstant: 0)
        }

        switch alignment {
        case .leading(let space):
            alignmentConstraint = panelView.leadingAnchor.constraint(equalTo: leadingWall, constant: space)
        case .trailing(let space):
            alignmentConstraint = panelView.trailingAnchor.constraint(equalTo: trailingWall, constant: -space)
        case .center:
            alignmentConstraint = panelView.centerXAnchor.constraint(equalTo: container.centerXAnchor)
        }
        cachedAlignment = alignment
    }

    internal func applyDetentLayout() {
        // Avoid reapplying layout while dragging or snapping so user interaction wins.
        if case .dragging = panState { return }
        guard let containerView,
              !heightAnimator.isAnimating,
              !presentedViewController.isBeingDismissed else { return }

        guard !detentState.isEmpty else {
            let fallback = containerView.bounds.height * 0.5
            updateContainerFrame(height: fallback)
            return
        }
        updateContainerFrame(height: detentState.currentHeight)
    }

    @objc private func handleDimmingTap() {
        if isInteractiveDismissDisabled { return }
        dismiss()
    }

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard case .dragging(let context) = panState, let container = containerView else { return }

        switch gesture.state {
        case .began:
            stopCurrentAnimation(finishAtEnd: false)
            context.activeScrollView?.panGestureRecognizer.isEnabled = false

        case .changed:
            let translation = gesture.translation(in: container)
            if let scroll = context.activeScrollView,
               scroll.contentOffset.y > -scroll.adjustedContentInset.top,
               !context.isIndicatorInteraction {
                return
            }
            
            let minHeight = detentState.minHeight
            let softMaxHeight = detentState.maxHeight

            let hardMaxHeight = container.bounds.height - container.safeAreaInsets.top

            var height = context.initialHeight - translation.y

            let isScrollingContent = (interactionMode == .scrolls && !context.isIndicatorInteraction)
            if height > softMaxHeight && !isScrollingContent {
                let overflow = height - softMaxHeight
                height = softMaxHeight + sqrt(overflow) * 12
            }
            height = min(height, hardMaxHeight)
            if height < minHeight {
                height = (interactionMode == .scrolls) ? height : minHeight - (minHeight - height) * PanelConstants.minHeightResistance
            }
            updateContainerFrame(height: height, isInteractive: true)

        case .ended:
            defer { resetPanState() }
            let velocity = gesture.velocity(in: container)
            let finalHeight = wrapperHeightConstraint?.constant ?? panelView.frame.height
            let projected = finalHeight - (velocity.y * 0.2)

            let minHeight = detentState.minHeight

            // Treat a strong downward gesture near the minimum detent as dismissal.
            let shouldDismiss = (
                velocity.y > PanelConstants.dismissVelocityThreshold &&
                finalHeight < minHeight * PanelConstants.dismissVelocityHeightRatio
            ) || finalHeight < minHeight * PanelConstants.forceDismissHeightRatio

            if shouldDismiss {
                if isInteractiveDismissDisabled {
                    snapToDefault()
                    return
                }
                dismiss()
                return
            }

            var target = detentState.nearest(to: projected)
            if interactionMode == .scrolls && !context.isIndicatorInteraction && target > context.initialHeight {
                target = detentState.nearest(to: context.initialHeight)
            }
            animateTo(height: target, velocity: velocity.y)

        case .cancelled, .failed:
            defer { resetPanState() }
            let velocity = gesture.velocity(in: container)
            animateTo(height: context.initialHeight, velocity: velocity.y)

        default:
            resetPanState()
        }
    }

    @objc internal func handleIndicatorTap() {
        guard detentState.count > 1 else { return }
        animateTo(height: detentState.next())
    }

    private func animateTo(height: CGFloat, velocity: CGFloat = 0) {
        dismissKeyboardIfNeeded()
        let currentHeight = wrapperHeightConstraint?.constant ?? 0
        heightAnimator.animate(
            from: currentHeight,
            to: height,
            duration: PanelConstants.snapAnimationDuration
        )
    }

    private func stopCurrentAnimation(finishAtEnd: Bool) {
        heightAnimator.stop(finishAtEnd: finishAtEnd)
    }

    private func resetPanState() {
        if case .dragging(let context) = panState {
            context.activeScrollView?.panGestureRecognizer.isEnabled = true
        }
        self.panState = .idle
    }

    private func snapToDefault() {
        animateTo(height: detentState.minHeight)
    }

    private func updateContainerFrame(height: CGFloat, isInteractive: Bool = false) {
        guard let containerView else { return }

        let current = wrapperHeightConstraint?.constant ?? 0
        // Non-interactive updates must still refresh background interaction at the same height.
        if isInteractive {
            guard current != height else { return }
        }

        wrapperHeightConstraint?.constant = height
        containerView.layoutIfNeeded()

        let isInteractable = backgroundInteraction.isInteractable(currentHeight: height, in: containerView)

        dimmingView.isPassthrough = isInteractable
        dimmingView.backgroundColor = isInteractable ? .clear : dimmedColor
        presentingViewController.view.tintAdjustmentMode = isInteractable ? .automatic : .dimmed

        animateDragIndicatorTransition()
    }

    internal func dismiss() {
        guard !presentedViewController.isBeingDismissed else { return }
        presentedViewController.dismiss(animated: true)
    }
    
    private func dismissKeyboardIfNeeded() {
        guard let containerView else { return }
        if containerView.keyboardLayoutGuide.layoutFrame.height > 0 {
            containerView.window?.endEditing(true)
        }
    }
    
    @MainActor
    struct DetentState {

        // MARK: - Nested Types

        private struct CachedPanelDetent {
            let detent: PanelDetent
            let height: CGFloat
        }

        // MARK: - State

        private var _current: PanelDetent?
        var current: PanelDetent {
            _current ?? cachedDetents.first?.detent ?? .large
        }

        var detents: [PanelDetent] {
            didSet {
                invalidate()
                if let c = _current, !detents.contains(c) { _current = nil }
            }
        }

        private var cachedDetents: [CachedPanelDetent] = []
        private var cachedSize: CGSize?

        var count: Int { detents.count }
        var isEmpty: Bool { detents.isEmpty }

        // MARK: - Init

        init(detents: [PanelDetent]) {
            self.detents = detents
        }

        // MARK: - Resolve

        private mutating func invalidate() {
            cachedDetents = []
            cachedSize = nil
        }

        mutating func resolve(in container: UIView) {
            let size = container.bounds.size
            guard cachedSize != size else { return }

            let largeHeight = PanelDetent.large.calculate(in: container)
            let maxHeight = container.bounds.height - container.safeAreaInsets.top

            cachedDetents = detents
                .map { CachedPanelDetent(detent: $0, height: min($0.calculate(in: container), largeHeight, maxHeight)) }
                .sorted { $0.height < $1.height }

            cachedSize = size
        }

        // MARK: - Query

        var currentHeight: CGFloat {
            return cachedDetents.first { $0.detent == current }?.height ?? cachedDetents.first?.height ?? 0
        }

        var minHeight: CGFloat {
            return cachedDetents.first?.height ?? 0
        }

        var maxHeight: CGFloat {
            return cachedDetents.last?.height ?? 0
        }

        // MARK: - Mutation

        /// To the next detent via indicator tap
        mutating func next() -> CGFloat {
            guard let idx = cachedDetents.firstIndex(where: { $0.detent == current }) else {
                return cachedDetents.first?.height ?? 0
            }
            let next = cachedDetents[(idx + 1) % cachedDetents.count]
            _current = next.detent
            return next.height
        }

        /// To the nearest detent when dragging ends
        mutating func nearest(to projected: CGFloat) -> CGFloat {
            guard let nearest = cachedDetents.min(by: { abs($0.height - projected) < abs($1.height - projected) }) else {
                return cachedDetents.first?.height ?? 0
            }
            _current = nearest.detent
            return nearest.height
        }

        /// To a specific detent from selectedDetent setter
        mutating func move(to detent: PanelDetent) -> CGFloat? {
            guard detent != current else { return nil }
            guard let cached = cachedDetents.first(where: { $0.detent == detent }) else { return nil }
            _current = cached.detent
            return cached.height
        }
    }
    
    @MainActor
    final class HeightAnimator {
        // MARK: - Public

        var isAnimating: Bool {
            animator != nil
        }

        var onUpdate: ((CGFloat) -> Void)?
        var onCompletion: (() -> Void)?

        // MARK: - Private

        private var animator: UIViewPropertyAnimator?

        private let dampingRatio: CGFloat

        // MARK: - Init
        
        init(dampingRatio: CGFloat) {
            self.dampingRatio = dampingRatio
        }

        // MARK: - Animation

        func animate(from startHeight: CGFloat, to targetHeight: CGFloat, duration: TimeInterval) {
            stop(finishAtEnd: false)

            let timing = UISpringTimingParameters(
                dampingRatio: dampingRatio,
                initialVelocity: .zero
            )
            
            let animator = UIViewPropertyAnimator(duration: duration, timingParameters: timing)
            
            animator.addAnimations {
                self.onUpdate?(targetHeight)
            }
            
            animator.addCompletion { [weak self] position in
                guard let self else { return }
                if position == .end {
                    self.onCompletion?()
                }
                self.animator = nil
            }
            
            self.animator = animator
            animator.startAnimation()
        }

        func stop(finishAtEnd: Bool) {
            guard let animator else { return }
            if finishAtEnd {
                animator.stopAnimation(false)
                animator.finishAnimation(at: .end)
            } else {
                animator.stopAnimation(true)
            }
            self.animator = nil
        }
    }
}
