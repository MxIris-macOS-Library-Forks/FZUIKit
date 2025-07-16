//
//  Color+.swift
//
//
//  Created by Florian Zand on 06.10.22.
//

import SwiftUI

#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

public extension NSUIColor {
    /// A `SwiftUI` representation of the color.
    var swiftUI: Color {
        Color(self)
    }
}

#if os(macOS) || os(iOS) || os(tvOS)
@available(macOS 11.0, iOS 14.0, watchOS 7.0, *)
extension Color {
    /**
     Creates a color that uses the specified block to generate its color data dynamically.
     
     - Parameters:
        - lightColor: The light color.
        - darkColor: The dark color.
     */
    public init(light lightColor: @escaping @autoclosure () -> Color, dark darkColor: @escaping @autoclosure () -> Color) {
        self.init(NSUIColor(light: lightColor().nsUIColor, dark: darkColor().nsUIColor))
    }
    
    /// A random color.
    public static var random: Color {
        NSUIColor.random.swiftUI
    }
    
    /// A random pastel color.
    public static var randomPastel: Color {
        NSUIColor.randomPastel.swiftUI
    }
    
    /**
     Creates a new color from the current mixed with with the specified color and amount.
     
     - Parameters:
        - color: The color to mix.
        - amount: The amount of the color to mix with the current color.
        - colorSpace: The color space mode to be used for mixing the two colors.

     - Returns: The new mixed color.
     */
    public func mixed(with color: Color, by amount: CGFloat = 0.5, using colorSpace: MixingColorSpace = .rgb) -> Color {
        nsUIColor.mixed(withFraction: amount, of: color.nsUIColor, using: .init(rawValue: colorSpace.rawValue)!).swiftUI
    }
    
    /// The color for mixing two colors.
    public enum MixingColorSpace: String, Hashable {
        /// RGB color space.
        case rgb
        /// HSL color space.
        case hsl
        /// HSB color space.
        case hsb
    }
    
    /**
     Tints the color by the specified amount.
     
     - Parameter amount: The amount of tint.
     - Returns: The tinted color object.
     */
    public func tinted(by amount: CGFloat = 0.2) -> Color {
        mixed(with: .white, by: amount)
    }
    
    /**
     Shades the color by the specified amount.
     
     - Parameter amount: The amount of shade.
     - Returns: The shaded color object.
     */
    public func shaded(by amount: CGFloat = 0.2) -> Color {
        mixed(with: .black, by: amount)
    }
    
    /**
     Brightens the color by the specified amount.
     
     - Parameter amount: The amount of brightness.
     - Returns: The brightened color.
     */
    public func lighter(by amount: CGFloat = 0.2) -> Color {
        nsUIColor.lighter(by: amount).swiftUI
    }
    
    /**
     Darkens the color by the specified amount.
     
     - Parameter amount: The amount of darken.
     - Returns: The darkened color.
     */
    public func darkened(by amount: CGFloat = 0.2) -> Color {
        nsUIColor.darkened(by: amount).swiftUI
    }
        
    
    /**
     Saturates the color by the specified amount.
     
     - Parameter amount: The amount of saturation.
     - Returns: The saturated color object.
     */
    public func saturated(by amount: CGFloat = 0.2) -> Color {
        nsUIColor.saturated(by: amount).swiftUI
    }
    
    /**
     Desaturates the color by the specified amount.
     
     - Parameter amount: The amount of desaturation.
     - Returns: The desaturated color object.
     */
    public func desaturated(by amount: CGFloat = 0.2) -> Color {
        nsUIColor.desaturated(by: amount).swiftUI
    }
    
    /**
     Creates and returns the complement of the color object.
     
     This is identical to adjustedHue(180).
     
     - returns: The complement DynamicColor.
     */
    public func complemented() -> Color {
        nsUIColor.complemented().swiftUI
    }
    
    #if os(macOS)
    /// A `NSColor` representation of the color.
    public var nsColor: NSColor {
        NSColor(self)
    }
    #else
    /// A `UIColor` representation of the color.
    public var uiColor: UIColor {
        UIColor(self)
    }
    #endif
    
    var nsUIColor: NSUIColor {
        NSUIColor(self)
    }
    
    /// The mode of grayscaling a color.
    public enum GrayscalingMode: String, Hashable {
        /// XYZ luminance
        case luminance
        /// HSL lightness
        case lightness
        /// RGB average
        case average
        /// HSV value
        case value
    }
    
    /**
     A grayscaled representation of the color.
     
     - Parameter mode: The grayscale mode.
     - Returns: The grayscaled color.
     */
    public func grayscaled(mode: GrayscalingMode = .lightness) -> Color {
        nsUIColor.grayscaled(mode: .init(rawValue: mode.rawValue)!).swiftUI
    }
    
    /**
     Creates and return a color object where the red, green, and blue values are inverted, while the alpha channel is left alone.
     
     - returns: An inverse (negative) of the original color.
     */
    public func inverted() -> Color {
        nsUIColor.inverted().swiftUI
    }
    
    /// A Boolean value indicating whether the color is light.
    public var isLight: Bool {
        nsUIColor.isLight
    }
    
    /// Returns a new color with the specified red component (between `0.0` and `1.0`).
    public func red(_ red: CGFloat) -> Color {
        nsUIColor.withRed(red).swiftUI
    }
    
    /// Returns a new color with the specified alpha component (between `0.0` and `1.0`).
    public func green(_ green: CGFloat) -> Color {
        nsUIColor.withGreen(green).swiftUI
    }
    
    /// Returns a new color with the specified blue component (between `0.0` and `1.0`).
    public func blue(_ blue: CGFloat) -> Color {
        nsUIColor.withBlue(blue).swiftUI
    }
    
    /// Returns a new color with the specified lightness value (between `0.0` and `1.0`).
    public func lightness(_ lightness: CGFloat) -> Color {
        nsUIColor.withLightness(lightness).swiftUI
    }
    
    /// Returns a new color with the specified brightness value (between `0.0` and `1.0`).
    public func brightness(_ brightness: CGFloat) -> Color {
        nsUIColor.withBrightness(brightness).swiftUI
    }
    
    /// Returns a new color with the specified hue value (between `0.0` and `1.0`).
    public func hue(_ hue: CGFloat) -> Color {
        nsUIColor.withHue(hue).swiftUI
    }
    
    /// Returns a new color with the specified saturation value (between `0.0` and `1.0`).
    public func saturation(_ saturation: CGFloat) -> Color {
        nsUIColor.withSaturation(saturation).swiftUI
    }
}
#endif
