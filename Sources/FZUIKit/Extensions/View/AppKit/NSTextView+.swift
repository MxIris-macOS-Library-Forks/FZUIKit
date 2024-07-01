//
//  NSTextView+.swift
//
//  Parts taken from:
//  Taken from: https://github.com/boinx/BXUIKit
//  Copyright ©2017-2018 Peter Baumgartner. All rights reserved.
//
//  Created by Florian Zand on 19.10.21.
//

#if os(macOS)

    import AppKit
import FZSwiftUtils

    extension NSTextView {
        /// Sets the Boolean value that indicates whether the text view draws its background.
        @discardableResult
        public func drawsBackground(_ draws: Bool) -> Self {
            drawsBackground = draws
            return self
        }
        
        /// The attributed string.
        public var attributedString: NSAttributedString! {
            set {
                let len = textStorage?.length ?? 0
                let range = NSRange(location: 0, length: len)
                textStorage?.replaceCharacters(in: range, with: newValue)
            }
            get { textStorage?.copy() as? NSAttributedString }
        }
        
        /// The ranges of characters selected in the text view.
        public var selectedStringRanges: [Range<String.Index>] {
            get { selectedRanges.compactMap({$0.rangeValue}).compactMap({ Range($0, in: string) }) }
            set { selectedRanges = newValue.compactMap({NSRange($0, in: string).nsValue}) }
        }
        
        /// The fonts of the selected text.
        public var selectionFonts: [NSFont] {
            get {
                guard let textStorage = textStorage else { return [] }
                var fonts: [NSFont] = []
                for range in selectedRanges.compactMap({$0.rangeValue}) {
                    textStorage.enumerateAttribute(.font, in: range, using: { font, range, fu in
                        if let font = font as? NSFont {
                            fonts.append(font)
                        }
                    })
                }
                return fonts
            }
            set {
                guard let textStorage = textStorage else { return }
                for (index, range) in selectedRanges.compactMap({$0.rangeValue}).enumerated() {
                    if let font = newValue[safe: index] ?? newValue.last {
                        textStorage.addAttribute(.font, value: font, range: range)
                    }
                }
            }
        }
        
        var selectionHasStrikethrough: Bool {
            guard let textStorage = textStorage else { return false }
            var selectionHasStrikethrough = false
            for range in selectedRanges.compactMap({$0.rangeValue}) {
                textStorage.enumerateAttribute(.strikethroughStyle, in: range, using: { strikethrough, range, fu in
                    if let strikethrough = strikethrough as? Int, strikethrough != 0 {
                        selectionHasStrikethrough = true
                    }
                })
            }
            return selectionHasStrikethrough
        }
        
        var selectionHasUnderline: Bool {
            guard let textStorage = textStorage else { return false }
            var selectionHasUnderline = false
            for range in selectedRanges.compactMap({$0.rangeValue}) {
                textStorage.enumerateAttribute(.underlineStyle, in: range, using: { underline, range, fu in
                    if let underline = underline as? Int, underline != 0 {
                        selectionHasUnderline = true
                    }
                })
            }
            return selectionHasUnderline
        }
        
        var typingIsUnderline: Bool {
            if let underline = typingAttributes[.underlineStyle] as? Int, underline != 0 {
                return true
            }
            return false
        }
        
        var typingIsStrikethrough: Bool {
            if let underline = typingAttributes[.strikethroughStyle] as? Int, underline != 0 {
                return true
            }
            return false
        }
        
        /// Selects all text.
        public func selectAll() {
            select(string)
        }
        
        /// Selects the specified string.
        public func select(_ string: String) {
            guard let range = string.range(of: string), !selectedStringRanges.contains(range) else { return }
            selectedStringRanges.append(range)
        }
        
        /// Selects the specified range.
        public func select(_ range: Range<String.Index>) {
            guard !selectedStringRanges.contains(range) else { return }
            selectedStringRanges.append(range)
        }
        
        /// Selects the specified range.
        public func select(_ range: ClosedRange<String.Index>) {
            select(range.lowerBound..<range.upperBound)
        }
        
        var _delegate: TextViewDelegate? {
            get { getAssociatedValue("_delegate", initialValue: nil) }
            set { setAssociatedValue(newValue, key: "_delegate") }
        }
        
        /// A Boolean value that indicates whether the text view should stop editing when the user clicks outside the text view.
        public var endEditingOnOutsideClick: Bool {
            get { getAssociatedValue("endEditingOnOutsideClick", initialValue: false) }
            set {
                guard newValue != endEditingOnOutsideClick else { return }
                setAssociatedValue(newValue, key: "endEditingOnOutsideClick")
                setupMouseMonitor()
            }
        }
        
        var mouseDownMonitor: NSEvent.Monitor? {
            get { getAssociatedValue("mouseDownMonitor", initialValue: nil) }
            set { setAssociatedValue(newValue, key: "mouseDownMonitor") }
        }

        func setupMouseMonitor() {
            if endEditingOnOutsideClick {
                if mouseDownMonitor == nil {
                    mouseDownMonitor = NSEvent.monitorLocal(.leftMouseDown) { [weak self] event in
                        guard let self = self, self.endEditingOnOutsideClick, self.isFirstResponder else { return event }
                        if self.bounds.contains(event.location(in: self)) == false {
                            self.resignFirstResponding()
                        }
                        return event
                    }
                }
            } else {
                mouseDownMonitor = nil
            }
        }
        
        /// The action to perform when the user presses the escape key.
        public enum EscapeKeyAction {
            /// No action.
            case none
            /// Ends editing the text.
            case endEditing
            /// Ends editing the text and resets it to the the state before editing.
            case endEditingAndReset
            
            var needsSwizzling: Bool {
                switch self {
                case .none: return false
                default: return true
                }
            }
        }

        /// The action to perform when the user presses the enter key.
        public enum EnterKeyAction {
            /// No action.
            case none
            /// Ends editing the text.
            case endEditing
            
            var needsSwizzling: Bool {
                switch self {
                case .none: return false
                case .endEditing: return true
                }
            }
        }
        
        /// The action to perform when the user presses the enter key.
        public var actionOnEnterKeyDown: EnterKeyAction {
            get { getAssociatedValue("actionOnEnterKeyDown", initialValue: .none) }
            set {
                guard actionOnEnterKeyDown != newValue else { return }
                setAssociatedValue(newValue, key: "actionOnEnterKeyDown")
                swizzleTextView()
            }
        }

        /// The action to perform when the user presses the escape key.
        public var actionOnEscapeKeyDown: EscapeKeyAction {
            get { getAssociatedValue("actionOnEscapeKeyDown", initialValue: .none) }
            set {
                guard actionOnEscapeKeyDown != newValue else { return }
                setAssociatedValue(newValue, key: "actionOnEscapeKeyDown")
                swizzleTextView()
            }
        }
        
        var needsSwizzling: Bool {
            actionOnEscapeKeyDown.needsSwizzling || actionOnEnterKeyDown.needsSwizzling
        }
        
        func swizzleTextView() {
            if needsSwizzling {
                if _delegate == nil {
                    _delegate = TextViewDelegate(self)
                }
            } else {
                _delegate = nil
            }
        }
        
        class TextViewDelegate: NSObject, NSTextViewDelegate {
            var string: String
            
            func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
                switch commandSelector {
                case #selector(NSControl.cancelOperation(_:)):
                    switch textView.actionOnEscapeKeyDown {
                    case .endEditingAndReset:
                        textView.string = string
                        textView.resignFirstResponding()
                        return true
                    case .endEditing:
                        textView.resignFirstResponding()
                    case .none:
                        break
                    }
                case #selector(NSControl.insertNewline(_:)):
                    switch textView.actionOnEnterKeyDown {
                    case .endEditing:
                        textView.resignFirstResponding()
                    case .none: break
                    }
                default: break
                }
                return true
            }
            
            func textDidBeginEditing(_ notification: Notification) {
                string = (notification.object as? NSText)?.string ?? ""
            }
            
            func textDidChange(_ notification: Notification) {
                
            }
            
            func textDidEndEditing(_ notification: Notification) {
                
            }
            
            init(_ textView: NSTextView) {
                self.string = textView.string
                super.init()
                textView.delegate = self
            }
        }
    }

#endif
