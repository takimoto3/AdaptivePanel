//
//  PanelPresenterTests.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/05/18.
//  
//

import Testing
import UIKit
import SwiftUI
@testable import AdaptivePanel

@Suite("PanelPresenter.Coordinator")
@MainActor
struct PanelPresenterCoordinatorTests {
    
    private func makeCoordinator(isPresented: Bool) -> (
        coordinator: PanelCoordinator<AnyView>,
        binding: Binding<Bool>
    ) {
        var value = isPresented
        let binding = Binding(get: { value }, set: { value = $0 })
        let coordinator = PanelCoordinator<AnyView>()
        coordinator.onDismiss = {
            guard value else { return }
            value = false
        }
        return (coordinator, binding)
    }

    // MARK: - onDismiss

    @Test func onDismiss_isPresentedTrue_setsBindingToFalse() {
        let (coordinator, binding) = makeCoordinator(isPresented: true)
        coordinator.onDismiss?()
        #expect(binding.wrappedValue == false)
    }

    @Test func onDismiss_isPresentedFalse_doesNothing() {
        let (coordinator, binding) = makeCoordinator(isPresented: false)
        coordinator.onDismiss?()
        #expect(binding.wrappedValue == false)
    }

    @Test func onDismiss_callsOnDismissCallback() {
        var value = true
        var onDismissCalled = false
        let coordinator = PanelCoordinator<AnyView>()
        coordinator.onDismiss = {
            guard value else { return }
            value = false
            onDismissCalled = true
        }

        coordinator.onDismiss?()
        #expect(onDismissCalled == true)
    }

    @Test func onDismiss_isPresentedFalse_doesNotCallOnDismissCallback() {
        var value = false
        var onDismissCalled = false
        let coordinator = PanelCoordinator<AnyView>()
        coordinator.onDismiss = {
            guard value else { return }
            value = false
            onDismissCalled = true
        }

        coordinator.onDismiss?()
        #expect(onDismissCalled == false)
    }
}
