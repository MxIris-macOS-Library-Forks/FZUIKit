//
//  NSToolbarItem+.swift
//
//
//  Created by Florian Zand on 15.09.22.
//

#if os(macOS)

import AppKit
import FZSwiftUtils

extension NSToolbarItem {
    /// Creates a toolbar item with the specified identifier.
    ///
    /// - Parameter itemIdentifier: The identifier for the toolbar item. You use this value to identify the item within your app, so you don’t need to localize it. For example, your toolbar delegate uses this value to identify the specific toolbar item.
    ///
    /// - Returns: A new toolbar item.
    @objc public convenience init(_ itemIdentifier: NSToolbarItem.Identifier) {
        self.init(itemIdentifier: itemIdentifier)
    }
}

extension NSToolbarItem.Identifier: @retroactive ExpressibleByExtendedGraphemeClusterLiteral {}
extension NSToolbarItem.Identifier: @retroactive ExpressibleByUnicodeScalarLiteral {}
extension NSToolbarItem.Identifier: @retroactive ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }

    /// A random toolbar identifier.
    static var random: Self { Self(rawValue: UUID().uuidString) }
}

#endif
