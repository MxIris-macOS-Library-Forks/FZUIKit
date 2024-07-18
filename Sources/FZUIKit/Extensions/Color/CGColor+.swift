//
//  CGColor+.swift
//
//
//  Created by Florian Zand on 16.03.23.
//

import FZSwiftUtils

#if os(macOS)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif
import SwiftUI

public extension CGColor {
    #if canImport(UIKit)
    static var black: CGColor {
        CGColor(red: 0, green: 0, blue: 0, alpha: 1)
    }
    #endif
    
    /// Returns the RGBA (red, green, blue, alpha) components of the color.
    func rgbaComponents() -> RGBAComponents? {
        var color = self
        if color.colorSpace?.model != .rgb, #available(iOS 9.0, macOS 10.11, tvOS 9.0, watchOS 2.0, *) {
            color = color.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil) ?? color
        }
        guard let components = color.components else { return nil }
        switch components.count {
        case 2:
            return RGBAComponents(components[0], components[0], components[0], components[1])
        case 3:
            return RGBAComponents(components[0], components[1], components[2], 1.0)
        case 4:
            return RGBAComponents(components[0], components[1], components[2], components[3])
        default:
            #if os(macOS) || os(iOS) || os(tvOS)
                let ciColor = CIColor(cgColor: color)
                return RGBAComponents(ciColor.red, ciColor.green, ciColor.blue, ciColor.alpha)
            #else
                return nil
            #endif
        }
    }

    /**
     Creates a new color object whose component values are a weighted sum of the current color object and the specified color object's.

     - Parameters:
        - fraction: The amount of the color to blend with the receiver's color. The method converts color and a copy of the receiver to RGB, and then sets each component of the returned color to fraction of color’s value plus 1 – fraction of the receiver’s.
        - color: The color to blend with the receiver's color.

     - Returns: The resulting color object or `nil` if the color couldn't be created.
     */
    func blended(withFraction fraction: CGFloat, of color: CGColor) -> CGColor? {
        guard let c1 = rgbaComponents(), let c2 = color.rgbaComponents() else { return nil }

        let red = c1.red + (fraction * (c2.red - c1.red))
        let green = c1.green + (fraction * (c2.green - c1.green))
        let blue = c1.blue + (fraction * (c2.blue - c1.blue))
        let alpha = c1.alpha + (fraction * (c2.alpha - c1.alpha))

        return CGColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    /// A Boolean value that indicates whether the color is visible (alpha value isn't zero).
    var isVisible: Bool {
        alpha != 0.0
    }

    /**
     Creates a color object with the specified alpha component.

     - Parameter alpha: The opacity value of the new color object, specified as a value from 0.0 to 1.0. Alpha values below 0.0 are interpreted as 0.0, and values above 1.0 are interpreted as 1.0.
     - Returns: The new `CGColor` object.
     */
    func withAlpha(_ alpha: CGFloat) -> CGColor {
        copy(alpha: alpha) ?? self
    }

    /// Returns a color from a pattern image.
    static func fromImage(_ image: NSUIImage) -> CGColor {
        let drawPattern: CGPatternDrawPatternCallback = { info, context in
            let image = Unmanaged<NSUIImage>.fromOpaque(info!).takeUnretainedValue()
            guard let cgImage = image.cgImage else { return }
            context.draw(cgImage, in: CGRect(origin: .zero, size: image.size))
        }

        var callbacks = CGPatternCallbacks(version: 0, drawPattern: drawPattern, releaseInfo: nil)

        let pattern = CGPattern(info: Unmanaged.passRetained(image).toOpaque(),
                                bounds: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height),
                                matrix: CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0),
                                xStep: image.size.width,
                                yStep: image.size.height,
                                tiling: .constantSpacing,
                                isColored: true,
                                callbacks: &callbacks)!

        let space = CGColorSpace(patternBaseSpace: nil)
        let color = CGColor(patternSpace: space!, pattern: pattern, components: [1.0])!
        return color
    }

    #if os(macOS)
        /// Returns a `NSColor` representation of the color.
        var nsColor: NSColor? {
            NSColor(cgColor: self)
        }

        /// Returns a `Color` representation of the color.
        var swiftUI: Color? {
            if let color = self.nsColor {
                return Color(color)
            }
            return nil
        }

    #elseif canImport(UIKit)
        /// Returns a `UIColor` representation of the color.
        var uiColor: UIColor {
            UIColor(cgColor: self)
        }

        /// Returns a `Color` representation of the color.
        var swiftUI: Color {
            Color(uiColor)
        }

        /// The clear color in the Generic gray color space.
        static var clear: CGColor {
            CGColor(gray: 0, alpha: 0)
        }
    #endif

    internal var nsUIColor: NSUIColor? {
        NSUIColor(cgColor: self)
    }
}

extension CGColor: CustomStringConvertible {
    public var description: String {
        CFCopyDescription(self) as String
    }
}
