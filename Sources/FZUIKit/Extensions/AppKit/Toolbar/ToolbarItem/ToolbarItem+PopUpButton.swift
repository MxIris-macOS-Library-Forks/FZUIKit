//
//  ToolbarItem+PopUpButton.swift
//
//
//  Created by Florian Zand on 09.04.23.
//

#if os(macOS)
    import AppKit

    public extension ToolbarItem {
        /**
         A toolbar item that contains a popup button.

         The item can be used with ``Toolbar``.
         */
        class PopUpButton: ToolbarItem {
            /// The popup button.
            public let button: NSPopUpButton

            /// Sets the handler that gets called when the user clicks the pop up button.
            @discardableResult
            public func onAction(_ action: ((_ item: ToolbarItem.PopUpButton)->())?) -> Self {
                if let action = action {
                    button.actionBlock = { [weak self] _ in
                        guard let self = self else { return }
                        action(self)
                    }
                } else {
                    button.actionBlock = nil
                }
                return self
            }

            /// Sets the menu of the popup button.
            @discardableResult
            public func menu(_ menu: NSMenu) -> Self {
                button.menu = menu
                return self
            }

            /// The menu of the popup button.
            public var menu: NSMenu? {
                get { button.menu }
                set { button.menu = newValue }
            }

            /// Sets the menu items of the popup button.
            @discardableResult
            public func items(@MenuBuilder _ items: () -> [NSMenuItem]) -> Self {
                button.menu = NSMenu(title: "", items: items())
                return self
            }

            /// Sets the string that is displayed on the popup button when the user isn’t pressing the mouse button.
            @discardableResult
            public func title(_ title: String) -> Self {
                button.setTitle(title)
                return self
            }

            /// Sets the Boolean value indicating whether the button displays a pull-down or pop-up menu.
            @discardableResult
            public func pullsDown(pullsDown: Bool) -> Self {
                button.pullsDown = pullsDown
                return self
            }

            /// A Boolean value indicating whether the button displays a pull-down or pop-up menu.
            public var pullsDown: Bool {
                get { button.pullsDown }
                set { button.pullsDown = newValue }
            }

            /// The index of the selected item, or `nil` if no item is selected.
            public var indexOfSelectedItem: Int? {
                get { (button.indexOfSelectedItem != -1) ? button.indexOfSelectedItem : nil }
                set { button.selectItem(at: newValue ?? -1)
                }
            }

            /// The selected menu item, or `nil` if no tem is selected.
            public var selectedItem: NSMenuItem? {
                get { button.selectedItem }
                set { button.select(newValue) }
            }

            /// Selects the item of the popup button at the specified index.
            @discardableResult
            public func selectItem(at index: Int) -> Self {
                button.selectItem(at: index)
                return self
            }

            /// Selects the item of the popup button with the specified title.
            @discardableResult
            public func selectItem(withTitle title: String) -> Self {
                button.selectItem(withTitle: title)
                return self
            }

            /// Selects the item of the popup button with the specified tag.
            @discardableResult
            public func selectItem(withTag tag: Int) -> Self {
                button.selectItem(withTag: tag)
                return self
            }

            /// Selects the specified menu item of the popup button.
            @discardableResult
            public func select(_ item: NSMenuItem) -> Self {
                button.select(item)
                return self
            }

            /**
             Creates a popup button toolbar item.

             - Parameters:
                - identifier: An optional identifier of the item.
                - items: The menu items of the popup button.
             */
            public convenience init(_ identifier: NSToolbarItem.Identifier? = nil, @MenuBuilder _ items: () -> [NSMenuItem]) {
                let button = NSPopUpButton(frame: .zero, pullsDown: true)
                button.bezelStyle = .texturedRounded
                button.imagePosition = .imageOnly
                button.imageScaling = .scaleProportionallyDown
                button.arrowPosition = .arrowAtBottom
                button.menu = NSMenu(title: "", items: items())
                self.init(identifier, popUpButton: button)
            }

            /**
             Creates a popup button toolbar item.

             - Parameters:
                - identifier: An optional identifier of the item.
                - popUpButton: The popup button of the item.
             */
            public init(_ identifier: NSToolbarItem.Identifier? = nil, popUpButton: NSPopUpButton) {
                popUpButton.translatesAutoresizingMaskIntoConstraints = true
                button = popUpButton
                super.init(identifier)
                item.view = button
            }
        }
    }

#endif
