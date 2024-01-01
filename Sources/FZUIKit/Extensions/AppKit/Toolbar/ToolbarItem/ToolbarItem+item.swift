//
//  ToolbarItem+item.swift
//
//
//  Created by Florian Zand on 09.04.23.
//

#if os(macOS)
import AppKit

public extension ToolbarItem {
    /**
     A toolbar item.
     
     It can be used as an item of a ``Toolbar``.
     */
    class Item: ToolbarItem {
        /// The title of the item.
        @discardableResult
        public func title(_ title: String) -> Self {
            set(\.item.title, to: title)
        }

        /// The image of the item, or `nil` if none.
        @discardableResult
        public func image(_ image: NSImage?) -> Self {
            set(\.item.image, to: image)
        }

        /// A Boolean value that indicates whether the toolbar item has a bordered style.
        @discardableResult
        public func bordered(_ isBordered: Bool) -> Self {
            set(\.item.isBordered, to: isBordered)
        }

        @available(macOS 11.0, *)
        @discardableResult
        /// A Boolean value that indicates whether the toolbar item behaves as a navigation item in the toolbar.
        public func isNavigational(_ isNavigational: Bool) -> Self {
            item.isNavigational = isNavigational
            return self
        }

        /// The action block of the item.
        @discardableResult
        public func onAction(_ action: ToolbarItem.ActionBlock?) -> Self {
            item.actionBlock = action
            return self
        }

        /// The action block of the item.
        @discardableResult
        public func onAction(_ handler: @escaping () -> Void) -> Self {
            item.actionBlock = { _ in
                handler()
            }
            return self
        }
    }
}
#endif
