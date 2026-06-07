//
//  PanelConstants.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/05/17.
//  
//

import UIKit

/// Shared layout and animation constants for the panel implementation.
enum PanelConstants {
    static let dragIndicatorHitArea = UIEdgeInsets(top: -20, left: -40, bottom: -20, right: -40)
    static let cornerRadius: CGFloat = 24
    static let indicatorAnimationDuration: TimeInterval = 0.25
    static let snapAnimationDuration: TimeInterval = 0.5
    static let snapDampingRatio: CGFloat = 0.75
    static let dismissVelocityThreshold: CGFloat = 700.0
    static let rubberBandFactor: CGFloat = 0.15
    static let minHeightResistance: CGFloat = 0.4
    static let maxNormalizedVelocity: CGFloat = 8
    static let dragIndicatorTopPadding: CGFloat = 8
    static let dismissVelocityHeightRatio: CGFloat = 1.1
    static let forceDismissHeightRatio: CGFloat = 0.5
}
