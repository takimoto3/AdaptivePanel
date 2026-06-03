//
//  View+panelBackgroundTests.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/05/17.
//  
//

import Testing
import SwiftUI
@testable import AdaptivePanel

@Suite("BackgroundStyle")
struct BackgroundStyleTests {

    @Test func equality_sameId() {
        let id = UUID()
        let style1 = BackgroundStyle(Color.red, id: id)
        let style2 = BackgroundStyle(Color.red, id: id)
        #expect(style1 == style2)
    }

    @Test func equality_differentId_sameStyle() {
        let style1 = BackgroundStyle(Color.red)
        let style2 = BackgroundStyle(Color.red)
        #expect(style1 != style2)
    }

    @Test func equality_differentStyle_sameId() {
        let id = UUID()
        let style1 = BackgroundStyle(Color.red, id: id)
        let style2 = BackgroundStyle(Color.blue, id: id)
        #expect(style1 == style2)
    }

    @Test func defaultValue_isSystemBackground() {
        let defaultStyle = PanelBackgroundStyleKey.defaultValue
        #expect(defaultStyle.id == PanelBackgroundStyleKey.defaultValue.id)
    }
}
