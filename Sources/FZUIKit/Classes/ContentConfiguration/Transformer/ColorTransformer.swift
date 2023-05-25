//
//  NSConfigurationColorTransformer.swift
//
//
//  Created by Florian Zand on 02.09.22.
//

#if os(macOS)
import AppKit
/**
 A transformer that generates a modified output color from an input color.

 A color transformer takes an input color and modifies it to produce a different output color. For example, you might have a color transformer that returns a grayscale or reduced alpha version of the input color.

 Because color transformers can use the same base input color to produce a number of variants of that color, you can create different appearances for different states of your views.
 */
public struct NSConfigurationColorTransformer {
    /// The transform closure of the color transformer.
    public let transform: (NSUIColor) -> NSUIColor
    /// The identifier of the color transformer.
    public let id: String

    /**
     Calls the transform closure of the color transformer.

     Using this syntax, you can call the color transformer type as if it were a closure:
     ```
     let opacityColorTransformer: NSConfigurationColorTransformer = .opacity(0.3)
     let baseColor = NSColor.red
     let modifiedColor = opacityColorTransformer(baseColor)
     ```
     */
    public func callAsFunction(_ input: NSUIColor) -> NSUIColor {
        return transform(input)
    }

    /// Creates a color transformer with the specified closure.
    public init(_ transform: @escaping (NSUIColor) -> NSUIColor) {
        self.transform = transform
        id = UUID().uuidString
    }

    /// Creates a color transformer with the specified closure.
    public init(_ id: String, _ transform: @escaping (NSUIColor) -> NSUIColor) {
        self.transform = transform
        self.id = id
    }

    /// Creates a color transformer that generates a version of the color.with modified opacity.
    public static func opacity(_ opacity: CGFloat) -> Self {
        return Self("opacity: \(opacity)") { $0.withAlphaComponent(opacity.clamped(max: 1.0)) }
    }

    /// Creates a color transformer that generates a version of the color.that is tinted by the amount.
    public static func tinted(by amount: CGFloat = 0.2) -> Self {
        return Self("tinted: \(amount)") { $0.tinted(by: amount) }
    }

    /// Creates a color transformer that generates a version of the color.that is shaded by the amount.
    public static func shaded(by amount: CGFloat = 0.2) -> Self {
        return Self("shaded: \(amount)") { $0.shaded(by: amount) }
    }

    /// Creates a color transformer that generates a version of the color.that is lightened by the amount.
    public static func lighter(by amount: CGFloat = 0.2) -> Self {
        return Self("lighter: \(amount)") { $0.lighter(by: amount) }
    }

    /// Creates a color transformer that generates a version of the color.that is darkened by the amount.
    public static func darkened(by amount: CGFloat = 0.2) -> Self {
        return Self("darkened: \(amount)") { $0.darkened(by: amount) }
    }

    /// Creates a color transformer that generates a version of the color.that is saturated by the amount.
    public static func saturated(by amount: CGFloat = 0.2) -> Self {
        return Self("lighter: \(amount)") { $0.saturated(by: amount) }
    }

    /// Creates a color transformer that generates a version of the color.that is desaturated by the amount.
    public static func desaturated(by amount: CGFloat = 0.2) -> Self {
        return Self("darkened: \(amount)") { $0.desaturated(by: amount) }
    }

    /// Creates a color transformer that generates a monochrome version of the color.
    public static let monochrome: Self = .init("monochrome") { _ in .secondaryLabelColor }

    /// A color transformer that returns the preferred system accent color.
    public static let preferredTint: Self = .init("monochrome") { _ in
        .controlAccentColor
    }

    /// Creates a color transformer that generates a grayscale version of the color.
    public static func grayscaled(mode: NSUIColor.GrayscalingMode = .lightness) -> Self {
        Self("grayscaled: \(mode.rawValue)") { $0.grayscaled(mode: mode) }
    }

    /// A color transformer that returns a color by system effect.
    public static func systemEffect(_ systemEffect: NSColor.SystemEffect) -> Self {
        return Self("systemEffect: \(systemEffect.rawValue)") { $0.withSystemEffect(systemEffect) }
    }
}

extension NSConfigurationColorTransformer: Hashable {
    public static func == (lhs: NSConfigurationColorTransformer, rhs: NSConfigurationColorTransformer) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
#endif

#if canImport(UIKit)
import UIKit
public struct HashableUIConfigurationColorTransformer {
    public let transform: (UIColor) -> UIColor
    public let id: String

    public func callAsFunction(_ input: UIColor) -> UIColor {
        return transform(input)
    }

    public init(_ transform: @escaping (UIColor) -> UIColor) {
        self.transform = transform
        id = UUID().uuidString
    }

    public init(_ id: String, _ transform: @escaping (UIColor) -> UIColor) {
        self.transform = transform
        self.id = id
    }

    public static func opacity(_ opacity: CGFloat) -> Self {
        return Self("opacity: \(opacity)") { $0.withAlphaComponent(opacity.clamped(max: 1.0)) }
    }

    public static let preferredTint: Self = .init("preferredTint", UIConfigurationColorTransformer.preferredTint.transform)

    public static let monochromeTint: Self = .init("monochromeTint", UIConfigurationColorTransformer.monochromeTint.transform)

    public static let grayscale: Self = .init("grayscale", UIConfigurationColorTransformer.grayscale.transform)
}

extension HashableUIConfigurationColorTransformer: Hashable {
    public static func == (lhs: HashableUIConfigurationColorTransformer, rhs: HashableUIConfigurationColorTransformer) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

#endif
