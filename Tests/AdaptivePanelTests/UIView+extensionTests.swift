//
//  UIView+extensionTests.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/05/17.
//  
//

import Testing
import UIKit
@testable import AdaptivePanel

@Suite("UIScrollView isVerticalScrollable")
@MainActor
struct UIScrollViewTests {
    
    @Test func verticalContent() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        scrollView.contentSize = CGSize(width: 100, height: 200)
        #expect(scrollView.isVerticalScrollable)
    }
    
    @Test func alwaysBounceVertical() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        scrollView.contentSize = CGSize(width: 100, height: 50)
        scrollView.alwaysBounceVertical = true
        #expect(scrollView.isVerticalScrollable)
    }
    
    @Test func horizontalOnly() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        scrollView.contentSize = CGSize(width: 200, height: 100)
        #expect(!scrollView.isVerticalScrollable)
    }
    
    @Test func noScroll() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        scrollView.contentSize = CGSize(width: 100, height: 100)
        #expect(!scrollView.isVerticalScrollable)
    }
}

@Suite("UIView findScrollView")
@MainActor
struct UIViewFindScrollViewTests {
    
    @Test func findsVerticalScrollView() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        scrollView.contentSize = CGSize(width: 200, height: 400)
        let child = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        root.addSubview(scrollView)
        scrollView.addSubview(child)
        
        #expect(root.findScrollView(point: CGPoint(x: 100, y: 100)) == scrollView)
    }
    
    @Test func ignoresHorizontalScrollView() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        scrollView.contentSize = CGSize(width: 400, height: 200)
        root.addSubview(scrollView)
        
        #expect(root.findScrollView(point: CGPoint(x: 100, y: 100)) == nil)
    }
    
    @Test func returnsNilWhenNoScrollView() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let child = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        root.addSubview(child)
        
        #expect(root.findScrollView(point: CGPoint(x: 100, y: 100)) == nil)
    }
    
    @Test func outsidePoint() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        scrollView.contentSize = CGSize(width: 200, height: 400)
        root.addSubview(scrollView)
        
        #expect(root.findScrollView(point: CGPoint(x: 300, y: 300)) == nil)
    }
}
