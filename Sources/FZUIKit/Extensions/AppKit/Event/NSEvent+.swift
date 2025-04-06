//
//  NSEvent+.swift
//
//
//  Created by Florian Zand on 08.05.22.
//

#if os(macOS)

import AppKit
import Carbon
import Foundation
import FZSwiftUtils

public extension NSEvent {
    /**
     The location of the event inside the specified view.
     
     - Parameter view: The view for the location.
     */
    func location(in view: NSView) -> CGPoint {
        view.convert(locationInWindow, from: nil)
    }
    
    /// The screen location of the event.
    var screenLocation: CGPoint? {
        window?.convertToScreen(CGRect(locationInWindow, .zero)).origin
    }
    
    /// The last event that the app retrieved from the event queue.
    static var current: NSEvent? {
        NSApplication.shared.currentEvent
    }
    
    /**
     Creates and returns a new key down event with the specified key code.
     
     - Parameters:
        - key: The virtual code for the pressed key.
        - modifierFlags: The pressed modifier keys.
        - location: The cursor location in the window.
        - window: The window of the event.
        - isARepeat: A Boolean value indicating whether the event is a repeat caused by the user holding the key down.
     */
    static func keyDown(key: UInt16, modifierFlags: NSEvent.ModifierFlags = [], location: CGPoint = .zero, window: NSWindow, isARepeat: Bool = false) -> NSEvent? {
        keyEvent(keyCode: key, modifierFlags: modifierFlags, location: location, keyDown: true, window: window, isARepeat: isARepeat)
    }
    
    /**
     Creates and returns a new key down event with the specified key code.
     
     - Parameters:
        - key: The virtual code for the pressed key.
        - modifierFlags: The pressed modifier keys.
        - location: The cursor location on the screen.
        - isARepeat: A Boolean value indicating whether the event is a repeat caused by the user holding the key down.
     */
    static func keyDown(key: UInt16, modifierFlags: NSEvent.ModifierFlags = [], location: CGPoint = .zero, isARepeat: Bool = false) -> NSEvent? {
        keyEvent(keyCode: key, modifierFlags: modifierFlags, location: location, keyDown: true, isARepeat: isARepeat)
    }
    
    /**
     Creates and returns a new key down event with the specified key.
     
     - Parameters:
        - key: The pressed key.
        - modifierFlags: The pressed modifier keys.
        - location: The cursor location in the window.
        - window: The window of the event.
        - isARepeat: A Boolean value indicating whether the event is a repeat caused by the user holding the key down.
     */
    static func keyDown(key: Key, modifierFlags: NSEvent.ModifierFlags = [], location: CGPoint = .zero, window: NSWindow, isARepeat: Bool = false) -> NSEvent? {
        keyEvent(keyCode: key.rawValue, modifierFlags: modifierFlags, location: location, keyDown: true, window: window, isARepeat: isARepeat)
    }
    
    /**
     Creates and returns a new key down event with the specified key.
     
     - Parameters:
        - key: The pressed key.
        - modifierFlags: The pressed modifier keys.
        - location: The cursor location on the screen.
        - isARepeat: A Boolean value indicating whether the event is a repeat caused by the user holding the key down.
     */
    static func keyDown(key: Key, modifierFlags: NSEvent.ModifierFlags = [], location: CGPoint = .zero, isARepeat: Bool = false) -> NSEvent? {
        keyEvent(keyCode: key.rawValue, modifierFlags: modifierFlags, location: location, keyDown: true, isARepeat: isARepeat)
    }
    
    /**
     Creates and returns a new key up event with the specified key code.
     
     - Parameters:
        - key: The virtual code for the pressed key.
        - modifierFlags: The pressed modifier keys.
        - location: The cursor location in the window.
        - window: The window of the event.
     */
    static func keyUp(key: UInt16, modifierFlags: NSEvent.ModifierFlags = [], location: CGPoint = .zero, window: NSWindow) -> NSEvent? {
        keyEvent(keyCode: key, modifierFlags: modifierFlags, location: location, keyDown: false, window: window)
    }
    
    /**
     Creates and returns a new key up event with the specified key code.
     
     - Parameters:
        - key: The virtual code for the pressed key.
        - modifierFlags: The pressed modifier keys.
        - location: The cursor location on the screen.
     */
    static func keyUp(key: UInt16, modifierFlags: NSEvent.ModifierFlags = [], location: CGPoint = .zero) -> NSEvent? {
        keyEvent(keyCode: key, modifierFlags: modifierFlags, location: location, keyDown: false)
    }
    
    /**
     Creates and returns a new key up event with the specified key.
     
     - Parameters:
        - key: The pressed key.
        - modifierFlags: The pressed modifier keys.
        - location: The cursor location in the window.
        - window: The window of the event.
     */
    static func keyUp(key: Key, modifierFlags: NSEvent.ModifierFlags = [], location: CGPoint = .zero, window: NSWindow, isARepeat: Bool = false) -> NSEvent? {
        keyEvent(keyCode: key.rawValue, modifierFlags: modifierFlags, location: location, keyDown: false, window: window)
    }
    
    /**
     Creates and returns a new key up event with the specified key.
     
     - Parameters:
        - key: The pressed key.
        - modifierFlags: The pressed modifier keys.
        - location: The cursor location on the screen.
     */
    static func keyUp(key: Key, modifierFlags: NSEvent.ModifierFlags = [], location: CGPoint = .zero, isARepeat: Bool = false) -> NSEvent? {
        keyEvent(keyCode: key.rawValue, modifierFlags: modifierFlags, location: location, keyDown: false)
    }
    
    private static func keyEvent(keyCode: UInt16, modifierFlags: NSEvent.ModifierFlags = [], location: CGPoint = .zero, keyDown: Bool, window: NSWindow? = nil,  isARepeat: Bool = false) -> NSEvent? {
        guard let cgEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: keyDown) else { return nil }
        cgEvent.flags = modifierFlags.cgEventFlags
        cgEvent.location = location
        guard let event = NSEvent(cgEvent: cgEvent) else { return nil }
        return NSEvent.keyEvent(with: event.type, location: location, modifierFlags: modifierFlags, timestamp: .now, windowNumber: window?.windowNumber ?? 0, context: nil, characters: event.characters!, charactersIgnoringModifiers: event.charactersIgnoringModifiers!, isARepeat: isARepeat, keyCode: keyCode) ?? event
    }
    
    /**
     Creates and returns a new mouse event.
     
     - Parameters:
        - type: The mouse event type.
        - location: The cursor location on the specified window.
        - modifierFlags: The modifier flags pressed.
        - clickCount: The number of mouse clicks associated with the mouse event.
        - pressure: The pressure (between `0.0` to `1.0`) applied to the input device (such as a graphics tablet).
        - window: The window of the event.
     */
    static func mouse(_ type: MouseEventType, location: CGPoint, modifierFlags: NSEvent.ModifierFlags = [], clickCount: Int = 1, pressure: Float = 1.0, window: NSWindow) -> NSEvent? {
        NSEvent.mouseEvent(with: type.type, location: location, modifierFlags: modifierFlags, timestamp: .now, windowNumber: window.windowNumber, context: nil, eventNumber: Int.random(in: 0...Int.max), clickCount: clickCount, pressure: pressure.clamped(max: 1.0))
    }
    
    /**
     Creates and returns a new mouse event.
     
     - Parameters:
        - type: The mouse event type.
        - location: The cursor location on the screen.
        - modifierFlags: The modifier flags pressed.
        - clickCount: The number of mouse clicks associated with the mouse event.
        - pressure: The pressure (between `0.0` to `1.0`) applied to the input device (such as a graphics tablet).
     */
    static func mouse(_ type: MouseEventType, location: CGPoint, modifierFlags: NSEvent.ModifierFlags = [], clickCount: Int = 1, pressure: Float = 1.0) -> NSEvent? {
        NSEvent.mouseEvent(with: type.type, location: location, modifierFlags: modifierFlags, timestamp: .now, windowNumber: 0, context: nil, eventNumber: Int.random(in: 0...Int.max), clickCount: clickCount, pressure: pressure.clamped(max: 1.0))
    }
    
    /// Constants for the mouse event types.
    enum MouseEventType {
        /// Left mouse down.
        case leftDown
        /// Left mouse up.
        case leftUp
        /// Left mouse dragged.
        case leftDragged
        /// Right mouse down.
        case rightDown
        /// Right mouse up.
        case rightUp
        /// Right mouse dragged.
        case rightDragged
        /// Other mouse down.
        case otherDown
        /// Other mouse up.
        case otherUp
        /// Other mouse dragged.
        case otherDragged
        /// Mouse entered.
        case entered
        /// Mouse moved.
        case moved
        /// Mouse exited.
        case exited
        
        var type: NSEvent.EventType {
            switch self {
            case .leftDown: return .leftMouseDown
            case .leftUp: return .leftMouseUp
            case .leftDragged: return .leftMouseDragged
            case .rightDown: return .rightMouseDown
            case .rightUp: return .rightMouseUp
            case .rightDragged: return .rightMouseDragged
            case .otherDown: return .otherMouseDown
            case .otherUp: return .otherMouseUp
            case .otherDragged: return .otherMouseDragged
            case .entered: return .mouseEntered
            case .moved: return .mouseMoved
            case .exited: return .mouseExited
            }
        }
    }
    
    /// A Boolean value that indicates whether no modifier key is pressed.
    var isNoModifierPressed: Bool {
        modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty
    }
    
    /**
     A Boolean value that indicates whether the event type is a right mouse-down event.
     
     The value returns `true` for:
     - type is `rightMouseDown`
     - type is `leftMouseDown` and modifierFlags contains `control`.
     */
    var isRightMouseDown: Bool {
        type == .rightMouseDown || (modifierFlags.contains(.control) && type == .leftMouseDown)
    }
    
    /**
     A Boolean value that indicates whether the event is a right mouse-up event.
     
     The value returns `true` for:
     - type is `rightMouseUp`
     - type is `leftMouseUp` and modifierFlags contains `control`.
     */
    var isRightMouseUp: Bool {
        type == .rightMouseUp || (modifierFlags.contains(.control) && type == .leftMouseUp)
    }
    
    /// A Boolean value that indicates whether the event is a user interaction event.
    var isUserInteraction: Bool {
        type == .userInteraction
    }
    
    /// A Boolean value that indicates whether the event is a keyboard event (`keyDown`, `keyUp` or `flagsChanged`).
    var isKeyboard: Bool {
        type == .keyboard
    }
    
    /// A Boolean value that indicates whether the event is a mouse click event.
    var isMouse: Bool {
        type == .mouse
    }
    
    /// A Boolean value that indicates whether the event is either a `.leftMouseDown`, `.leftMouseUp` or `.leftMouseDragged` event.
    var isLeftMouse: Bool {
        type == .leftMouse
    }
    
    /// A Boolean value that indicates whether the event is either a `rightMouseDown`, `rightMouseUp` or `rightMouseDragged` event.
    var isRightMouse: Bool {
        type == .rightMouse
    }
    
    /// A Boolean value that indicates whether the event is either a `.otherMouseDown`, `.otherMouseUp` or `.otherMouseDragged` event.
    var isOtherMouse: Bool {
        type == .otherMouse
    }
    
    /// A Boolean value that indicates whether the event is a mouse movement event (`mouseEntered`, `mouseMoved` or `mouseExited`).
    var isMouseMovement: Bool {
        type == .mouseMovements
    }
    
    /// A Boolean value that indicates whether the `command` key is pressed.
    var isCommandPressed: Bool {
        modifierFlags.contains(.command)
    }
    
    /// A Boolean value that indicates whether the `option` key is pressed.
    var isOptionPressed: Bool {
        modifierFlags.contains(.option)
    }
    
    /// A Boolean value that indicates whether the `control` key is pressed.
    var isControlPressed: Bool {
        modifierFlags.contains(.control)
    }
    
    /// A Boolean value that indicates whether the `shift` key is pressed.
    var isShiftPressed: Bool {
        modifierFlags.contains(.shift)
    }
    
    /// A Boolean value that indicates whether the `capslock` key is pressed.
    var isCapsLockPressed: Bool {
        modifierFlags.contains(.capsLock)
    }
    
    /// A Boolean value that indicates whether the `function` key is pressed.
    var isFunctionPressed: Bool {
        modifierFlags.contains(.function)
    }
}

extension NSEvent.EventType: Hashable, Codable { }
extension NSEvent.EventTypeMask: Hashable, Codable { }
extension NSEvent.ModifierFlags: Hashable, Codable { }

extension NSEvent.EventType {
    static func == (lhs: Self, rhs: NSEvent.EventTypeMask) -> Bool {
        rhs.intersects(lhs)
    }
}

extension NSEvent.EventSubtype: CustomStringConvertible {
    public var description: String {
        switch self {
        case .applicationActivated: return "applicationActivated"
        case .applicationDeactivated: return "applicationDeactivated"
        case .windowMoved: return "windowMoved"
        case .screenChanged: return "screenChanged"
        case .touch: return "touch"
        case .tabletPoint: return "tabletPoint"
        case .tabletProximity: return "tabletProximity"
        case .mouseEvent:  return "mouseEvent"
        default: return "other(\(rawValue))"
        }
    }
}

extension NSEvent.EventType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .leftMouseDown: return "leftMouseDown"
        case .leftMouseUp: return "leftMouseUp"
        case .rightMouseDown: return "rightMouseDown"
        case .rightMouseUp: return "rightMouseUp"
        case .mouseMoved: return "mouseMoved"
        case .leftMouseDragged: return "leftMouseDragged"
        case .rightMouseDragged: return "rightMouseDragged"
        case .mouseEntered: return "mouseEntered"
        case .mouseExited: return "mouseExited"
        case .keyDown: return "keyDown"
        case .keyUp: return "keyUp"
        case .flagsChanged: return "flagsChanged"
        case .appKitDefined: return "appKitDefined"
        case .systemDefined: return "systemDefined"
        case .applicationDefined: return "applicationDefined"
        case .periodic: return "periodic"
        case .cursorUpdate: return "cursorUpdate"
        case .scrollWheel: return "scrollWheel"
        case .tabletPoint: return "tabletPoint"
        case .tabletProximity: return "tabletProximity"
        case .otherMouseDown: return "otherMouseDown"
        case .otherMouseUp: return "otherMouseUp"
        case .otherMouseDragged: return "otherMouseDragged"
        case .gesture: return "gesture"
        case .magnify: return "magnify"
        case .swipe: return "swipe"
        case .rotate: return "rotate"
        case .beginGesture: return "beginGesture"
        case .endGesture: return "endGesture"
        case .smartMagnify: return "smartMagnify"
        case .quickLook: return "quickLook"
        case .pressure: return "pressure"
        case .directTouch: return "directTouch"
        case .changeMode: return "changeMode"
        default: return "other(\(rawValue))"
        }
    }
}

extension NSEvent.EventTypeMask: CustomStringConvertible {
    /// A Boolean value that indicates whether the specified event intersects with the mask.
    public func intersects(_ event: NSEvent?) -> Bool {
        guard let event = event else { return false }
        if event.type == .mouse {
            return event.associatedEventsMask.intersection(self).isEmpty == false
        }
        return self.intersects(event.type)
    }
    
    /// A Boolean value that indicates whether the specified event type intersects with the mask.
    public func intersects(_ type: NSEvent.EventType) -> Bool {
        switch type {
        case .leftMouseDown: return contains(.leftMouseDown)
        case .leftMouseUp: return contains(.leftMouseUp)
        case .rightMouseDown: return contains(.rightMouseDown)
        case .rightMouseUp: return contains(.rightMouseUp)
        case .mouseMoved: return contains(.mouseMoved)
        case .leftMouseDragged: return contains(.leftMouseDragged)
        case .rightMouseDragged: return contains(.rightMouseDragged)
        case .mouseEntered: return contains(.mouseEntered)
        case .mouseExited: return contains(.mouseExited)
        case .keyDown: return contains(.keyDown)
        case .keyUp: return contains(.keyUp)
        case .flagsChanged: return contains(.flagsChanged)
        case .appKitDefined: return contains(.appKitDefined)
        case .systemDefined: return contains(.systemDefined)
        case .applicationDefined: return contains(.applicationDefined)
        case .periodic: return contains(.periodic)
        case .cursorUpdate: return contains(.cursorUpdate)
        case .scrollWheel: return contains(.scrollWheel)
        case .tabletPoint: return contains(.tabletPoint)
        case .tabletProximity: return contains(.tabletProximity)
        case .otherMouseDown: return contains(.otherMouseDown)
        case .otherMouseUp: return contains(.otherMouseUp)
        case .otherMouseDragged: return contains(.otherMouseDragged)
        case .gesture: return contains(.gesture)
        case .magnify: return contains(.magnify)
        case .swipe: return contains(.swipe)
        case .rotate: return contains(.rotate)
        case .beginGesture: return contains(.beginGesture)
        case .endGesture: return contains(.endGesture)
        case .smartMagnify: return contains(.smartMagnify)
        case .pressure: return contains(.pressure)
        case .directTouch: return contains(.directTouch)
        case .changeMode: return contains(.changeMode)
        //  case .quickLook: return contains(.quick)
        default: return false
        }
    }
    
    /// A mask for user interaction events  (`keyboard`, `mouse`, `mouseMovements`, `magnify`, `scrollWheel`, `swipe` or `rotate`).
    public static let userInteraction: NSEvent.EventTypeMask = keyboard + mouse + mouseMovements + [.magnify, .scrollWheel, .swipe, .rotate]
    
    /// A mask for keyboard events (`keyDown`, `keyUp` or `flagsChanged`).
    public static let keyboard: NSEvent.EventTypeMask = [.keyDown, .keyUp, .flagsChanged]
    
    /// A mask for mouse click events (`left`, `right` or `other`).
    public static let mouse: NSEvent.EventTypeMask = leftMouse + rightMouse + otherMouse
    
    /// A mask for left mouse click events  (`leftMouseDown`, `leftMouseUp` or `leftMouseDragged`).
    public static let leftMouse: NSEvent.EventTypeMask = [.leftMouseDown, .leftMouseUp, .leftMouseDragged]
    
    /// A mask for right mouse click events  (`rightMouseDown`, `rightMouseUp` or `rightMouseDragged`).
    public static let rightMouse: NSEvent.EventTypeMask = [.rightMouseDown, .rightMouseUp, .rightMouseDragged]
    
    /// A mask for other mouse click events (`otherMouseDown`, `otherMouseUp` or `otherMouseDragged`).
    public static let otherMouse: NSEvent.EventTypeMask = [.otherMouseDown, .otherMouseUp, .otherMouseDragged]
    
    /// A mask for mouse movement events (`mouseEntered`, `mouseMoved` or `mouseExited`).
    public static let mouseMovements: NSEvent.EventTypeMask = [.mouseEntered, .mouseMoved, .mouseExited]
    
    public var description: String {
        var strings: [String] = []
        if self.contains(.leftMouseDown) { strings += ".leftMouseDown" }
        if self.contains(.leftMouseUp) { strings += ".leftMouseDown" }
        if self.contains(.leftMouseDragged) { strings += ".leftMouseDown" }
        if self.contains(.rightMouseDown) { strings += ".leftMouseDown" }
        if self.contains(.rightMouseUp) { strings += ".leftMouseDown" }
        if self.contains(.rightMouseDragged) { strings += ".leftMouseDown" }
        if self.contains(.otherMouseDown) { strings += ".leftMouseDown" }
        if self.contains(.otherMouseUp) { strings += ".leftMouseDown" }
        if self.contains(.otherMouseDragged) { strings += ".leftMouseDown" }
        if self.contains(.keyDown) { strings += ".keyDown" }
        if self.contains(.keyUp) { strings += ".keyUp" }
        if self.contains(.flagsChanged) { strings += ".flagsChanged" }
        if self.contains(.mouseEntered) { strings += ".mouseEntered" }
        if self.contains(.mouseMoved) { strings += ".mouseMoved" }
        if self.contains(.mouseExited) { strings += ".mouseExited" }
        if self.contains(.beginGesture) { strings += ".beginGesture" }
        if self.contains(.endGesture) { strings += ".endGesture" }
        if self.contains(.magnify) { strings += ".magnify" }
        if self.contains(.smartMagnify) { strings += ".smartMagnify" }
        if self.contains(.swipe) { strings += ".swipe" }
        if self.contains(.rotate) { strings += ".rotate" }
        if self.contains(.gesture) { strings += ".gesture" }
        if self.contains(.directTouch) { strings += ".directTouch" }
        if self.contains(.tabletPoint) { strings += ".tabletPoint" }
        if self.contains(.tabletProximity) { strings += ".tabletProximity" }
        if self.contains(.pressure) { strings += ".pressure" }
        if self.contains(.scrollWheel) { strings += ".scrollWheel" }
        if self.contains(.changeMode) { strings += ".changeMode" }
        if self.contains(.appKitDefined) { strings += ".appKitDefined" }
        if self.contains(.applicationDefined) { strings += ".applicationDefined" }
        if self.contains(.cursorUpdate) { strings += ".cursorUpdate" }
        if self.contains(.periodic) { strings += ".periodic" }
        if self.contains(.systemDefined) { strings += ".systemDefined" }
        return "[\(strings.joined(separator: ", "))]"
    }
}

public extension NSEvent.ModifierFlags {
    /// A `CGEventFlags` representation of the modifier flags.
    var cgEventFlags: CGEventFlags {
        var flags: CGEventFlags = []
        if contains(.shift) { flags.insert(.maskShift) }
        if contains(.control) { flags.insert(.maskControl) }
        if contains(.command) { flags.insert(.maskCommand) }
        if contains(.numericPad) { flags.insert(.maskNumericPad) }
        if contains(.help) { flags.insert(.maskHelp) }
        if contains(.option) { flags.insert(.maskAlternate) }
        if contains(.function) { flags.insert(.maskSecondaryFn) }
        if contains(.capsLock) { flags.insert(.maskAlphaShift) }
        return flags
    }
}

extension CGEvent {
    /// The location of the mouse pointer.
    public static var mouseLocation: CGPoint? {
        CGEvent(source: nil)?.location
    }
}
#endif
