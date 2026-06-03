//
//  DetentStateTests.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/05/29.
//  
//

import Testing
import UIKit
@testable import AdaptivePanel

@Suite("DetentState")
@MainActor
struct DetentStateTests {

    private typealias DetentState = PanelPresentationController.DetentState

    private func makeContainer(width: CGFloat = 390, height: CGFloat = 844) -> UIView {
        UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
    }

    // MARK: - init

    @Test func init_current_returnsSortedFirst() {
        let state = DetentState(detents: [.large, .medium])
        // sorted: [medium, large] -> current = medium
        #expect(state.current == .medium)
    }

    @Test func init_emptyDetents_currentFallsBackToLarge() {
        let state = DetentState(detents: [])
        #expect(state.current == .large)
    }

    @Test func init_singleDetent_currentIsThatDetent() {
        let state = DetentState(detents: [.medium])
        #expect(state.current == .medium)
    }

    // MARK: - detents.didSet

    @Test func detents_didSet_currentContained_preservesCurrent() {
        var state = DetentState(detents: [.medium, .large])
        let container = makeContainer()
        // Force _current to .large via move
        _ = state.move(to: .large, in: container)
        #expect(state.current == .large)

        // Update detents still containing .large
        state.detents = [.medium, .large]
        #expect(state.current == .large)
    }

    @Test func detents_didSet_currentNotContained_resetsToSortedFirst() {
        var state = DetentState(detents: [.medium, .large])
        let container = makeContainer()
        _ = state.move(to: .large, in: container)
        #expect(state.current == .large)

        // Remove .large -> _current = nil -> sorted.first = .medium
        state.detents = [.medium]
        #expect(state.current == .medium)
    }

    @Test func detents_didSet_invalidatesCache() {
        var state = DetentState(detents: [.medium, .large])
        let container = makeContainer()
        let height1 = state.currentHeight(in: container)

        state.detents = [.large]
        let height2 = state.currentHeight(in: container)

        #expect(height1 != height2)
    }

    // MARK: - currentHeight

    @Test func currentHeight_nilCurrent_returnsFirst() {
        var state = DetentState(detents: [.medium, .large])
        let container = makeContainer()
        // _current is nil -> returns heights.first = medium height
        let expected = PanelDetent.medium.calculate(in: container)
        #expect(state.currentHeight(in: container) == expected)
    }

    @Test func currentHeight_afterMove_returnsCorrectHeight() {
        var state = DetentState(detents: [.medium, .large])
        let container = makeContainer()
        _ = state.move(to: .large, in: container)
        let expected = PanelDetent.large.calculate(in: container)
        #expect(state.currentHeight(in: container) == expected)
    }

    // MARK: - minHeight / maxHeight

    @Test func minHeight_returnsMediumHeight() {
        var state = DetentState(detents: [.medium, .large])
        let container = makeContainer()
        let expected = PanelDetent.medium.calculate(in: container)
        #expect(state.minHeight(in: container) == expected)
    }

    @Test func maxHeight_returnsLargeHeight() {
        var state = DetentState(detents: [.medium, .large])
        let container = makeContainer()
        let expected = PanelDetent.large.calculate(in: container)
        #expect(state.maxHeight(in: container) == expected)
    }

    // MARK: - next

    @Test func next_mediumToLarge() {
        var state = DetentState(detents: [.medium, .large])
        let container = makeContainer()
        // current = medium -> next = large
        let height = state.next(in: container)
        #expect(state.current == .large)
        #expect(height == PanelDetent.large.calculate(in: container))
    }

    @Test func next_largeCyclesToMedium() {
        var state = DetentState(detents: [.medium, .large])
        let container = makeContainer()
        _ = state.move(to: .large, in: container)
        let height = state.next(in: container)
        #expect(state.current == .medium)
        #expect(height == PanelDetent.medium.calculate(in: container))
    }

    // MARK: - nearest

    @Test func nearest_closerToMedium_selectsMedium() {
        var state = DetentState(detents: [.medium, .large])
        let container = makeContainer()
        let mediumHeight = PanelDetent.medium.calculate(in: container)
        let projected = mediumHeight + 10
        _ = state.nearest(to: projected, in: container)
        #expect(state.current == .medium)
    }

    @Test func nearest_closerToLarge_selectsLarge() {
        var state = DetentState(detents: [.medium, .large])
        let container = makeContainer()
        let largeHeight = PanelDetent.large.calculate(in: container)
        let projected = largeHeight - 10
        _ = state.nearest(to: projected, in: container)
        #expect(state.current == .large)
    }

    // MARK: - move

    @Test func move_sameCurrent_returnsNil() {
        var state = DetentState(detents: [.medium, .large])
        let container = makeContainer()
        // current = medium (sorted.first)
        let result = state.move(to: .medium, in: container)
        #expect(result == nil)
    }

    @Test func move_differentDetent_returnsHeightAndUpdatesCurrent() {
        var state = DetentState(detents: [.medium, .large])
        let container = makeContainer()
        let result = state.move(to: .large, in: container)
        #expect(result != nil)
        #expect(state.current == .large)
        #expect(result == PanelDetent.large.calculate(in: container))
    }

    @Test func move_detentNotInList_returnsNil() {
        var state = DetentState(detents: [.medium])
        let container = makeContainer()
        let result = state.move(to: .large, in: container)
        #expect(result == nil)
        #expect(state.current == .medium)
    }

    // MARK: - cache

    @Test func cache_sameContainerAndDetents_doesNotRecalculate() {
        var state = DetentState(detents: [.medium, .large])
        let container = makeContainer()
        let h1 = state.currentHeight(in: container)
        let h2 = state.currentHeight(in: container)
        #expect(h1 == h2)
    }

    @Test func cache_differentContainerSize_recalculates() {
        var state = DetentState(detents: [.medium, .large])
        let container1 = makeContainer(width: 390, height: 844)
        let container2 = makeContainer(width: 390, height: 932)
        let h1 = state.currentHeight(in: container1)
        let h2 = state.currentHeight(in: container2)
        #expect(h1 != h2)
    }
}
