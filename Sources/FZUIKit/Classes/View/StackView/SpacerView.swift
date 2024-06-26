//
//  SpacerView.swift
//
//
//  Created by Florian Zand on 18.04.24.
//

#if os(macOS) || os(iOS) || os(tvOS)
#if os(macOS)
    import AppKit
#elseif os(iOS) || os(tvOS)
    import UIKit
#endif

/// A flexible spacer view for ``StackView`` that expands along the major axis of it's containing stack view.
open class SpacerView: NSUIView {
    /// The length of the spacer.
    public let length: CGFloat?
    
    /// Creates a flexible spacer.
    public init() {
        self.length = nil
        super.init(frame: .zero)
    }
    
    /// Creates a spacer with the specified length.
    public init(_ length: CGFloat) {
        self.length = length
        super.init(frame: .zero)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    #if os(macOS)
    open override var fittingSize: NSSize {
        if let length = length {
            return CGSize(length, length)
        }
        return CGSize(-1, -1)
    }
    
    open override var firstBaselineOffsetFromTop: CGFloat {
        bounds.height-0.5
    }
    #endif
}
#endif
