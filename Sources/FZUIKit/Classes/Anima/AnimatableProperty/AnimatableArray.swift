//
//  AnimatableArrray.swift
//
//
//  Created by Florian Zand on 15.10.21.
//

import Foundation
import SwiftUI
import Accelerate
import FZSwiftUtils

/**
 An array of animatable values, which is itself animatable.
  
 It's recommended to use `Double` values for much faster calculation in animations.
 */
public struct AnimatableArray<Element: VectorArithmetic & AdditiveArithmetic> {
    var elements: [Element] = []

    /// Creates a new, empty array.
    public init() {}

    /**
     Creates a new array with the given elements from an array literal.

     - Parameter elements: The elements for the new array..
     */
    public init(arrayLiteral elements: Element...) {
        self.elements = elements
    }
    
    /**
     Creates a new array containing the elements of a sequence.

     - Parameter elements: The sequence of elements for the new array.
     */
    public init<S>(_ elements: S) where S: Sequence, Element == S.Element {
        self.elements = .init(elements)
    }

    /**
     Creates a new array containing the specified number of a single, repeated value.
     
     - Parameters
        -  repeatedValue: The element to repeat.
        -  count: The number of times to repeat the value passed in the repeating parameter. count must be zero or greater.
     */
    public init(repeating repeatedValue: Element, count: Int) {
        elements = .init(repeating: repeatedValue, count: count)
    }
    
    /**
     Accesses the element at the specified position.
     
     - Parameter index: The position of the element to access. index must be greater than or equal to startIndex and less than endIndex.
     */
    public subscript(index: Int) -> Element {
        get {  return elements[index] }
        set {  elements[index] = newValue }
    }
    
    public subscript(safe safeIndex: Index) -> Element? {
        get {
            if isEmpty == false, safeIndex < count {
                return self[safeIndex]
            }
            return nil
        }
        set {
            if isEmpty == false, safeIndex < count, let newValue = newValue {
                self[safeIndex] = newValue
            }
        }
    }
    
    /**
     Accesses a contiguous subrange of the array’s elements.
     
     - Parameter bounds: A range of integers. The bounds of the range must be valid indices of the array.
     */
    public subscript(bounds: Range<Int>) -> ArraySlice<Element> {
        get { return elements[bounds] }
        set { elements[bounds] = newValue }
    }
    
    
    /// The position of the first element in a nonempty array.
    public var startIndex: Int {
        return elements.startIndex
    }

    /// The array’s “past the end” position—that is, the position one greater than the last valid subscript argument.
    public var endIndex: Int {
        return elements.endIndex
    }

    /// The number of elements in the array.
    public var count: Int {
        return elements.count
    }
    
    /// A Boolean value indicating whether the collection is empty.
    public var isEmpty: Bool {
        return elements.isEmpty
    }
    
    /// The first element of the collection.
    public var first: Element? {
        return elements.first
    }
    
    /// The last element of the collection.
    public var last: Element? {
        return elements.last
    }
    
    /**
     Replaces the specified subrange of elements with the given collection.
     
     - Parameters
        -  subrange: The subrange of the collection to replace. The bounds of the range must be valid indices of the collection.
        -  newElements: The new elements to add to the collection.
     */
    public mutating func replaceSubrange<C, R>(_ subrange: R, with newElements: C)
        where C: Collection, R: RangeExpression, Element == C.Element, Int == R.Bound {
        elements.replaceSubrange(subrange, with: newElements)
    }
}

extension AnimatableArray: MutableCollection, RangeReplaceableCollection, RandomAccessCollection, BidirectionalCollection { }
extension AnimatableArray: ExpressibleByArrayLiteral { }
extension AnimatableArray: Sendable where Element: Sendable { }
extension AnimatableArray: Encodable where Element: Encodable { }
extension AnimatableArray: Decodable where Element: Decodable { }

extension AnimatableArray: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    public var customMirror: Mirror {
        return elements.customMirror
    }

    public var debugDescription: String {
        return elements.debugDescription
    }

    public var description: String {
        return elements.description
    }
}

extension AnimatableArray: Hashable where Element: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(elements)
    }
}

extension AnimatableArray: VectorArithmetic & AdditiveArithmetic {
    
    public static func + (lhs: AnimatableArray, rhs: AnimatableArray) -> AnimatableArray {
        let count = Swift.min(lhs.count, rhs.count)
        if let _lhs = lhs as? AnimatableArray<Double>, let _rhs = rhs as? AnimatableArray<Double> {
            return AnimatableArray<Double>(vDSP.add(_lhs[0..<count], _rhs[0..<count])) as! Self
        }
        var lhs = lhs
        for index in 0..<count {
            lhs[index] += rhs[index]
        }
        return lhs
    }
    
    public static func += (lhs: inout AnimatableArray, rhs: AnimatableArray) {
        lhs = lhs + rhs
    }
    
    public static func - (lhs: AnimatableArray, rhs: AnimatableArray) -> AnimatableArray {
        let count = Swift.min(lhs.count, rhs.count)
        if let _lhs = lhs as? AnimatableArray<Double>, let _rhs = rhs as? AnimatableArray<Double> {
            return AnimatableArray<Double>(vDSP.subtract(_lhs[0..<count], _rhs[0..<count])) as! Self
        }
        var lhs = lhs
        for index in 0..<count {
            lhs[index] += rhs[index]
        }
        return lhs
    }
    
    public static func -= (lhs: inout Self, rhs: Self) {
        lhs = lhs - rhs
    }
    
    public mutating func scale(by rhs: Double) {
        if let _self = self as? AnimatableArray<Double> {
            self.elements = vDSP.multiply(rhs, _self.elements) as! [Element]
        } else {
            for index in startIndex..<endIndex {
                self[index].scale(by: rhs)
            }
        }
    }
    
    public var magnitudeSquared: Double {
        if let _self = self as? AnimatableArray<Double> {
            return vDSP.sum(vDSP.multiply(_self.elements, _self.elements))
        }
       return reduce(into: 0.0) { (result, new) in
            result += new.magnitudeSquared
        }
    }

    public static var zero: Self { .init() }
}

extension AnimatableArray: MultiplicativeArithmetic where Element: MultiplicativeArithmetic {
    public static func / (lhs: Self, rhs: Self) -> Self {
        let count = Swift.min(lhs.count, rhs.count)
        if let lhs = lhs as? AnimatableArray<Double>, let rhs = rhs as? AnimatableArray<Double> {
            return AnimatableArray<Double>(vDSP.divide(lhs[0..<count], rhs[0..<count])) as! Self
        }
        if let lhs = lhs as? AnimatableArray<Float>, let rhs = rhs as? AnimatableArray<Float> {
            return AnimatableArray<Float>(vDSP.divide(lhs[0..<count], rhs[0..<count])) as! Self
        }

        var array = Self()
        for i in 0..<count {
            array.append(lhs[i] / rhs[i])
        }
        return array
    }
    
    public static func /= (lhs: inout AnimatableArray, rhs: AnimatableArray) {
        lhs = lhs / rhs
    }

    public static func * (lhs: Self, rhs: Self) -> Self {
        let count = Swift.min(lhs.count, rhs.count)
        if let lhs = lhs as? AnimatableArray<Double>, let rhs = rhs as? AnimatableArray<Double> {
            return AnimatableArray<Double>(vDSP.multiply(lhs[0..<count], rhs[0..<count])) as! Self
        }
        if let lhs = lhs as? AnimatableArray<Float>, let rhs = rhs as? AnimatableArray<Float> {
            return AnimatableArray<Float>(vDSP.multiply(lhs[0..<count], rhs[0..<count])) as! Self
        }
        var array = Self()
        for i in 0..<count {
            array.append(lhs[i] * rhs[i])
        }
        return array
    }
    
    public static func *= (lhs: inout AnimatableArray, rhs: AnimatableArray) {
        lhs = lhs * rhs
    }
}

extension AnimatableArray: Comparable where Element: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        for (leftElement, rightElement) in zip(lhs.elements, rhs.elements) {
            if leftElement < rightElement {
                return true
            } else if leftElement > rightElement {
                return false
            }
        }
        return lhs.count < rhs.count
    }
}

protocol SupportedScalar { }
extension Float: SupportedScalar {}
extension Double: SupportedScalar {}

protocol SupportedCollection {
    associatedtype Element: SupportedScalar
    var elements: [Element] { get set }
    func add(other: Self) -> Self
}

extension SupportedCollection where Element == Float {
    func add(other: Self) -> Self {
        return self
    }
}