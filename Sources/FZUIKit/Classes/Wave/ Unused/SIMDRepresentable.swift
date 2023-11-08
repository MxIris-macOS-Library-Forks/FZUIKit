//
//  SIMDRepresentable.swift
//
//
//  Created by Adam Bell on 8/1/20.
//  Taken from https://github.com/b3ll/Motion

/*
#if os(macOS) || os(iOS) || os(tvOS)

import CoreGraphics
import Foundation
import simd
import FZSwiftUtils
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif
import SwiftUI

/// A protocol that defines supported `SIMD` types that conform to `SIMDRepresentable` and `ApproximateEquatable`.
public protocol SupportedSIMD: SIMD, SIMDRepresentable where Scalar: SupportedScalar {}

/// A protocol that defines supported `SIMD` Scalar types that conform to `FloatingPointInitializable`, `ApproximateEquatable`, and are `RealModule.Real` numbers.
public protocol SupportedScalar: SIMDScalar, FloatingPointInitializable, Decodable, Encodable { }

public protocol FloatingPointInitializable: FloatingPoint & ExpressibleByFloatLiteral & Comparable {
    init(_ value: Float)
    init(_ value: Double)
}

extension Float: FloatingPointInitializable { }
extension Double: FloatingPointInitializable { }
extension CGFloat: FloatingPointInitializable { }

extension Float: SupportedScalar {}
extension Double: SupportedScalar {}

extension SupportedSIMD {
    static func /= (lhs: inout Self, rhs: Scalar)  {
        lhs = lhs / rhs
    }
    
    static func / (lhs: Self, rhs: Scalar) -> Self {
        var lhs = lhs
        (0..<lhs.scalarCount).forEach({
            lhs[$0] = lhs[$0] / rhs
        })
        return lhs
    }
    
    static func *= (lhs: inout Self, rhs: Scalar)  {
        lhs = lhs * rhs
    }

    static func * (lhs: Self, rhs: Scalar) -> Self {
        var lhs = lhs
        (0..<lhs.scalarCount).forEach({
            lhs[$0] = lhs[$0] * rhs
        })
        return lhs
    }
    
    static func += (lhs: inout Self, rhs: Scalar)  {
        lhs = lhs + rhs
    }

    static func + (lhs: Self, rhs: Scalar) -> Self {
        var lhs = lhs
        (0..<lhs.scalarCount).forEach({
            lhs[$0] = lhs[$0] + rhs
        })
        return lhs
    }
}

extension CGFloat: SupportedScalar {
    public typealias SIMDMaskScalar = Int64
    public typealias SIMD2Storage = SIMD2<CGFloat>
    public typealias SIMD4Storage = SIMD4<CGFloat>
    public typealias SIMD8Storage = SIMD8<CGFloat>
    public typealias SIMD16Storage = SIMD16<CGFloat>
    public typealias SIMD32Storage = SIMD32<CGFloat>
    public typealias SIMD64Storage = SIMD64<CGFloat>
}

extension SupportedSIMD where Self:  Comparable, Scalar: SupportedScalar {
    public static func < (lhs: Self, rhs: Self) -> Bool {
            return all(lhs .< rhs)
    }
}

extension SIMD2: SupportedSIMD, Comparable where Scalar: SupportedScalar {}
extension SIMD3: SupportedSIMD, Comparable where Scalar: SupportedScalar {}
extension SIMD4: SupportedSIMD, Comparable where Scalar: SupportedScalar {}
extension SIMD8: SupportedSIMD, Comparable where Scalar: SupportedScalar {}
extension SIMD16: SupportedSIMD, Comparable where Scalar: SupportedScalar {}
extension SIMD32: SupportedSIMD, Comparable where Scalar: SupportedScalar {}
extension SIMD64: SupportedSIMD, Comparable where Scalar: SupportedScalar {}


// MARK: - SIMDRepresentable

/// A protocol that defines how something that can be represented / stored in a `SIMD` type as well as instantiated from said `SIMD` type.
public protocol SIMDRepresentable: Comparable where Self.SIMDType == Self.SIMDType.SIMDType {

    /**
     The `SIMD` type that `self` can be represented by.
      - Description: i.e. `CGPoint` can be stored in `SIMD2<Double>`.
     */
    associatedtype SIMDType: SupportedSIMD = Self

    /// Initializes `self` with a `SIMDType`.
    init(_ simdRepresentation: SIMDType)

    /// Returns a `SIMDType` that represents `self`.
    func simdRepresentation() -> SIMDType

    /// A version of `self` that represents zero.
    static var zero: Self { get }
    
}

extension SIMDRepresentable where SIMDType == Self {
    @inlinable public init(_ simdRepresentation: SIMDType) {
        self = simdRepresentation
    }

    @inlinable public func simdRepresentation() -> Self {
        return self
    }
}

extension SIMDRepresentable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.simdRepresentation() < rhs.simdRepresentation()
    }
}

extension SIMD2: SIMDRepresentable where Scalar: SupportedScalar {}
extension SIMD3: SIMDRepresentable where Scalar: SupportedScalar {}
extension SIMD4: SIMDRepresentable where Scalar: SupportedScalar {}
extension SIMD8: SIMDRepresentable where Scalar: SupportedScalar {}
extension SIMD16: SIMDRepresentable where Scalar: SupportedScalar {}
extension SIMD32: SIMDRepresentable where Scalar: SupportedScalar {}
extension SIMD64: SIMDRepresentable where Scalar: SupportedScalar {}

extension Float: SIMDRepresentable {
    @inlinable public init(_ simdRepresentation: SIMD2<Float>) {
        self = simdRepresentation[0]
    }

    /// `SIMD2` representation of the value.
    @inlinable public func simdRepresentation() -> SIMD2<Float> {
        return [self, 0]
    }
}

extension Double: SIMDRepresentable {
    @inlinable public init(_ simdRepresentation: SIMD2<Double>) {
        self = simdRepresentation[0]
    }

    /// `SIMD2` representation of the value.
    @inlinable public func simdRepresentation() -> SIMD2<Double> {
        return [self, 0]
    }
}

extension CGFloat: SIMDRepresentable {
    @inlinable public init(_ simdRepresentation: SIMD2<CGFloat.NativeType>) {
        self = CGFloat(simdRepresentation[0])
    }

    /// `SIMD2` representation of the value.
    @inlinable public func simdRepresentation() -> SIMD2<CGFloat.NativeType> {
        return [self, 0]
    }
}

extension CGPoint: SIMDRepresentable {
    @inlinable public init(_ simdRepresentation: SIMD2<CGFloat.NativeType>) {
        self.init(x: simdRepresentation[0], y: simdRepresentation[1])
    }

    /// `SIMD2` representation of the value.
    @inlinable public func simdRepresentation() -> SIMD2<CGFloat.NativeType> {
        return [x, y]
    }
}

extension CGSize: SIMDRepresentable {
    @inlinable public init(_ simdRepresentation: SIMD2<CGFloat.NativeType>) {
        self.init(width: simdRepresentation[0], height: simdRepresentation[1])
    }

    /// `SIMD2` representation of the value.
    @inlinable public func simdRepresentation() -> SIMD2<CGFloat.NativeType> {
        return [width, height]
    }
}

extension CGRect: SIMDRepresentable {
    @inlinable public init(_ simdRepresentation: SIMD4<CGFloat.NativeType>) {
        self.init(x: simdRepresentation[0], y: simdRepresentation[1], width: simdRepresentation[2], height: simdRepresentation[3])
    }

    /// `SIMD4` representation of the value.
    @inlinable public func simdRepresentation() -> SIMD4<Double> {
        return [x, y, width, height]
    }
}

extension NSUIColor: SIMDRepresentable {
    /// `SIMD4` representation of the value.
    @inlinable public func simdRepresentation() -> SIMD4<CGFloat.NativeType> {
        let rgba = self.rgbaComponents()
        return [rgba.red, rgba.green, rgba.blue, rgba.alpha]
    }
}

extension SIMDRepresentable where Self: NSUIColor {
    /// Initializes with a `SIMD4`.
    @inlinable public init(_ simdRepresentation: SIMD4<CGFloat.NativeType>) {
        self.init(red: simdRepresentation[0], green: simdRepresentation[1], blue: simdRepresentation[2], alpha: simdRepresentation[3])
    }
}

extension CGAffineTransform: SIMDRepresentable {
    /// Initializes with a `SIMD8`.
    @inlinable public init(_ simdRepresentation: SIMD8<CGFloat.NativeType>) {
        self.init(simdRepresentation[0], simdRepresentation[1], simdRepresentation[2], simdRepresentation[3], simdRepresentation[4], simdRepresentation[5])
    }
    
    /// `SIMD8` representation of the value.
    @inlinable public func simdRepresentation() -> SIMD8<CGFloat.NativeType> {
        return [a, b, c, d, tx, ty, 0, 0]
    }
}

extension CATransform3D: SIMDRepresentable {
    /// Initializes with a `SIMD16`.
    @inlinable public init(_ simdRepresentation: SIMD16<CGFloat.NativeType>) {
        self.init(m11: simdRepresentation[0], m12: simdRepresentation[1], m13: simdRepresentation[2], m14: simdRepresentation[3], m21: simdRepresentation[4], m22: simdRepresentation[5], m23: simdRepresentation[6], m24: simdRepresentation[7], m31: simdRepresentation[8], m32: simdRepresentation[9], m33: simdRepresentation[10], m34: simdRepresentation[11], m41: simdRepresentation[12], m42: simdRepresentation[13], m43: simdRepresentation[14], m44: simdRepresentation[15])
    }
    
    /// `SIMD16` representation of the value.
    @inlinable public func simdRepresentation() -> SIMD16<CGFloat.NativeType> {
        return [m11, m12, m13, m14, m21, m22, m23, m24, m31, m32, m33, m34, m41, m42, m43, m44]
    }
}

extension CGQuaternion: SIMDRepresentable {
    public init(_ simdRepresentation: SIMD4<Double>) {
        self.storage = .init(vector: simdRepresentation)
    }
    
    public func simdRepresentation() -> SIMD4<Double> {
        self.storage.vector
    }
}

extension SIMDRepresentable where Self: CGColor {
    /// Initializes with a `SIMD4`.
    @inlinable public init(_ simdRepresentation: SIMD4<CGFloat.NativeType>) {
        self = NSUIColor(red: simdRepresentation[0], green: simdRepresentation[1], blue: simdRepresentation[2], alpha: simdRepresentation[3]).cgColor as! Self
    }
}

extension CGColor: SIMDRepresentable {
    /// `SIMD4` representation of the value.
    public func simdRepresentation() -> SIMD4<CGFloat.NativeType> {
        let rgba = self.nsUIColor?.rgbaComponents() ?? (red: 0, green: 0, blue: 0, alpha: 0)
        return [rgba.red, rgba.green, rgba.blue, rgba.alpha]
    }
}

/*

/// A protocol that defines how something that can be represented / stored in a `SIMD` type as well as instantiated from said `SIMD` type.
public protocol AnimatableValue: Comparable where Self.SIMDType == Self.SIMDType.SIMDType {
    /**
     The `SIMD` type that `self` can be represented by.
      - Description: i.e. `CGPoint` can be stored in `SIMD2<Double>`.
     */
    associatedtype SIMDType: SupportedSIMD = Self
    
    var animatableData: SIMDType { get set }

    /// A version of `self` that represents zero.
    static var zero: Self { get }
}

extension AnimatableValue where Self: SIMDRepresentable {
    var animatableData: Self.SIMDType {
        get { self.simdRepresentation() }
        set {  }
    }
}

internal protocol ScaledIntegralable {
    var scaledIntegral: Self { get  }
}

extension CGFloat: ScaledIntegralable { }
extension CGSize: ScaledIntegralable { }
extension CGPoint: ScaledIntegralable { }
extension CGRect: ScaledIntegralable { }

public protocol AnimatableSIMD: SIMDRepresentable where Self.SIMDType.Scalar == CGFloat.NativeType { }
extension CGQuaternion: AnimatableSIMD { }
extension CGColor: AnimatableSIMD { }
extension NSUIColor: AnimatableSIMD { }
extension CGFloat: AnimatableSIMD { }
extension CGPoint: AnimatableSIMD { }
extension CGSize: AnimatableSIMD { }
extension CGRect: AnimatableSIMD { }
extension Double: AnimatableSIMD { }
extension CATransform3D: AnimatableSIMD { }
extension CGAffineTransform: AnimatableSIMD { }
extension SIMD2<CGFloat.NativeType>: AnimatableSIMD { }
extension SIMD3<CGFloat.NativeType>: AnimatableSIMD { }
extension SIMD4<CGFloat.NativeType>: AnimatableSIMD { }
extension SIMD8<CGFloat.NativeType>: AnimatableSIMD { }
extension SIMD16<CGFloat.NativeType>: AnimatableSIMD { }
extension SIMD32<CGFloat.NativeType>: AnimatableSIMD { }
extension SIMD64<CGFloat.NativeType>: AnimatableSIMD { }
*/
#endif

*/