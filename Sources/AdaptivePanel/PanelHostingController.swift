//
//  PanelHostingController.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/05/17.
//  
//

import SwiftUI

/// Hosts panel content and forwards SwiftUI preference changes to the presentation controller.
@MainActor
class PanelHostingController<Content: View>: UIHostingController<PanelHostingController<Content>.BridgeView> {
    struct BridgeView: View {
        /// Stores a weak controller reference for the value-typed `BridgeView`.
        final class OwnerBox {
            weak var controller: PanelHostingController?
        }
        let content: () -> Content
        let ownerBox: OwnerBox

        var body: some View {
            content()
                .ignoresSafeArea(edges: [.horizontal, .bottom])
                .ignoresSafeArea(.keyboard)
                .background(.clear)
                .onPreferenceChange(PanelBackgroundStyleKey.self) { value in
                    ownerBox.controller?.applyPresenter{ $0.updateBackgroundStyle(value.style) }
                }
                .onPreferenceChange(PanelLandscapeKey.self) { value in
                    ownerBox.controller?.applyPresenter { $0.landscapeConfiguration = value }
                }
                .onPreferenceChange(PanelDetentKey.self) { value in
                    ownerBox.controller?.applyPresenter { $0.panelDetents = value }
                }
                .onPreferenceChange(PanelInteractionKey.self) { value in
                    ownerBox.controller?.applyPresenter { $0.interactionMode = value }
                }
                .onPreferenceChange(PanelDragIndicatorVisibleKey.self) { value in
                    ownerBox.controller?.applyPresenter  { $0.dragIndicatorVisibility = value }
                }
                .onPreferenceChange(PanelInteractiveDismissDisabledKey.self) { value in ownerBox.controller?.applyPresenter { $0.isInteractiveDismissDisabled = value }
                }
                .onPreferenceChange(PanelCornerRadiusKey.self) { value in
                    ownerBox.controller?.applyPresenter { $0.panelCornerRadius = value }
                }
                .onPreferenceChange(PanelBackgroundInteractionKey.self) { value in
                    ownerBox.controller?.applyPresenter { $0.backgroundInteraction = value }
                }
                .onPreferenceChange(PanelDetentSelectionKey.self) { sel in
                    guard let sel else { return }
                    ownerBox.controller?.applyPresenter {
                        $0.onDetentChange = { sel.binding.wrappedValue = $0 }
                        $0.selectedDetent = sel.detent
                    }
                }
        }
    }

    init(@ViewBuilder content: @escaping () -> Content) {
        let ownerBox = BridgeView.OwnerBox()
        super.init(rootView: BridgeView(content: content, ownerBox: ownerBox))
        ownerBox.controller = applyTarget()
        self.sizingOptions = []
        self.view.insetsLayoutMarginsFromSafeArea = false
        self.view.backgroundColor = .clear
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Always restore the scroll view gesture state, even when dismissed mid-drag.
        (presentationController as? PanelPresentationController)?.restoreScrollViews()
    }
    
    func applyTarget() -> PanelHostingController<Content> {
        return self
    }


    internal func update(@ViewBuilder content: @escaping () -> Content) {
        self.rootView = BridgeView(content: content, ownerBox: self.rootView.ownerBox)
    }

    internal func applyPresenter(_ apply: (PanelPreferenceReceiver) -> Void) {
        guard let receiver = presentationController as? PanelPreferenceReceiver else { return }
        apply(receiver)
    }
}
