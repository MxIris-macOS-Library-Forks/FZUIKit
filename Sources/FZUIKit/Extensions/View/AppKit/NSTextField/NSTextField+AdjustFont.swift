//
//  NSTextField+AdjustFont.swift
//
//
//  Created by Florian Zand on 05.10.23.
//

#if os(macOS)

import AppKit
import FZSwiftUtils

extension NSTextField {
    /**
     A Boolean value that determines whether the text field reduces the text’s font size to fit the title string into the text field’s bounding rectangle.
     
     Normally, the text field draws the text with the font you specify in the `font` property. If this property is true, and the text in the `stringValue` property exceeds the text field’s bounding rectangle, the text field reduces the font size until the text fits or it has scaled the font down to the minimum font size. The default value for this property is `false`. If you change it to `true`, be sure that you also set an appropriate minimum font scale by modifying the ``AppKit/NSTextField/adjustsFontSizeToFitWidth`` property. This autoshrinking behavior is only intended for use with a single-line text field.
     */
    public var adjustsFontSizeToFitWidth: Bool {
        get { getAssociatedValue(key: "adjustsFontSizeToFitWidth", object: self, initialValue: false) }
        set {
            guard newValue != adjustsFontSizeToFitWidth else { return }
            set(associatedValue: newValue, key: "adjustsFontSizeToFitWidth", object: self)
            self.setupTextFieldObserver()
        }
    }
    
    /**
     The minimum scale factor for the text field’s text.
     
     If the ``AppKit/NSTextField/adjustsFontSizeToFitWidth`` is `true, use this property to specify the smallest multiplier for the current font size that yields an acceptable font size for the text field’s text. If you specify a value of 0 for this property, the text field doesn’t scale the text down. The default value of this property is 0.
     */
    public var minimumScaleFactor: CGFloat {
        get { getAssociatedValue(key: "minimumScaleFactor", object: self, initialValue: 0.0) }
        set {
            let newValue = newValue.clamped(max: 1.0)
            guard newValue != minimumScaleFactor else { return }
            set(associatedValue: newValue, key: "minimumScaleFactor", object: self)
            self.setupTextFieldObserver()
        }
    }
    
    internal var isFittingCurrentText: Bool {
        let isFitting = !isTruncatingText
        if isFitting == true {
            if let cell = cell, cell.cellSize(forBounds: CGRect(.zero, CGSize(bounds.width, CGFloat.greatestFiniteMagnitude))).height > bounds.height {
                return false
            }
        }
        return isFitting
    }
    
    internal func adjustFontSize(requiresSmallerScale: Bool = false) {
        guard let _font = _font else { return }
        self.isAdjustingFontSize = true
        cell?.font = _font
        self.stringValue = self.stringValue
        if adjustsFontSizeToFitWidth, minimumScaleFactor != 0.0 {
            var scaleFactor = requiresSmallerScale ? lastFontScaleFactor : 1.0
            var needsUpdate = !isFittingCurrentText
            while needsUpdate && scaleFactor >= minimumScaleFactor {
                scaleFactor = scaleFactor - 0.005
                let adjustedFont = _font.withSize(_font.pointSize * scaleFactor)
                cell?.font = adjustedFont
                needsUpdate = !isFittingCurrentText
            }
            lastFontScaleFactor = scaleFactor
            if needsUpdate, allowsDefaultTighteningForTruncation {
                adjustFontKerning()
            }
        } else if allowsDefaultTighteningForTruncation {
            adjustFontKerning()
        }
        self.isAdjustingFontSize = false
    }
    
    internal func adjustFontKerning() {
        guard let fontSize = _font?.pointSize else { return }
        var needsUpdate = !isFittingCurrentText
        var kerning: Float = 0.0
        let maxKerning: Float
        if fontSize < 8 {
            maxKerning = 0.6
        } else if fontSize < 16 {
            maxKerning = 0.8
        } else {
            maxKerning = 1.0
        }
        while needsUpdate && kerning <= maxKerning {
            self.attributedStringValue = self.attributedStringValue.applyingAttributes( [.kern: -kerning])
            kerning += 0.005
            needsUpdate = !isFittingCurrentText
        }
    }
    
    internal func setupTextFieldObserver() {
        if (adjustsFontSizeToFitWidth && minimumScaleFactor != 0.0) || allowsDefaultTighteningForTruncation {
            swizzleTextField()
            if observer == nil {
                observer = KeyValueObserver(self)
                observer?.add(\.stringValue, handler: { [weak self] old, new in
                    guard let self = self, self.isAdjustingFontSize == false, old != new else { return }
                    self.adjustFontSize()
                })
                observer?.add(\.isBezeled, handler: { [weak self] old, new in
                    guard let self = self, old != new else { return }
                    self.adjustFontSize()
                })
                observer?.add(\.isBordered, handler: { [weak self] old, new in
                    guard let self = self, old != new else { return }
                    self.adjustFontSize()
                })
                observer?.add(\.bezelStyle, handler: { [weak self] old, new in
                    guard let self = self, self.isBezeled, old != new else { return }
                    self.adjustFontSize()
                })
                observer?.add(\.preferredMaxLayoutWidth, handler: { [weak self] old, new in
                    guard let self = self, old != new else { return }
                    self.adjustFontSize()
                })
                observer?.add(\.allowsDefaultTighteningForTruncation, handler: { [weak self] old, new in
                    guard let self = self, old != new else { return }
                    self.adjustFontSize()
                })
                observer?.add(\.maximumNumberOfLines, handler: { [weak self] old, new in
                    guard let self = self, old != new else { return }
                    self.adjustFontSize()
                })
            }
        } else {
            observer = nil
        }
        self.adjustFontSize()
    }

    internal func updateString() {
        let newString = self.allowedCharacters.trimString(self.stringValue)
        if let shouldEdit = self.editingHandlers.shouldEdit {
            if shouldEdit(self.stringValue) == false {
                self.stringValue = self.previousString
            } else {
                self.editingHandlers.didEdit?()
            }
        } else if let maxCharCount = self.maximumNumberOfCharacters, newString.count > maxCharCount {
            if self.previousString.count <= maxCharCount {
                self.stringValue = self.previousString
                self.currentEditor()?.selectedRange = self.editingRange
            } else {
                self.stringValue = String(newString.prefix(maxCharCount))
            }
            self.editingHandlers.didEdit?()
        } else if let minCharCount = self.minimumNumberOfCharacters, newString.count < minCharCount  {
            if self.previousString.count >= minCharCount {
                self.stringValue = self.previousString
                self.currentEditor()?.selectedRange = self.editingRange
            }
        } else {
            self.stringValue = newString
            if self.previousString == newString {
                self.currentEditor()?.selectedRange = self.editingRange
            }
            self.editingHandlers.didEdit?()
        }
        self.previousString = self.stringValue
        if let editingRange = self.currentEditor()?.selectedRange {
            self.editingRange = editingRange
        }
        self.adjustFontSize()
    }
    
    internal func swizzleTextField() {
        guard didSwizzleTextField == false else { return }
        didSwizzleTextField = true
        _font = self.font
        
        do {
            try self.replaceMethod(
                #selector(setter: font),
                methodSignature: (@convention(c)  (AnyObject, Selector, NSFont?) -> Void).self,
                hookSignature: (@convention(block)  (AnyObject, NSFont?) -> Void).self) { store in { object, font in
                    let textField = (object as? NSTextField)
                    textField?._font = font
                    textField?.adjustFontSize()
                }
                }
            
            try self.replaceMethod(
                #selector(getter: font),
                methodSignature: (@convention(c)  (AnyObject, Selector) -> NSFont?).self,
                hookSignature: (@convention(block)  (AnyObject) -> NSFont?).self) { store in { object in
                    return (object as! NSTextField)._font
                }
                }
            
            try self.replaceMethod(
                #selector(layout),
                methodSignature: (@convention(c)  (AnyObject, Selector) -> ()).self,
                hookSignature: (@convention(block)  (AnyObject) -> ()).self) { store in { object in
                    store.original(object, #selector(NSView.layout))
                    if let textField = (object as? NSTextField), textField.bounds.size != textField._bounds.size {
                        textField.adjustFontSize()
                        textField._bounds = textField.bounds
                    }
                }
                }
            
            try self.replaceMethod(
                #selector(NSTextViewDelegate.textView(_:doCommandBy:)),
                methodSignature: (@convention(c)  (AnyObject, Selector, NSTextView, Selector) -> (Bool)).self,
                hookSignature: (@convention(block)  (AnyObject, NSTextView, Selector) -> (Bool)).self) { store in { object, textView, selector in
                    if let doCommand = (object as? NSTextField)?.editingHandlers.doCommand {
                        return doCommand(selector)
                    }
                    if let textField = object as? NSTextField {
                        switch selector {
                        case #selector(NSControl.cancelOperation(_:)):
                            switch textField.actionOnEscapeKeyDown {
                            case .endEditingAndReset(handler: let handler):
                                textField.stringValue = textField.editStartString
                                textField.adjustFontSize()
                                handler?()
                                return true
                            case .endEditing(handler: let handler):
                                textField.window?.makeFirstResponder(nil)
                                handler?()
                                return true
                            case .none:
                                break
                            }
                        case #selector(NSControl.insertNewline(_:)):
                            switch textField.actionOnEnterKeyDown {
                            case .endEditing(handler: let handler):
                                handler?()
                                return true
                            case .none: break
                            }
                        default: break
                        }
                    }
                    return store.original(object, #selector(NSTextViewDelegate.textView(_:doCommandBy:)), textView, selector)
                }
                }
            
            try self.replaceMethod(
                #selector(textDidEndEditing),
                methodSignature: (@convention(c)  (AnyObject, Selector, Notification) -> ()).self,
                hookSignature: (@convention(block)  (AnyObject, Notification) -> ()).self) { store in { object, notification in
                    let textField = (object as? NSTextField)
                  //  textField?.editingState = .didEnd
                    textField?.adjustFontSize()
                    textField?.editingHandlers.didEnd?()
                    store.original(object, #selector(NSTextField.textDidEndEditing), notification)
                }
                }
            
            try self.replaceMethod(
                #selector(textDidBeginEditing),
                methodSignature: (@convention(c)  (AnyObject, Selector, Notification) -> ()).self,
                hookSignature: (@convention(block)  (AnyObject, Notification) -> ()).self) { store in { object, notification in
                    store.original(object, #selector(NSTextField.textDidBeginEditing), notification)
                    if let textField = (object as? NSTextField) {
                        textField.editStartString = textField.stringValue
                        textField.previousString = textField.stringValue
                        textField.editingHandlers.didBegin?()
                        if let editingRange = textField.currentEditor()?.selectedRange {
                            textField.editingRange = editingRange
                        }
                    }
                }
                }
            
            try self.replaceMethod(
                #selector(textDidChange),
                methodSignature: (@convention(c)  (AnyObject, Selector, Notification) -> ()).self,
                hookSignature: (@convention(block)  (AnyObject, Notification) -> ()).self) { store in { object, notification in
                    if let textField = (object as? NSTextField) {
                        textField.updateString()
                        /*
                        let newStr = textField.conformingString()
                        if textField.stringValue != newStr {
                            textField.stringValue = newStr
                            if textField.previousString != newStr {
                                textField.editingHandlers.didEdit?()
                                textField.adjustFontSize()
                                textField.previousString = textField.stringValue
                                if let editingRange = textField.currentEditor()?.selectedRange {
                                    textField.editingRange = editingRange
                                }
                            } else {
                                textField.currentEditor()?.selectedRange = textField.editingRange
                            }
                        }
                        
                        let newString = textField.allowedCharacters.trimString(textField.stringValue)
                        if let shouldEdit = textField.editingHandlers.shouldEdit {
                            if shouldEdit(textField.stringValue) == false {
                                textField.stringValue = textField.previousString
                            } else {
                                textField.editingHandlers.didEdit?()
                            }
                        } else if let maxCharCount = textField.maximumNumberOfCharacters, newString.count > maxCharCount {
                            if textField.previousString.count <= maxCharCount {
                                textField.stringValue = textField.previousString
                                textField.currentEditor()?.selectedRange = textField.editingRange
                            } else {
                                textField.stringValue = String(newString.prefix(maxCharCount))
                            }
                            textField.editingHandlers.didEdit?()
                        } else if let minCharCount = textField.minimumNumberOfCharacters, newString.count < minCharCount  {
                            if textField.previousString.count >= minCharCount {
                                textField.stringValue = textField.previousString
                                textField.currentEditor()?.selectedRange = textField.editingRange
                            }
                        } else {
                            textField.stringValue = newString
                            if textField.previousString == newString {
                                textField.currentEditor()?.selectedRange = textField.editingRange
                            }
                            textField.editingHandlers.didEdit?()
                        }
                        textField.previousString = textField.stringValue
                        if let editingRange = textField.currentEditor()?.selectedRange {
                            textField.editingRange = editingRange
                        }
                        textField.adjustFontSize()
                        */
                    }
                    store.original(object, #selector(NSTextField.textDidChange), notification)
                }
                }
        } catch {
            Swift.debugPrint(error)
        }
    }
    
    internal var isAdjustingFontSize: Bool {
        get { getAssociatedValue(key: "isAdjustingFontSize", object: self, initialValue: false) }
        set { set(associatedValue: newValue, key: "isAdjustingFontSize", object: self)
        }
    }
    
    internal var didSwizzleTextField: Bool {
        get { getAssociatedValue(key: "didSwizzleTextField", object: self, initialValue: false) }
        set {
            set(associatedValue: newValue, key: "didSwizzleTextField", object: self)
        }
    }
    
    internal var _bounds: CGRect {
        get { getAssociatedValue(key: "bounds", object: self, initialValue: .zero) }
        set { set(associatedValue: newValue, key: "bounds", object: self) }
    }
    
    internal var lastFontScaleFactor: CGFloat {
        get { getAssociatedValue(key: "lastFontScaleFactor", object: self, initialValue: 1.0) }
        set { set(associatedValue: newValue, key: "lastFontScaleFactor", object: self) }
    }
    
    internal var _font: NSFont? {
        get { getAssociatedValue(key: "_font", object: self, initialValue: nil) }
        set { set(associatedValue: newValue, key: "_font", object: self) }
    }
    
    internal var editStartString: String {
        get { getAssociatedValue(key: "editStartString", object: self, initialValue: self.stringValue) }
        set { set(associatedValue: newValue, key: "editStartString", object: self) }
    }
    
    internal var previousString: String {
        get { getAssociatedValue(key: "previousString", object: self, initialValue: self.stringValue) }
        set { set(associatedValue: newValue, key: "previousString", object: self) }
    }
    
    internal var editingRange: NSRange {
        get { getAssociatedValue(key: "editingRange", object: self, initialValue: self.currentEditor()?.selectedRange ?? NSRange(location: 0, length: 0)) }
        set { set(associatedValue: newValue, key: "editingRange", object: self) }
    }
    
    internal var observer: KeyValueObserver<NSTextField>? {
        get { getAssociatedValue(key: "observer", object: self, initialValue: nil) }
        set { set(associatedValue: newValue, key: "observer", object: self) }
    }
}

#endif

/*
 internal func swizzleTextField() {
 guard didSwizzleTextField == false else { return }
 didSwizzleTextField = true
 _font = self.font
 keyDownMonitor = NSEvent.localMonitor(for: .keyDown) {event in
 if self.hasKeyboardFocus, self.editingState != .didEnd {
 if event.keyCode == 36, self.actionOnEnterKeyDown == .endEditing {
 self.window?.makeFirstResponder(nil)
 return nil
 }
 if event.keyCode == 53 {
 if self.actionOnEscapeKeyDown == .endEditingAndReset {
 self.stringValue = self.editStartString
 self.adjustFontSize()
 }
 if self.actionOnEscapeKeyDown != .none {
 self.window?.makeFirstResponder(nil)
 return nil
 }
 }
 }
 return event
 }
 guard let viewClass = object_getClass(self) else { return }
 let viewSubclassName = String(cString: class_getName(viewClass)).appending("_animatable")
 if let viewSubclass = NSClassFromString(viewSubclassName) {
 object_setClass(self, viewSubclass)
 } else {
 guard let viewClassNameUtf8 = (viewSubclassName as NSString).utf8String else { return }
 guard let viewSubclass = objc_allocateClassPair(viewClass, viewClassNameUtf8, 0) else { return }
 if let getFontMethod = class_getInstanceMethod(viewClass, #selector(getter: NSTextField.font)),
 let setFontMethod = class_getInstanceMethod(viewClass, #selector(setter: NSTextField.font)),
 let textDidChangeMethod = class_getInstanceMethod(viewClass, #selector(textDidChange)),
 let textDidEndEditingMethod = class_getInstanceMethod(viewClass, #selector(textDidEndEditing)),
 let textDidBeginEditingMethod = class_getInstanceMethod(viewClass, #selector(textDidBeginEditing))
 {
 let setFont: @convention(block) (AnyObject, NSFont?) -> Void = { _, font in
 self._font = font
 self.adjustFontSize()
 }
 let getFont: @convention(block) (AnyObject) -> NSFont? = { _ in
 return self._font
 }
 
 let beginEditing: @convention(block) (AnyObject) -> Void = { [weak self] _ in
 guard let self = self else { return }
 self.editingState = .didBegin
 self.editStartString = self.stringValue
 self.previousString = self.stringValue
 }
 
 let endEditing: @convention(block) (AnyObject) -> Void = { [weak self] _ in
 guard let self = self else { return }
 self.editingState = .didEnd
 self.adjustFontSize()
 }
 
 let textEdit: @convention(block) (AnyObject) -> Void = { [weak self] _ in
 guard let self = self else { return }
 if let maxCharCount = self.maximumNumberOfCharacters, self.stringValue.count > maxCharCount {
 if self.previousString.count == self.maximumNumberOfCharacters {
 self.stringValue = self.previousString
 if let editor = self.currentEditor(), editor.selectedRange.location > 0 {
 editor.selectedRange.location -= 1
 }
 } else {
 self.stringValue = String(self.stringValue.prefix(maxCharCount))
 }
 }
 self.editingState = .isEditing
 self.previousString = self.stringValue
 self.adjustFontSize()
 }
 
 class_addMethod(viewSubclass, #selector(getter: NSTextField.font),
 imp_implementationWithBlock(getFont), method_getTypeEncoding(getFontMethod))
 class_addMethod(viewSubclass, #selector(setter: NSTextField.font),
 imp_implementationWithBlock(setFont), method_getTypeEncoding(setFontMethod))
 class_addMethod(viewSubclass, #selector(textDidChange),
 imp_implementationWithBlock(textEdit), method_getTypeEncoding(textDidChangeMethod))
 class_addMethod(viewSubclass, #selector(textDidBeginEditing),
 imp_implementationWithBlock(beginEditing), method_getTypeEncoding(textDidBeginEditingMethod))
 class_addMethod(viewSubclass, #selector(textDidEndEditing),
 imp_implementationWithBlock(endEditing), method_getTypeEncoding(textDidEndEditingMethod))
 }
 objc_registerClassPair(viewSubclass)
 object_setClass(self, viewSubclass)
 }
 }
 */