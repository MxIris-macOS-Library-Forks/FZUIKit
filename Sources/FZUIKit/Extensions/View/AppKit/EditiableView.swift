//
//  EditiableView.swift
//
//
//  Created by Florian Zand on 03.12.24.
//

#if os(macOS)

import AppKit

/// A view with content that can be selected or editied.
public protocol EditiableView: NSView {
    /// A Boolean value that indicates whether the user can select the content.
    var isSelectable: Bool { get set }
    /// A Boolean value that indicates whether the user can edit the content.
    var isEditable: Bool { get set }
    /// A Boolean value that indicates whether the user is currently selecting the content.
    var isSelecting: Bool { get }
    /// A Boolean value that indicates whether the user is currently editing the content.
    var isEditing: Bool { get }
}

extension NSTextField: EditiableView { 
    /// A Boolean value that indicates whether the user is currently editing the text.
    public var isEditing: Bool {
        isEditable && isFirstResponder
    }
    
    /// A Boolean value that indicates whether the user is currently selecting the text.
    public var isSelecting: Bool {
        isSelectable && isFirstResponder
    }
}

extension NSTextView: EditiableView {
    /// A Boolean value that indicates whether the user is currently editing the text.
    public var isEditing: Bool {
        isEditable && isFirstResponder
    }
    
    /// A Boolean value that indicates whether the user is currently selecting the text.
    public var isSelecting: Bool {
        isSelectable && isFirstResponder
    }
}

#endif
