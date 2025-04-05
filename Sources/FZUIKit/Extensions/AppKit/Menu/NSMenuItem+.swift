//
//  NSMenuItem+.swift
//
//
//  Created by Florian Zand on 09.04.23.
//

#if os(macOS)

import AppKit
import Foundation
import SwiftUI
import FZSwiftUtils

public extension NSMenuItem {
    /**
     Initializes and returns a menu item with the specified title.
     
     - Parameters:
        - title: The title of the menu item.
        - action: The action handler.
     
     - Returns: An instance of `NSMenuItem`.
     */
    convenience init(_ title: String, action: ActionBlock? = nil) {
        self.init(title: title, action: nil, keyEquivalent: "")
        actionBlock = action
    }
    
    /**
     Initializes and returns a menu item with the specified title.
     
     - Parameters:
        - title: The title of the menu item.
        - action: The action handler.
     
     - Returns: An instance of `NSMenuItem`.
     */
    convenience init(_ title: NSAttributedString, action: ActionBlock? = nil) {
        self.init("", action: action)
        attributedTitle = title
    }
    
    /**
     Initializes and returns a menu item with the specified localized title.
     
     - Parameters:
        - localizedTitle: The localized title of the menu item.
        - table: The table of the localization.
        - bundle: The bundle of the localization.
        - locale: The language.
        - comment: The comment of the localization.
        - action: The action handler.
     
     - Returns: An instance of `NSMenuItem`.
     */
    @available(macOS 12, *)
    convenience init(_ localizedTitle: String.LocalizationValue, table: String? = nil, bundle: Bundle? = nil, locale: Locale = .current, comment: StaticString? = nil, action: ActionBlock? = nil) {
        self.init(String(localized: localizedTitle, table: table, bundle: bundle, locale: locale, comment: comment), action: action)
    }
    
    /**
     Initializes and returns a menu item with the specified image.
     
     - Parameters:
        - title: The title of the menu item.
        - image: The image of the menu item.
        - action: The action handler.
     
     - Returns: An instance of `NSMenuItem`.
     */
    convenience init(_ title: String? = nil, image: NSImage, action: ActionBlock? = nil) {
        self.init(title ?? "", action: action)
        self.image = image
    }
    
    /**
     Initializes and returns a menu item with the view.
     
     - Parameters:
        - title: The title of the menu item.
        - view: The view of the menu item.
        - showsHighlight: A Boolean value that indicates whether menu item should highlight on interaction.
        - action: The action handler.
     
     - Returns: An instance of `NSMenuItem`.
     */
    convenience init(_ title: String? = nil, view: NSView, showsHighlight: Bool = true, action: ActionBlock? = nil) {
        self.init(title ?? "", action: action)
        self.view(view, showsHighlight: showsHighlight)
    }
    
    @available(macOS 13.0, *)
    convenience init(_ title: String? = nil, view: NSView, sizingOptions: NSHostingSizingOptions, showsHighlight: Bool = true, action: ActionBlock? = nil) {
        self.init(title ?? "", action: action)
        self.view(view, showsHighlight: showsHighlight)
    }
    
    /**
     Initializes and returns a menu item with the `SwiftUI` view.
     
     - Parameters:
        - title: The title of the menu item.
        - view: The view of the menu item.
        - showsHighlight: A Boolean value that indicates whether menu item should highlight on interaction.
        - action: The action handler.
     
     - Returns: An instance of `NSMenuItem`.
     */
    convenience init<V: View>(_ title: String? = nil, view: V, showsHighlight: Bool = true, action: ActionBlock? = nil) {
        self.init(title ?? "", action: action)
        self.view(view, showsHighlight: showsHighlight)
    }
    
    /**
     Initializes and returns a menu item with the `SwiftUI` view.
     
     - Parameters:
        - title: The title of the menu item.
        - view: The view of the menu item.
        - sizingOptions: The options for how the view creates and updates constraints based on the size of `view`.
        - showsHighlight: A Boolean value that indicates whether menu item should highlight on interaction.
        - action: The action handler.
     
     - Returns: An instance of `NSMenuItem`.
     */
    @available(macOS 13.0, *)
    convenience init<V: View>(_ title: String? = nil, view: V, sizingOptions: NSHostingSizingOptions, showsHighlight: Bool = true, action: ActionBlock? = nil) {
        self.init(title ?? "", action: action)
        self.view(view, sizingOptions: sizingOptions, showsHighlight: showsHighlight)
    }
    
    /**
     Initializes and returns a menu item with the `SwiftUI` view.
     
     - Parameters:
        - title: The title of the menu item.
        - view: The view of the menu item.
        - showsHighlight: A Boolean value that indicates whether menu item should highlight on interaction.
        - action: The action handler.
     
     - Returns: An instance of `NSMenuItem`.
     */
    convenience init<V: View>(_ title: String? = nil, @ViewBuilder view: () -> V, showsHighlight: Bool = true, action: ActionBlock? = nil) {
        self.init(title, view: view(), showsHighlight: showsHighlight, action: action)
    }
    
    /**
     Initializes and returns a menu item with the `SwiftUI` view.
     
     - Parameters:
        - title: The title of the menu item.
        - view: The view of the menu item.
        - sizingOptions: The options for how the view creates and updates constraints based on the size of `rootView`.
        - showsHighlight: A Boolean value that indicates whether menu item should highlight on interaction.
        - action: The action handler.
     
     - Returns: An instance of `NSMenuItem`.
     */
    @available(macOS 13.0, *)
    convenience init<V: View>(_ title: String? = nil, @ViewBuilder view: () -> V, sizingOptions: NSHostingSizingOptions, showsHighlight: Bool = true, action: ActionBlock? = nil) {
        self.init(title, view: view(), sizingOptions: sizingOptions, showsHighlight: showsHighlight, action: action)
    }
    
    /**
     Initializes and returns a menu item with the specified title and submenu containing the specified menu items.
     
     - Parameters:
        - title: The title for the menu item.
        - items: The items of the submenu.
     
     - Returns: An instance of `NSMenuItem`.
     */
    convenience init(_ title: String, @MenuBuilder items: () -> [NSMenuItem]) {
        self.init(title)
        submenu = NSMenu(title: "", items: items())
    }
    
    /// The font of the menu item.
    var font: NSFont? {
        get { value(forKey: "font") as? NSFont }
        set { setValue(newValue, forKey: "font") }
    }
    
    /// Sets the font of the menu item.
    @discardableResult
    func font(_ font: NSFont) -> Self {
        self.font = font
        return self
    }
    
    /// A Boolean value that indicates whether the menu item is enabled.
    @discardableResult
    func isEnabled(_ isEnabled: Bool) -> Self {
        self.isEnabled = isEnabled
        return self
    }
    
    /// A Boolean value that indicates whether the menu item is hidden.
    @discardableResult
    func isHidden(_ isHidden: Bool) -> Self {
        self.isHidden = isHidden
        return self
    }
    
    /// The menu item's tag.
    @discardableResult
    func tag(_ tag: Int) -> Self {
        self.tag = tag
        return self
    }
    
    /// The menu item's title.
    @discardableResult
    func title(_ title: String) -> Self {
        self.title = title
        return self
    }
    
    /// A custom string for a menu item.
    @discardableResult
    func attributedTitle(_ attributedTitle: NSAttributedString?) -> Self {
        self.attributedTitle = attributedTitle
        return self
    }
    
    /// The state of the menu item.
    @discardableResult
    func state(_ state: NSControl.StateValue) -> Self {
        self.state = state
        return self
    }
    
    /// The state of the menu item.
    @discardableResult
    func state(_ state: Bool) -> Self {
        self.state = state ? .on : .off
        return self
    }
    
    /// The menu item’s image.
    @discardableResult
    func image(_ image: NSImage?) -> Self {
        self.image = image
        return self
    }
    
    /// The image of the menu item that indicates an “on” state.
    @discardableResult
    func onStateImage(_ image: NSImage!) -> Self {
        onStateImage = image
        return self
    }
    
    /// The image of the menu item that indicates an “off” state.
    @discardableResult
    func offStateImage(_ image: NSImage?) -> Self {
        offStateImage = image
        return self
    }
    
    /// The image of the menu item that indicates a “mixed” state, that is, a state neither “on” nor “off.”
    @discardableResult
    func mixedStateImage(_ image: NSImage!) -> Self {
        mixedStateImage = image
        return self
    }
    
    /// The menu item’s badge.
    @available(macOS 14.0, *)
    @discardableResult
    func badge(_ badge: NSMenuItemBadge?) -> Self {
        self.badge = badge
        return self
    }
    
    /// The menu item’s unmodified key equivalent.
    @discardableResult
    func keyEquivalent(_ keyEquivalent: String) -> Self {
        self.keyEquivalent = keyEquivalent
        return self
    }
    
    /**
     Sets the menu item as an alternate to the previous menu item in the menu, that is displayed when the specified modifier flags are hold.

     If you set this value to `[]`, the item isn't an alternative and displayed all the time.
     */
    func alternateModifierFlags(_ modifierFlags: NSEvent.ModifierFlags) -> Self {
        isAlternate = modifierFlags != []
        keyEquivalentModifierMask = modifierFlags
        return self
    }
    
    /// The menu item’s keyboard equivalent modifiers.
    @discardableResult
    func keyEquivalentModifierMask(_ modifierMask: NSEvent.ModifierFlags) -> Self {
        keyEquivalentModifierMask = modifierMask
        return self
    }
    
    /// A Boolean value that marks the menu item as an alternate to the previous menu item.
    @discardableResult
    func isAlternate(_ isAlternate: Bool) -> Self {
        self.isAlternate = isAlternate
        return self
    }
    
    /// The menu item indentation level for the menu item.
    @discardableResult
    func indentationLevel(_ level: Int) -> Self {
        indentationLevel = level
        return self
    }
    
    /**
     Displays a content view instead of the title or attributed title.
     
     By default, a highlight background will be drawn behind the view whenever the menu item is highlighted. You can disable this and handle highlighting yourself by passing `showsHighlight: false`
     
     - Parameters:
        - view: The  view of the menu item.
        - showsHighlight: A Boolean value that indicates whether to draw the highlight when the item is highlighted.
     */
    @discardableResult
    func view(_ view: NSView?, showsHighlight: Bool = true) -> Self {
        if let view = view {
            if showsHighlight {
                self.view = NSMenuItemView(content: view)
            } else {
                self.view = view
            }
        } else {
            self.view = nil
        }
        return self
    }
    
    /**
     Displays a SwiftUI `View` instead of the title or attributed title.
     
     Any views inside a menu item can use the `menuItemIsHighlighted` environment value to alter their appearance when highlighted.
     
     By default, a highlight background will be drawn behind the view whenever `menuItemIsHighlighted` is `true`. You can disable this and handle highlighting yourself by passing `showsHighlight: false`
     
     - Parameters:
        - content: The  SwiftUI `View`.
        - showsHighlight: A Boolean value that indicates whether to draw the highlight when the item is highlighted.
     */
    @discardableResult
    func view<Content: View>(@ViewBuilder _ content: () -> Content, showsHighlight: Bool = true) -> Self {
        view(content(), showsHighlight: showsHighlight)
    }
    
    /**
     Displays a SwiftUI `View` instead of the title or attributed title.
     
     Any views inside a menu item can use the `menuItemIsHighlighted` environment value to alter their appearance when highlighted.
     
     By default, a highlight background will be drawn behind the view whenever `menuItemIsHighlighted` is `true`. You can disable this and handle highlighting yourself by passing `showsHighlight: false`
     
     - Parameters:
        - view: The  SwiftUI `View`.
        - showsHighlight: A Boolean value that indicates whether to draw the highlight when the item is highlighted.
     */
    @discardableResult
    func view<V: View>(_ view: V, showsHighlight: Bool = true) -> Self {
        self.view = NSMenuItemHostingView(rootView: view, showsHighlight: showsHighlight)
        return self
    }
    
    /**
     Displays a SwiftUI `View` instead of the title or attributed title.
     
     Any views inside a menu item can use the `menuItemIsHighlighted` environment value to alter their appearance when highlighted.
     
     By default, a highlight background will be drawn behind the view whenever `menuItemIsHighlighted` is `true`. You can disable this and handle highlighting yourself by passing `showsHighlight: false`
     
     - Parameters:
        - content: The  SwiftUI `View`.
        - sizingOptions: The options for how the view creates and updates constraints based on the size of `SwiftUI` view.
        - showsHighlight: A Boolean value that indicates whether to draw the highlight when the item is highlighted.
     */
    @available(macOS 13.0, *)
    @discardableResult
    func view<Content: View>(@ViewBuilder _ content: () -> Content, sizingOptions: NSHostingSizingOptions, showsHighlight: Bool = true) -> Self {
        view(content(), sizingOptions: sizingOptions, showsHighlight: showsHighlight)

    }
    
    /**
     Displays a SwiftUI `View` instead of the title or attributed title.
     
     Any views inside a menu item can use the `menuItemIsHighlighted` environment value to alter their appearance when highlighted.
     
     By default, a highlight background will be drawn behind the view whenever `menuItemIsHighlighted` is `true`. You can disable this and handle highlighting yourself by passing `showsHighlight: false`
     
     - Parameters:
        - view: The  SwiftUI `View`.
        - sizingOptions: The options for how the view creates and updates constraints based on the size of `view`.
        - showsHighlight: A Boolean value that indicates whether to draw the highlight when the item is highlighted.
     */
    @available(macOS 13.0, *)
    @discardableResult
    func view<V: View>(_ view: V, sizingOptions: NSHostingSizingOptions, showsHighlight: Bool = true) -> Self {
        self.view = NSMenuItemHostingView(rootView: view, showsHighlight: showsHighlight, sizingOptions: sizingOptions)
        return self
    }
    
    /// A help tag for the menu item.
    @discardableResult
    func toolTip(_ toolTip: String?) -> Self {
        self.toolTip = toolTip
        return self
    }
    
    /// The object represented by the menu item.
    @discardableResult
    func representedObject(_ object: Any?) -> Self {
        representedObject = object
        return self
    }
    
    /// A Boolean value that determines whether the system automatically remaps the keyboard shortcut to support localized keyboards.
    @available(macOS 12.0, *)
    @discardableResult
    func allowsAutomaticKeyEquivalentLocalization(_ allows: Bool) -> Self {
        self.allowsAutomaticKeyEquivalentLocalization = allows
        return self
    }
    
    /// A Boolean value that determines whether the system automatically swaps input strings for some keyboard shortcuts when the interface direction changes.
    @available(macOS 12.0, *)
    @discardableResult
    func allowsAutomaticKeyEquivalentMirroring(_ allows: Bool) -> Self {
        self.allowsAutomaticKeyEquivalentMirroring = allows
        return self
    }
    
    /// A Boolean value that determines whether the item allows the key equivalent when hidden.
    @discardableResult
    func allowsKeyEquivalentWhenHidden(_ allows: Bool) -> Self {
        self.allowsKeyEquivalentWhenHidden = allows
        return self
    }
    
    /// Sets the menu item’s menu.
    @discardableResult
    func menu(_ menu: NSMenu?) -> Self {
        self.menu = menu
        return self
    }
    
    /// Sets the menu item’s menu.
    @discardableResult
    func menu(@MenuBuilder _ items: @escaping () -> [NSMenuItem]) -> Self {
        menu = NSMenu().items(items)
        return self
    }
    
    /// The submenu of the menu item.
    @discardableResult
    func submenu(_ menu: NSMenu?) -> Self {
        submenu = menu
        return self
    }
    
    /// The submenu of the menu item.
    @discardableResult
    func submenu(@MenuBuilder _ items: @escaping () -> [NSMenuItem]) -> Self {
        submenu = NSMenu().items(items)
        return self
    }
    
    /// The visibilty of an item when it is visible in it's menu.
    enum Visiblity: Int {
        /// The default option that uses the menu item's `isHidden` property.^
        case normal
        /// The item is visible while the option key is hold.
        case optionHold
        /// The item is visible if the option key is pressed while the menu opens.
        case optionHoldOnMenuOpen
    }
    
    /// The visibilty of the item.
    var visiblity: Visiblity {
        get { getAssociatedValue("visiblity", initialValue: .normal) }
        set {
            setAssociatedValue(newValue, key: "visiblity")
            if newValue == .normal {
                menuObservation = nil
            } else if menuObservation == nil {
                menu?.setupDelegateProxy()
                menuObservation = observeChanges(for: \.menu) { old, new in
                    new?.setupDelegateProxy()
                }
            }
        }
    }
    
    /// Sets the visibilty of the item when it is visible in it's menu.
    @discardableResult
    func visiblity(_ visiblity: Visiblity) -> Self {
        self.visiblity = visiblity
        return self
    }
    
    internal var menuObservation: KeyValueObservation? {
        get { getAssociatedValue("menuObservation") }
        set { setAssociatedValue(newValue, key: "menuObservation") }
    }
}

@available(macOS 14.0, *)
public extension NSMenuItem {
    static func palette(
        images: [NSImage],
        titles: [String] = [],
        selectionMode: NSMenu.SelectionMode = .selectAny,
        onSelectionChange: ((IndexSet) -> Void)? = nil
    ) -> NSMenuItem {
        let paletteItem = NSMenuItem()
        let menu = NSMenu()
        menu.presentationStyle = .palette
        for (index, image) in images.enumerated() {
            let item = NSMenuItem(image: image)
            item.title = titles[safe: index] ?? ""
            item.image = image
            menu.addItem(item)
        }
        paletteItem.submenu = menu
        return paletteItem
    }
    
    static func palette(
        symbolImages: [String],
        titles: [String] = [],
        selectionMode: NSMenu.SelectionMode = .selectAny,
        onSelectionChange: ((IndexSet) -> Void)? = nil
    ) -> NSMenuItem {
        let paletteItem = NSMenuItem()
        let menu = NSMenu()
        menu.presentationStyle = .palette
        let images = symbolImages.compactMap({NSImage(systemSymbolName: $0)})
        for (index, image) in images.enumerated() {
            let item = NSMenuItem(image: image)
            item.title = titles[safe: index] ?? ""
            menu.addItem(item)
        }
        paletteItem.submenu = menu
        return paletteItem
    }
    
    /**
     Creates a palette style menu item displaying user-selectable color tags that tint using the specified array of colors.
     
     - Parameters:
        - colors: The display colors for the menu items.
        - titles: The menu item titles.
        - template: The image the system displays for the menu items.
        - selectionMode:
        - onSelectionChange: The closure to invoke when someone selects the menu item.
     
     - Returns: A menu item that presents with a palette.
     */
    static func palette(
        colors: [NSColor],
        titles: [String] = [],
        template: NSImage? = nil,
        offStateTemplate: NSImage? = nil,
        selectionMode: NSMenu.SelectionMode = .selectAny,
        onSelectionChange: (([NSColor]) -> Void)? = nil
    ) -> NSMenuItem {
        let paletteItem = NSMenuItem()
        let menu: NSMenu
        if let offStateTemplate = offStateTemplate {
            menu = .palette(colors: colors, titles: titles) { menu in
                guard let onSelectionChange = onSelectionChange else { return }
                let indexes = menu.selectedItems.compactMap({menu.items.firstIndex(of:$0)})
                let colors = indexes.compactMap({colors[safe: $0]})
                onSelectionChange(colors)
            }
            menu.items.forEach({$0.onStateImage = template})
            menu.items.forEach({$0.offStateImage = offStateTemplate})
        } else {
            menu = .palette(colors: colors, titles: titles, template: template) { menu in
                guard let onSelectionChange = onSelectionChange else { return }
                let indexes = menu.selectedItems.compactMap({menu.items.firstIndex(of:$0)})
                let colors = indexes.compactMap({colors[safe: $0]})
                onSelectionChange(colors)
            }
        }
        menu.selectionMode = selectionMode
        paletteItem.submenu = menu
        return paletteItem
    }
}
#endif
