//
//  PanelBackgroundHostingController.swift
//  AdaptivePanel
//  
//  Created by Masato Takimoto on 2026/06/11.
//  
//

import SwiftUI
import UIKit

final class PanelBackgroundHostingController: UIViewController {
    private var contentObject: ContentObject
    
    var backgroundColor: UIColor? {
        get { self.view.backgroundColor }
        set { self.view.backgroundColor = newValue }
    }

    init() {
        self.contentObject = ContentObject()
        super.init(nibName: nil, bundle: nil)
        self.view.backgroundColor = .systemBackground
    }
    
    @MainActor
    @preconcurrency
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = PanelBackgroundView(contentObject: contentObject)
    }
    

    func updateBackgroundStyle(_ style: AnyShapeStyle) {
        contentObject.content = AnyView(
            Rectangle()
                .fill(style)
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        )
    }
    
    func updateBackground<Content: View>(alignment: Alignment = .center, @ViewBuilder content:() -> Content) {
        contentObject.content = AnyView(
            ZStack(alignment: alignment) {
                content()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
        )
    }

    // MARK: - ContentObject

    @Observable
    final class ContentObject {
        var content: AnyView = AnyView(Color.clear)
    }

    
    // MARK: - PanelBackgroundView

    final class PanelBackgroundView: UIView {
        private let contentView: UIView
        
        override var safeAreaInsets: UIEdgeInsets {
            get { .zero }
        }
        
        init(contentObject: ContentObject) {
            contentView = UIHostingConfiguration {
                BackgroundContentView(contentObject: contentObject)
            }
            .margins(.all, 0)
            .makeContentView()
            super.init(frame: .zero)
            addSubview(contentView)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            contentView.frame = bounds
        }
    }
    
    // MARK: - BackgroundContentView

    struct BackgroundContentView: View {
        let contentObject: ContentObject

        var body: some View {
            contentObject.content
        }
    }

}
