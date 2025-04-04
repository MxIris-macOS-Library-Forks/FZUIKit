//
//  ToolbarItem.swift
//
//
//  Created by Florian Zand on 09.04.23.
//

#if os(macOS)
    import AppKit

    /// A toolbar item that can be used with ``Toolbar``.
    open class ToolbarItem: NSObject {
        /// The identifier of the toolbar item.
        public let identifier: NSToolbarItem.Identifier

        /// A Boolean value that indicates whether the item is available on the 'default' toolbar presented to the user.
        open var isDefault = true
        
        /// A Boolean value that indicates whether the item can be selected.
        open var isSelectable = false
        
        /// A Boolean value that indicates whether the item can't be removed or rearranged by the user.
        open var isImmovable = false
        
        /// A Boolean value that indicates whether the item displays in the center of the toolbar.
        @available(macOS 13.0, *)
        open var isCentered: Bool {
            get { _isCentered }
            set { _isCentered = newValue }
        }
        
        open func validate() {
            
        }
        
        var _isCentered = false {
            didSet {
                guard #available(macOS 13.0, *), oldValue != isCentered, let toolbar = toolbar else { return }
                if isCentered {
                    toolbar.centeredItems.insert(self)
                } else {
                    toolbar.centeredItems.remove(self)
                }
            }
        }
                
        var _label: String = "" {
            didSet {
                guard oldValue != _label else { return }
                item.label = _label
                if _label == "", let item = self as? ToolbarItem.Segmented, !item.groupItem.subitems.isEmpty {
                    item.updateSegments()
                }
            }
        }
        
        /// A Boolean value that indicates whether the item is selected.
        var isSelected: Bool {
            get { toolbar?.selectedItem == self }
            set {
                guard isSelectable, let toolbar = toolbar, newValue != isSelected else { return }
                if newValue {
                    toolbar.selectedItem = self
                } else if toolbar.selectedItem === self {
                    toolbar.selectedItem = nil
                }
            }
        }
      
        lazy var rootItem = ValidateToolbarItem(for: self)
        var item: NSToolbarItem {
            rootItem
        }
        
        public var itemA: NSToolbarItem {
            rootItem
        }

        init(_ identifier: NSToolbarItem.Identifier? = nil) {
            self.identifier = identifier ?? Toolbar.automaticIdentifier(for: "\(type(of: self))")
        }
    }

    extension ToolbarItem {
        /**
         A Boolean value that indicates whether the item is currently visible in the toolbar, and not in the overflow menu.

         The value of this property is true when the item is visible in the toolbar, and false when it isn’t in the toolbar or is present in the toolbar’s overflow menu. This property is key-value observing (KVO) compliant.
         */
        @available(macOS 12.0, *)
        @objc open var isVisible: Bool { item.isVisible }

        /// The toolbar that currently includes the item.
        public var toolbar: Toolbar? { item.toolbar?.delegate as? Toolbar }
        

        /// The label that appears for this item in the toolbar.
        public var label: String {
            get { _label }
            set { _label = newValue }
        }
        
        /// Sets the label that appears for this item in the toolbar.
        @discardableResult
        @objc open func label(_ label: String?) -> Self {
            _label = label ?? ""
            return self
        }
        
        /**
         The set of labels that the item might display.

         Use this property to specify all of the labels you might possibly use for the toolbar item. Specify all strings in the current locale. To ensure there’s space for the longest label, the item sizes itself using the strings you provide.
         */
        @available(macOS 13.0, *)
        public var possibleLabels: Set<String> {
            get { item.possibleLabels }
            set { item.possibleLabels = newValue }
        }

        /**
         Sets the set of labels that the item might display.

         Use this property to specify all of the labels you might possibly use for the toolbar item. Specify all strings in the current locale. To ensure there’s space for the longest label, the item sizes itself using the strings you provide.
         */
        @available(macOS 13.0, *)
        @discardableResult
        @objc open func possibleLabels(_ labels: Set<String>) -> Self {
            item.possibleLabels = labels
            return self
        }
        
        /**
         The label that appears when the toolbar item is in the customization palette.

         If you support toolbar customizations, you must provide palette labels for your items. In most cases, you can apply the same value to this property and the label property. However, you might use this property to offer a more descriptive string, or to provide a label string when the label property contains an empty string.
         */
        public var paletteLabel: String {
            get { item.paletteLabel }
            set { item.paletteLabel = newValue }
        }

        /**
         Sets the label that appears when the toolbar item is in the customization palette.

         If you support toolbar customizations, you must provide palette labels for your items. In most cases, you can apply the same value to this property and the label property. However, you might use this property to offer a more descriptive string, or to provide a label string when the label property contains an empty string.
         */
        @discardableResult
        @objc open func paletteLabel(_ paletteLabel: String?) -> Self {
            item.paletteLabel = paletteLabel ?? ""
            return self
        }
        
        /**
         An tag to identify the toolbar item.

         The toolbar doesn’t use this value. You can use it for your own custom purposes.
         */
        public var tag: Int {
            get { item.tag }
            set { item.tag = newValue }
        }

        /**
         Sets the tag to identify the toolbar item.

         The toolbar doesn’t use this value. You can use it for your own custom purposes.
         */
        @discardableResult
        @objc open func tag(_ tag: Int) -> Self {
            item.tag = tag
            return self
        }
        
        /// A Boolean value that indicates whether the item is enabled.
        public var isEnabled: Bool {
            get { item.isEnabled }
            set { item.isEnabled = newValue }
        }

        /// Sets the Boolean value that indicates whether the item is enabled.
        @discardableResult
        @objc open func isEnabled(_ isEnabled: Bool) -> Self {
            item.isEnabled = isEnabled
            return self
        }

        /// Sets the Boolean value that indicates whether the item can be selected.
        @discardableResult
        @objc open func isSelectable(_ isSelectable: Bool) -> Self {
            self.isSelectable = isSelectable
            return self
        }

        /// Sets the Boolean value that indicates whether the item is available on the 'default' toolbar presented to the user.
        @discardableResult
        @objc open func isDefault(_ isDefault: Bool) -> Self {
            self.isDefault = isDefault
            return self
        }

        /// Sets the Boolean value that indicates whether the item can't be removed or rearranged by the user.
        @discardableResult
        @objc open func isImmovable(_ isImmovable: Bool) -> Self {
            self.isImmovable = isImmovable
            return self
        }
        
        /// Sets the Boolean value that indicates whether the item displays in the center of the toolbar.
        @available(macOS 13.0, *)
        @discardableResult
        @objc open func isCentered(_ isCentered: Bool) -> Self {
            self.isCentered = isCentered
            return self
        }
        
        /// The tooltip to display when someone hovers over the item in the toolbar.
        public var toolTip: String? {
            get { item.toolTip }
            set { item.toolTip = newValue }
        }

        /// Sets the tooltip to display when someone hovers over the item in the toolbar.
        @discardableResult
        @objc open func toolTip(_ toolTip: String?) -> Self {
            item.toolTip = toolTip
            return self
        }
        
        /**
         The display priority associated with the toolbar item.

         The default value of this property is `standard`. Assign a higher priority to give preference to the toolbar item when space is limited.

         When a toolbar doesn’t have enough space to fit all of its items, it pushes lower-priority items to the overflow menu first. When two or more items have the same priority, the toolbar removes them one at a time starting from the trailing edge.
         */
        public var visibilityPriority: NSToolbarItem.VisibilityPriority {
            get { item.visibilityPriority }
            set { item.visibilityPriority = newValue }
        }

        /**
         Sets the display priority associated with the toolbar item.

         The default value of this property is standard. Assign a higher priority to give preference to the toolbar item when space is limited.

         When a toolbar doesn’t have enough space to fit all of its items, it pushes lower-priority items to the overflow menu first. When two or more items have the same priority, the toolbar removes them one at a time starting from the trailing edge.
         */
        @discardableResult
        @objc open func visibilityPriority(_ priority: NSToolbarItem.VisibilityPriority) -> Self {
            item.visibilityPriority = priority
            return self
        }
        
        /**
         The menu item to use when the toolbar item is in the overflow menu.

         The toolbar provides an initial default menu form representation that uses the toolbar item’s label as the menu item’s title. You can customize this menu item by changing the title or adding a submenu. When the toolbar is in text only mode, this menu item provides the text for the toolbar item. If the menu item in this property has a submenu and is visbile, clicking the toolbar item displays that submenu. If the toolbar item isn’t visible because it’s in the overflow menu, the menu item and submenu appear there.
         */
        public var menuFormRepresentation: NSMenuItem? {
            get { item.menuFormRepresentation }
            set { item.menuFormRepresentation = newValue }
        }

        /**
         Sets the menu item to use when the toolbar item is in the overflow menu.

         The toolbar provides an initial default menu form representation that uses the toolbar item’s label as the menu item’s title. You can customize this menu item by changing the title or adding a submenu. When the toolbar is in text only mode, this menu item provides the text for the toolbar item. If the menu item in this property has a submenu and is visbile, clicking the toolbar item displays that submenu. If the toolbar item isn’t visible because it’s in the overflow menu, the menu item and submenu appear there.
         */
        @discardableResult
        @objc open func menuFormRepresentation(_ menuItem: NSMenuItem?) -> Self {
            item.menuFormRepresentation = menuItem
            return self
        }
    }

public extension Sequence where Element == ToolbarItem {
    /// An array of identifier of the toolbar items.
    var ids: [NSToolbarItem.Identifier] {
        map(\.identifier)
    }
    
    /// The toolbar item with the specified identifier, or `nil` if the sequence doesn't contain an item with the identifier.
    subscript(id id: NSToolbarItem.Identifier) -> Element? {
        first(where: { $0.identifier == id })
    }

    /// The toolbar items with the specified identifiers.
    subscript<S: Sequence<NSToolbarItem.Identifier>>(ids ids: S) -> [Element] {
        filter { ids.contains($0.identifier) }
    }
}

class ValidateToolbarItem: NSToolbarItem {
    weak var item: ToolbarItem?
    
    init(for item: ToolbarItem) {
        super.init(itemIdentifier: item.identifier)
        self.item = item
    }
    
    override func validate() {
        super.validate()
        item?.validate()
    }
}
#endif
