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
        var state = DetentState(detents: [.large, .medium])
        let container = makeContainer()
        state.resolve(in: container)
        // sorted: [medium, large] -> current = medium
        #expect(state.current == .medium)
    }

    @Test func init_emptyDetents_currentFallsBackToLarge() {
        let state = DetentState(detents: [])
        #expect(state.current == .large)
    }

    @Test func init_singleDetent_currentIsThatDetent() {
        var state = DetentState(detents: [.medium])
        let container = makeContainer()
        state.resolve(in: container)
        #expect(state.current == .medium)
    }


    // MARK: - detents.didSet

    @Test func detents_didSet_currentContained_preservesCurrent() {
        var state = DetentState(detents: [.medium, .large])
        let container = makeContainer()
        state.resolve(in: container)
        // Force _current to .large via move
        _ = state.move(to: .large)
        #expect(state.current == .large)

        // Update detents still containing .large
        state.detents = [.medium, .large]
        #expect(state.current == .large)
    }

    @Test func detents_didSet_currentNotContained_resetsToSortedFirst() {
        var state = DetentState(detents: [.medium, .large])
        let container = makeContainer()
        state.resolve(in: container)
        _ = state.move(to: .large)
        #expect(state.current == .large)

        // Remove .large -> _current = nil -> sorted.first = .medium
        state.detents = [.medium]
        state.resolve(in: container)
        #expect(state.current == .medium)
    }

    @Test func detents_didSet_invalidatesCache() {
        var state = DetentState(detents: [.medium, .large])
        let container = makeContainer()
        state.resolve(in: container)
        let height1 = state.currentHeight

        state.detents = [.large]
        state.resolve(in: container)
        let height2 = state.currentHeight

        #expect(height1 != height2)
    }

    // MARK: - currentHeight

    @Test func currentHeight_nilCurrent_returnsFirst() {
        var state = DetentState(detents: [.medium, .large])
        let container = makeContainer()
        state.resolve(in: container)
        // _current is nil -> returns heights.first = medium height
        let expected = PanelDetent.medium.calculate(in: container)
        #expect(state.currentHeight == expected)
    }

    @Test func currentHeight_afterMove_returnsCorrectHeight() {
        var state = DetentState(detents: [.medium, .large])
        let container = makeContainer()
        state.resolve(in: container)
        _ = state.move(to: .large)
        let expected = PanelDetent.large.calculate(in: container)
        #expect(state.currentHeight == expected)
    }

    // MARK: - minHeight / maxHeight

    @Test func minHeight_returnsMediumHeight() {
        var state = DetentState(detents: [.medium, .large])
        let container = makeContainer()
        state.resolve(in: container)
        let expected = PanelDetent.medium.calculate(in: container)
        #expect(state.minHeight == expected)
    }

    @Test func maxHeight_returnsLargeHeight() {
        var state = DetentState(detents: [.medium, .large])
        let container = makeContainer()
        state.resolve(in: container)
        let expected = PanelDetent.large.calculate(in: container)
        #expect(state.maxHeight == expected)
    }

    // MARK: - next

    @Test func next_mediumToLarge() {
        var state = DetentState(detents: [.medium, .large])
        let container = makeContainer()
        state.resolve(in: container)
        // current = medium -> next = large
        let height = state.next()
        #expect(state.current == .large)
        #expect(height == PanelDetent.large.calculate(in: container))
    }

    @Test func next_largeCyclesToMedium() {
        var state = DetentState(detents: [.medium, .large])
        let container = makeContainer()
        state.resolve(in: container)
        _ = state.move(to: .large)
        let height = state.next()
        #expect(state.current == .medium)
        #expect(height == PanelDetent.medium.calculate(in: container))
    }

    // MARK: - nearest

    @Test func nearest_closerToMedium_selectsMedium() {
        var state = DetentState(detents: [.medium, .large])
        let container = makeContainer()
        state.resolve(in: container)
        let mediumHeight = PanelDetent.medium.calculate(in: container)
        let projected = mediumHeight + 10
        _ = state.nearest(to: projected)
        #expect(state.current == .medium)
    }

    @Test func nearest_closerToLarge_selectsLarge() {
        var state = DetentState(detents: [.medium, .large])
        let container = makeContainer()
        state.resolve(in: container)
        let largeHeight = PanelDetent.large.calculate(in: container)
        let projected = largeHeight - 10
        _ = state.nearest(to: projected)
        #expect(state.current == .large)
    }

    // MARK: - move

    @Test func move_sameCurrent_returnsNil() {
        var state = DetentState(detents: [.medium, .large])
        let container = makeContainer()
        state.resolve(in: container)
        // current = medium (sorted.first)
        let result = state.move(to: .medium)
        #expect(result == nil)
    }

    @Test func move_differentDetent_returnsHeightAndUpdatesCurrent() {
        var state = DetentState(detents: [.medium, .large])
        let container = makeContainer()
        state.resolve(in: container)
        let result = state.move(to: .large)
        #expect(result != nil)
        #expect(state.current == .large)
        #expect(result == PanelDetent.large.calculate(in: container))
    }

    @Test func move_detentNotInList_returnsNil() {
        var state = DetentState(detents: [.medium])
        let container = makeContainer()
        state.resolve(in: container)
        let result = state.move(to: .large)
        #expect(result == nil)
        #expect(state.current == .medium)
    }

    // MARK: - cache

    @Test func cache_sameContainerAndDetents_doesNotRecalculate() {
        var state = DetentState(detents: [.medium, .large])
        let container = makeContainer()
        state.resolve(in: container)
        let h1 = state.currentHeight
        let h2 = state.currentHeight
        #expect(h1 == h2)
    }

    @Test func cache_differentContainerSize_recalculates() {
        var state = DetentState(detents: [.medium, .large])
        let container1 = makeContainer(width: 390, height: 844)
        let container2 = makeContainer(width: 390, height: 932)
        state.resolve(in: container1)
        let h1 = state.currentHeight
        state.resolve(in: container2)
        let h2 = state.currentHeight
        #expect(h1 != h2)
    }
}
