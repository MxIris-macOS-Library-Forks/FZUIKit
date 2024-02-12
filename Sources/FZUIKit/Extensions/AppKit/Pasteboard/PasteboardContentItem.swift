//
//  PasteboardContentItem.swift
//
//
//  Created by Florian Zand on 11.02.24.
//

#if os(macOS)
import AppKit

/// A type that can be used as pasteboard content.
public protocol PasteboardContentItem: Codable, PasteboardContent {
    /// The pasteboard type of the object. The default value is `codable`.
    static var pasteboardType: NSPasteboard.PasteboardType { get }
    
    /// Creates a pasteboard item for the object.
    var pasteboardItem: NSPasteboardItem { get }
    
    /// Creates the object from the specified pasteboard item.
    init?(pasteboardItem: NSPasteboardItem)
}

extension NSPasteboard.PasteboardType {
    /// Codable type
    public static let codable = NSPasteboard.PasteboardType(rawValue: "codable")
}

extension PasteboardContentItem {
    public static var pasteboardType: NSPasteboard.PasteboardType {
        return .codable
    }
    
    public var pasteboardWriting: NSPasteboardWriting {
        pasteboardItem
    }
    public var pasteboardItem: NSPasteboardItem {
        NSPasteboardItem(self, type: Self.pasteboardType)!
    }
    
    public init?(pasteboardItem: NSPasteboardItem) {
        guard let content = pasteboardItem.content(Self.self, for: Self.pasteboardType) else {
            return nil
        }
        self = content
    }
}
#endif
