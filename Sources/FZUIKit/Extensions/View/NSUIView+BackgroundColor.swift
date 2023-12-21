//
//  NSUIView+BackgroundColor.swift
//
//
//  Created by Florian Zand on 21.10.22.
//

#if os(macOS) || os(iOS) || os(tvOS)
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

import FZSwiftUtils

/// A protocol for objects with background color.
public protocol BackgroundColorSettable {
    /// The background color of the object.
    var backgroundColor: NSUIColor? { get set }
}

extension NSUIView: BackgroundColorSettable { }

#if os(macOS)
public extension BackgroundColorSettable where Self: NSView {
    /// The background color of the view.
    dynamic var backgroundColor: NSColor? {
        get { self.backgroundColorAnimatable }
        set {
            self.wantsLayer = true
            Self.swizzleAnimationForKey()
            self.dynamicColors.background = newValue
            
            var animatableColor = newValue?.resolvedColor(for: self)
            if animatableColor == nil, self.isProxy() {
                animatableColor = .clear
            }
            
            if self.layer?.backgroundColor?.isVisible == false || self.layer?.backgroundColor == nil {
                self.layer?.backgroundColor = animatableColor?.withAlphaComponent(0.0).cgColor ?? .clear
            }
            self.backgroundColorAnimatable = animatableColor
        }
    }
}

internal extension NSView {
    @objc dynamic var backgroundColorAnimatable: NSColor? {
        get { layer?.backgroundColor?.nsColor }
        set {
            layer?.backgroundColor = newValue?.cgColor
        }
    }
    
    struct DynamicColors {
        var shadow: NSColor? = nil {
            didSet { if shadow?.isDynamic == false { shadow = nil } } }
        var innerShadow: NSColor? = nil {
            didSet { if innerShadow?.isDynamic == false { innerShadow = nil } } }
        var border: NSColor? = nil {
            didSet { if border?.isDynamic == false { border = nil } } }
        var background: NSColor? = nil {
            didSet { if background?.isDynamic == false { background = nil } } }
        
        var needsAppearanceObserver: Bool {
            background != nil || border != nil || shadow != nil || innerShadow != nil
        }
        
        mutating func update(_ keyPath: WritableKeyPath<Self, NSColor?>, cgColor: CGColor?) {
            guard let dynamics = self[keyPath: keyPath]?.dynamicColors else { return }
            if  cgColor != dynamics.light.cgColor && cgColor != dynamics.dark.cgColor {
                self[keyPath: keyPath] = nil
            }
        }
    }
    
    var dynamicColors: DynamicColors {
        get { getAssociatedValue(key: "dynamicColors", object: self, initialValue: DynamicColors() ) }
        set { set(associatedValue: newValue, key: "dynamicColors", object: self)
            setupEffectiveAppearanceObserver()
        }
    }
    
    var _effectiveAppearanceKVO: NSKeyValueObservation? {
        get { getAssociatedValue(key: "_viewEffectiveAppearanceKVO", object: self) }
        set { set(associatedValue: newValue, key: "_viewEffectiveAppearanceKVO", object: self) }
    }

    func setupEffectiveAppearanceObserver() {
        if dynamicColors.needsAppearanceObserver {
            if _effectiveAppearanceKVO == nil {
                _effectiveAppearanceKVO = observeChanges(for: \.effectiveAppearance) { [weak self] _, _ in
                    self?.updateEffectiveColors()
                }
            }
        } else {
            _effectiveAppearanceKVO?.invalidate()
            _effectiveAppearanceKVO = nil
        }
    }
    
    func updateEffectiveColors() {
        dynamicColors.update(\.shadow, cgColor: self.layer?.shadowColor)
        dynamicColors.update(\.background, cgColor: self.layer?.backgroundColor)
        dynamicColors.update(\.border, cgColor: self.layer?.borderColor)
        dynamicColors.update(\.innerShadow, cgColor: self.innerShadowLayer?.shadowColor)
        
        if let color = dynamicColors.shadow?.resolvedColor(for: self).cgColor {
            layer?.shadowColor = color
        }
        if let color = dynamicColors.border?.resolvedColor(for: self).cgColor {
            if let dashedBorderLayer = self.dashedBorderLayer {
                dashedBorderLayer.borderColor = color
            } else {
                layer?.borderColor = color
            }
        }
        if let color = dynamicColors.background?.resolvedColor(for: self).cgColor {
            layer?.backgroundColor = color
        }
        if let color = dynamicColors.innerShadow?.resolvedColor(for: self).cgColor {
            innerShadowLayer?.shadowColor = color
        }

        if dynamicColors.needsAppearanceObserver == false {
            _effectiveAppearanceKVO?.invalidate()
            _effectiveAppearanceKVO = nil
        }
    }
}

#endif
#endif