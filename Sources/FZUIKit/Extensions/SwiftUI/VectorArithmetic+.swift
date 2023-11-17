//
//  VectorArithmetic+.swift
//
//
//  Created by Florian Zand on 20.10.23.
//

import Foundation
import SwiftUI

extension VectorArithmetic {
    public static func * (lhs: inout Self, rhs: Double)  {
        lhs.scale(by: rhs)
    }
    
    public static func * (lhs: Self, rhs: Double) -> Self {
        return lhs.scaled(by: rhs)
    }
    
    public static func / (lhs: inout Self, rhs: Double)  {
        lhs.scale(by: 1.0 / rhs)
    }
    
    public static func / (lhs: Self, rhs: Double) -> Self {
        return lhs.scaled(by: 1.0 / rhs)
    }
    
    public static prefix func - (lhs: Self) -> Self {
        lhs * -1
    }
}

/*
extension VectorElements {
    var indices: Range<Int> {
        0..<elements.count
    }
}

extension CGFloat: VectorElements {
    var elements: [CGFloat] {
        get { [self] }
        set { self = newValue.first ?? self }
    }
}

extension Double: VectorElements {
    var elements: [Double] {
        get { [self] }
        set { self = newValue.first ?? self }
    }
}

extension Float: VectorElements {
    var elements: [Float] {
        get { [self] }
        set { self = newValue.first ?? self }
    }
}

protocol VectorElements<Element> {
    associatedtype Element: DoubleConvertable & DivisionArithmetic & VectorArithmetic & AdditiveArithmetic & Comparable
    var indices: Range<Int> { get }
    var elements: [Element] { get set }
}

extension AnimatablePair: VectorElements where First: DoubleConvertable & VectorArithmetic & Comparable & DivisionArithmetic, First == Second {
    typealias Element = First
    var elements: [First] {
        get { [first, second] }
        set {
            if let first = newValue[safe: 0] {
                self.first = first
            }
            
            if let second = newValue[safe: 1] {
                self.second = second
            }
        }
    }
}

extension AnimatableArray: VectorElements where Element: DivisionArithmetic & Comparable & DoubleConvertable { }

protocol DivisionArithmetic: VectorArithmetic & AdditiveArithmetic {
    static func / (lhs: Self, rhs: Self) -> Self
    static func /= (lhs: inout Self, rhs: Self)
}

extension CGFloat: DivisionArithmetic { }
extension Double: DivisionArithmetic { }
extension Float: DivisionArithmetic { }

protocol DoubleConvertable: FloatingPoint & ExpressibleByFloatLiteral & Comparable {
    var doubleValue: Double { get }
}

extension Float: DoubleConvertable {
    var doubleValue: Double {
        Double(self)
    }
}
extension Double: DoubleConvertable {
    var doubleValue: Double {
        Double(self)
    }
}
extension CGFloat: DoubleConvertable {
    var doubleValue: Double {
        Double(self)
    }
}
*/


// public typealias AnimatableVector = Array<Double>

/*
public typealias AnimatableVector = AnimatableArray<Double>

public typealias FF = Fun
public struct Fun {
    public static func -= (lhs: inout Fun, rhs: Fun) {
    }
}

public typealias AnimatableArray = BaseArray<VectorArithmetic>

public class AnimatableArray<Element>: BaseArray<Element>, AdditiveArithmetic & VectorArithmetic where Element: AdditiveArithmetic & VectorArithmetic {
    public static func -= (lhs: inout Self, rhs: Self) {
        if var _lhs = lhs as? AnimatableArray<Double>, let _rhs = rhs as? AnimatableArray<Double> {
            let count = Swift.min(_lhs.count, _rhs.count)
            vDSP.subtract(_lhs[0..<count], _rhs[0..<count], result: &_lhs[0..<count])
            lhs = _lhs as! Self
        } else {
            let range = (lhs.startIndex..<lhs.endIndex)
                .clamped(to: rhs.startIndex..<rhs.endIndex)
            for index in range {
                lhs[index] -= rhs[index]
            }
        }
    }
    
    public static func - (lhs: AnimatableArray, rhs: AnimatableArray) -> AnimatableArray {
        if let _lhs = lhs as? AnimatableArray<Double>, let _rhs = rhs as? AnimatableArray<Double> {
            let count = Swift.min(_lhs.count, _rhs.count)
            return AnimatableArray<Double>(vDSP.subtract(_lhs[0..<count], _rhs[0..<count])) as! Self
        }
        var lhs = lhs
        lhs -= rhs
        return lhs
    }
    
    public static func += (lhs: inout AnimatableArray, rhs: AnimatableArray) {
        if var _lhs = lhs as? AnimatableArray<Double>, let _rhs = rhs as? AnimatableArray<Double> {
            let count = Swift.min(_lhs.count, _rhs.count)
            vDSP.add(_lhs[0..<count], _rhs[0..<count], result: &_lhs[0..<count])
            lhs = _lhs as! Self
        } else {
            let range = (lhs.startIndex..<lhs.endIndex)
                .clamped(to: rhs.startIndex..<rhs.endIndex)
            for index in range {
                lhs[index] += rhs[index]
            }
        }
    }
    
    public static func + (lhs: AnimatableArray, rhs: AnimatableArray) -> AnimatableArray {
        if let _lhs = lhs as? AnimatableArray<Double>, let _rhs = rhs as? AnimatableArray<Double> {
            let count = Swift.min(_lhs.count, _rhs.count)
            return AnimatableArray<Double>(vDSP.add(_lhs[0..<count], _rhs[0..<count])) as! Self
        }
        var lhs = lhs
        lhs += rhs
        return lhs
    }
    
    public static func + (lhs: AnimatableArray, rhs: AnimatableArray) -> AnimatableArray where Element == Double {
        Swift.print("here")
        let count = Swift.min(lhs.count, rhs.count)
        return AnimatableArray(vDSP.add(lhs[0..<count], rhs[0..<count]))
    }
    
    public func scale(by rhs: Double) {
        if let _self = self as? AnimatableArray<Double> {
            self.removeAll()
            self.append(contentsOf:  vDSP.multiply(rhs, _self.collect()) as! [Element])
        } else {
            for index in startIndex..<endIndex {
                self[index].scale(by: rhs)
            }
        }
    }
    
    public var magnitudeSquared: Double {
        if let _self = self as? AnimatableArray<Double> {
            return vDSP.sum(vDSP.multiply(_self.collect(), _self.collect()))
        }
       return reduce(into: 0.0) { (result, new) in
            result += new.magnitudeSquared
        }
    }

    public static var zero: Self { .init() }
}
*/
/*
extension Array: AdditiveArithmetic & VectorArithmetic where Element: VectorArithmetic  {
    public static func -= (lhs: inout Self, rhs: Self) {
        if var _lhs = lhs as? AnimatableVector, let _rhs = rhs as? AnimatableVector {
            let count = Swift.min(_lhs.count, _rhs.count)
            vDSP.subtract(_lhs[0..<count], _rhs[0..<count], result: &_lhs[0..<count])
            lhs = _lhs as! Self
        } else {
            let range = (lhs.startIndex..<lhs.endIndex)
                .clamped(to: rhs.startIndex..<rhs.endIndex)
            for index in range {
                lhs[index] -= rhs[index]
            }
        }
    }

    public static func - (lhs: Self, rhs: Self) -> Self {
        if let _lhs = lhs as? AnimatableVector, let _rhs = rhs as? AnimatableVector {
            let count = Swift.min(_lhs.count, _rhs.count)
            return vDSP.subtract(_lhs[0..<count], _rhs[0..<count]) as! Self
        }
        var lhs = lhs
        lhs -= rhs
        return lhs
    }

    public static func += (lhs: inout Self, rhs: Self) {
        if var _lhs = lhs as? AnimatableVector, let _rhs = rhs as? AnimatableVector {
            let count = Swift.min(_lhs.count, _rhs.count)
            vDSP.add(_lhs[0..<count], _rhs[0..<count], result: &_lhs[0..<count])
            lhs = _lhs as! Self
        } else {
            let range = (lhs.startIndex..<lhs.endIndex)
                .clamped(to: rhs.startIndex..<rhs.endIndex)
            for index in range {
                lhs[index] += rhs[index]
            }
        }
    }

    public static func + (lhs: Self, rhs: Self) -> Self {
        if let _lhs = lhs as? AnimatableVector, let _rhs = rhs as? AnimatableVector {
            let count = Swift.min(_lhs.count, _rhs.count)
            return vDSP.add(_lhs[0..<count], _rhs[0..<count]) as! Self
        }
        var lhs = lhs
        lhs += rhs
        return lhs
    }

    mutating public func scale(by rhs: Double) {
        if let _self = self as? AnimatableVector {
            self = vDSP.multiply(rhs, _self) as! Self
        } else {
            for index in startIndex..<endIndex {
                self[index].scale(by: rhs)
            }
        }
    }

    public var magnitudeSquared: Double {
        if let _self = self as? AnimatableVector {
           return vDSP.sum(vDSP.multiply(_self, _self))
        }
       return reduce(into: 0.0) { (result, new) in
            result += new.magnitudeSquared
        }
    }

    public static var zero: Self { .init() }
}
 */

/*
extension VectorArithmetic where Self == Array<Double> {
    public static func + (lhs: Self, rhs: Self) -> Self {
        Swift.print("hhh")
        let count = Swift.min(lhs.count, rhs.count)
        return vDSP.add(lhs[0..<count], rhs[0..<count])
    }
    
    public static func += (lhs: inout Self, rhs: Self) {
        Swift.print("hhh")
        let count = Swift.min(lhs.count, rhs.count)
        vDSP.add(lhs[0..<count], rhs[0..<count], result: &lhs[0..<count])
    }
    
    public static func - (lhs: Self, rhs: Self) -> Self {
        Swift.print("hhh")
        let count = Swift.min(lhs.count, rhs.count)
        return vDSP.subtract(lhs[0..<count], rhs[0..<count])
    }

    public static func -= (lhs: inout Self, rhs: Self) {
        Swift.print("hhh")

        let count = Swift.min(lhs.count, rhs.count)
        vDSP.subtract(lhs[0..<count], rhs[0..<count], result: &lhs[0..<count])
    }

    public mutating func scale(by rhs: Double) {
        self = vDSP.multiply(rhs, self)
    }

    public var magnitudeSquared: Double {
        vDSP.sum(vDSP.multiply(self, self))
    }
}

extension VectorArithmetic where Self == Array<Float> {
    public static func + (lhs: Self, rhs: Self) -> Self {
        let count = Swift.min(lhs.count, rhs.count)
        return vDSP.add(lhs[0..<count], rhs[0..<count])
    }
    
    public static func += (lhs: inout Self, rhs: Self) {
        let count = Swift.min(lhs.count, rhs.count)
        vDSP.add(lhs[0..<count], rhs[0..<count], result: &lhs[0..<count])
    }
    
    public static func - (lhs: Self, rhs: Self) -> Self {
        let count = Swift.min(lhs.count, rhs.count)
        return vDSP.subtract(lhs[0..<count], rhs[0..<count])
    }

    public static func -= (lhs: inout Self, rhs: Self) {
        let count = Swift.min(lhs.count, rhs.count)
        vDSP.subtract(lhs[0..<count], rhs[0..<count], result: &lhs[0..<count])
    }


    public mutating func scale(by rhs: Float) {
        self = vDSP.multiply(rhs, self)
    }

    public var magnitudeSquared: Float {
        vDSP.sum(vDSP.multiply(self, self))
    }
}
 */

/*
 extension AnimatableVector {
     public static func * (lhs: Self, rhs: Self) -> Self {
         vDSP.multiply(lhs, rhs)
     }
     
     public static func *= (lhs: inout Self, rhs: Self) {
         let count = Swift.min(lhs.count, rhs.count)
         vDSP.multiply(lhs[0..<count], rhs[0..<count], result: &lhs[0..<count])
     }
     
     public static func / (lhs: Self, rhs: Self) -> Self {
         vDSP.divide(lhs, rhs)
     }
     
     public static func /= (lhs: inout Self, rhs: Self) {
         let count = Swift.min(lhs.count, rhs.count)
         vDSP.divide(lhs[0..<count], rhs[0..<count], result: &lhs[0..<count])
     }
 }
 

 */
