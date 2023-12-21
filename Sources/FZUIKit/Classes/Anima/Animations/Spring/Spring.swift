//
//  Spring.swift
//
//  Modified by Florian Zand
//  Original: Copyright (c) 2022 Janum Trivedi.
//

#if os(macOS) || os(iOS) || os(tvOS)
import CoreGraphics
import Foundation
import SwiftUI

/**
 A representation of a spring’s motion.
 
 Example usage:
 ```swift
 let spring = Spring(duration: 0.5, bounce: 0.3)
 let (dampingRatio, stiffness, mass) = (spring.dampingRatio, spring.stiffness, spring.mass)
 // (0.7, 157.9, 1.0)
 ```
 
 You can also use it to query for a value/velocity for a given set of inputs:
 
 ```swift
 let value = spring.value(fromValue: 0.0, toValue: 200.0, initialVelocity: .zero, time: 0.1)
 // 84.66
 
 let velocity = spring.value(fromValue: 0.0, toValue: 200.0, initialVelocity: .zero, time: 0.1)
 // 1141.51
 ```
 */
public struct Spring: Sendable, Hashable {
    // MARK: - Getting spring characteristics
    
    /**
     The amount of oscillation the spring will exhibit (i.e. "springiness").
     
     When dampingRatio is 1, the spring will smoothly decelerate to its final position without oscillating. Damping ratios less than 1 will oscillate more and more before coming to a complete stop.
     */
    public let dampingRatio: Double

    /// The stiffness of the spring, defined as an approximate duration in seconds.
    public let response: Double
    
    /**
     How bouncy the spring is.
     
     A value of `0` indicates no bounces (a critically damped spring), positive values indicate increasing amounts of bounciness up to a maximum of `1.0` (corresponding to undamped oscillation), and negative values indicate overdamped springs with a minimum value of `-1.0`.
     */
    public var bounce: Double {
        1.0 - dampingRatio
    }

    /**
     The spring stiffness coefficient.
     
     Increasing the stiffness reduces the number of oscillations and will reduce the settling duration. Decreasing the stiffness increases the the number of oscillations and will increase the settling duration.
     */
    public let stiffness: Double

    /**
     The mass "attached" to the spring.
     
     The default value of `1.0` rarely needs to be modified. Increasing this value will increase the spring’s effect: the attached object will be subject to more oscillations and greater overshoot, resulting in an increased settling duration. Decreasing the mass will reduce the spring effect: there will be fewer oscillations and a reduced overshoot, resulting in a decreased settling duration.
     */
    public let mass: Double

    /**
     Defines how the spring’s motion should be damped due to the forces of friction.
     
     Reducing this value reduces the energy loss with each oscillation: the spring will overshoot its destination. Increasing the value increases the energy loss with each duration: there will be fewer and smaller oscillations.
     */
    public let damping: Double

    /// The estimated duration required for the spring system to be considered at rest.
    public let settlingDuration: TimeInterval

    
    // MARK: - Creating a spring
    
    /**
     Creates a spring with the specified duration and bounce.
     
     - Parameters:
        - duration: Defines the pace of the spring. This is approximately equal to the settling duration, but for springs with very large bounce values, will be the duration of the period of oscillation for the spring.
        - bounce: How bouncy the spring should be. A value of 0 indicates no bounces (a critically damped spring), positive values indicate increasing amounts of bounciness up to a maximum of 1.0 (corresponding to undamped oscillation), and negative values indicate overdamped springs with a minimum value of -1.0.
     */
    public init(duration: Double = 0.5, bounce: Double = 0.0) {
        self.init(response: duration, dampingRatio: 1.0 - bounce, mass: 1.0)
    }

    /**
     Creates a spring with the given damping ratio and frequency response.

     - Parameters:
        - stiffness: The corresponding spring coefficient. The value affects how quickly the spring animation reaches its target value.  It's an alternative to configuring springs with a ``response`` value.
        - dampingRatio: The amount of oscillation the spring will exhibit (i.e. "springiness"). A value of `1.0` (critically damped) will cause the spring to smoothly reach its target value without any oscillation. Values closer to `0.0` (underdamped) will increase oscillation (and overshoot the target) before settling.
        - mass: The mass "attached" to the spring. The default value of `1.0` rarely needs to be modified.
     */
    public init(stiffness: Double, dampingRatio: Double, mass: Double = 1.0) {
        precondition(stiffness > 0, "The stiffness of the spring has to be > 0")
        precondition(dampingRatio > 0, "The dampingRatio of the spring has to be > 0")

        self.dampingRatio = dampingRatio
        self.stiffness = stiffness
        self.mass = mass
        self.response = Self.response(stiffness: stiffness, mass: mass)
        self.damping = Self.damping(dampingRatio: dampingRatio, response: response, mass: mass)
        self.settlingDuration = Self.settlingTime(dampingRatio: dampingRatio, damping: damping, stiffness: stiffness, mass: mass)
    }
    
    /**
     Creates a spring with the given damping ratio and frequency response.

     - parameters:
        - response: Represents the frequency response of the spring. This value affects how quickly the spring animation reaches its target value. The frequency response is the duration of one period in the spring's undamped system, measured in seconds. Values closer to `0` create a very fast animation, while values closer to `1.0` create a relatively slower animation.
        - dampingRatio: The amount of oscillation the spring will exhibit (i.e. "springiness"). A value of `1.0` (critically damped) will cause the spring to smoothly reach its target value without any oscillation. Values closer to `0.0` (underdamped) will increase oscillation (and overshoot the target) before settling.
        - mass: The mass "attached" to the spring. The default value of `1.0` rarely needs to be modified.
     */
    public init(response: Double, dampingRatio: Double, mass: Double = 1.0) {
        precondition(dampingRatio >= 0, "The dampingRatio of the spring has to be >= 0")
        precondition(response >= 0, "The response of the spring has to be >= 0")
        
        self.dampingRatio = dampingRatio
        self.response = response
        self.mass = mass
        self.stiffness = Self.stiffness(response: response, mass: mass)
        
        let unbandedDamping = Self.damping(dampingRatio: dampingRatio, response: response, mass: mass)
        
      //  self.damping = Rubberband.value(for: unbandedDamping, range: 0 ... 60, interval: 15)
        self.damping = unbandedDamping

        self.settlingDuration = Self.settlingTime(dampingRatio: dampingRatio, damping: damping, stiffness: stiffness, mass: mass)
    }
    
    public init(unresponse response: Double, dampingRatio: Double, mass: Double = 1.0) {
        precondition(dampingRatio >= 0, "The dampingRatio of the spring has to be >= 0")
        precondition(response >= 0, "The response of the spring has to be >= 0")
        
        self.dampingRatio = dampingRatio
        self.response = response
        self.mass = mass
        self.stiffness = Self.stiffness(response: response, mass: mass)
        
        let unbandedDampingCoefficient = Self.damping(dampingRatio: dampingRatio, response: response, mass: mass)
        
        self.damping = unbandedDampingCoefficient
        
        self.settlingDuration = Self.settlingTime(dampingRatio: dampingRatio, damping: damping, stiffness: stiffness, mass: mass)
    }
    
    /*
    /**
     Creates a spring with the specified mass, stiffness, and damping.
     
     - Parameters:
        - stiffness: Specifies that property of the object attached to the end of the spring.
        - damping: The corresponding spring coefficient.
        - mass: Defines how the spring’s motion should be damped due to the forces of friction.
        - allowOverDamping: A value of `true` specifies that over-damping should be allowed when appropriate based on the other inputs, and a value of `false` specifies that such cases should instead be treated as critically damped.
     */
    public init (stiffness: Double, damping: Double, mass: Double = 1.0, allowOverDamping: Bool = false) {
        var dampingRatio = Self.dampingRatio(damping: damping, stiffness: stiffness, mass: mass)
        if allowOverDamping == false, dampingRatio > 1.0 {
            dampingRatio = 1.0
        }
        self.init(stiffness: stiffness, dampingRatio: dampingRatio, mass: mass)
    }
    */
    
    /// Creates a spring from a SwiftUI spring.
    @available(macOS 14.0, iOS 17, tvOS 17, *)
    public init(_ spring: SwiftUI.Spring) {
        dampingRatio = spring.dampingRatio
        response = spring.response
        stiffness = spring.stiffness
        mass = spring.mass
        damping = spring.damping
        settlingDuration = spring.settlingDuration
    }
        
    /**
     Creates a spring with the specified duration and damping ratio.
     
     - Parameters:
        - settlingDuration: The approximate time it will take for the spring to come to rest.
        - dampingRatio: The amount of drag applied as a fraction of the amount needed to produce critical damping.
        - epsilon: The threshold for how small all subsequent values need to be before the spring is considered to have settled. The default value is `0.001`.
     */
    @available(macOS 14.0, iOS 17, tvOS 17, *)
    public init(settlingDuration: TimeInterval, dampingRatio: Double, epsilon: Double = 0.001) {
        let spring = SwiftUI.Spring(settlingDuration: settlingDuration, dampingRatio: dampingRatio, epsilon: epsilon)
        self.init(spring)
    }

    // MARK: - Built-in springs

    /// A reasonable, slightly underdamped spring to use for interactive animations (like dragging an item around).
    public static let interactive = Spring(response: 0.28, dampingRatio: 0.86)
    
    /// A spring with a predefined duration and higher amount of bounce.
    public static let bouncy = Spring.bouncy()
    
    /**
     A spring with a predefined duration and higher amount of bounce that can be tuned.
     
     - Parameters:
        - duration: The perceptual duration, which defines the pace of the spring. This is approximately equal to the settling duration, but for very bouncy springs, will be the duration of the period of oscillation for the spring.
        - extraBounce: How much additional bounciness should be added to the base bounce of 0.3.
     */
    public static func bouncy(duration: Double = 0.5, extraBounce: Double = 0.0) -> Spring {
        Spring(response: duration, dampingRatio: 0.7-extraBounce, mass: 1.0)
    }
    
    /// A smooth spring with a predefined duration and no bounce.
    public static let smooth = Spring.smooth()
    
    /**
     A smooth spring with a predefined duration and no bounce that can be tuned.
     
     - Parameters:
        - duration: The perceptual duration, which defines the pace of the spring. This is approximately equal to the settling duration, but for very bouncy springs, will be the duration of the period of oscillation for the spring.
        - extraBounce: How much additional bounciness should be added to the base bounce of 0.
     */
    public static func smooth(duration: Double = 0.5, extraBounce: Double = 0.0) -> Spring {
        Spring(response: duration, dampingRatio: 1.0-extraBounce, mass: 1.0)
    }
    
    /// A spring with a predefined duration and small amount of bounce that feels more snappy.
    public static let snappy = Spring.snappy()
    
    /**
     A spring with a predefined duration and small amount of bounce that feels more snappy and can be tuned.
     
     - Parameters:
        - duration: The perceptual duration, which defines the pace of the spring. This is approximately equal to the settling duration, but for very bouncy springs, will be the duration of the period of oscillation for the spring.
        - extraBounce: How much additional bounciness should be added to the base bounce of 0.15.
     */
    public static func snappy(duration: Double = 0.5, extraBounce: Double = 0.0) -> Spring {
        return Spring(response: duration, dampingRatio: 0.85-extraBounce, mass: 1.0)
    }
    
    // MARK: - Updating values

    /**
     Updates the current value and velocity of a spring.
     
     - Parameters:
        - value: The current value of the spring.
        - velocity: The current velocity of the spring.
        - target: The target that value is moving towards.
        - deltaTime: The amount of time that has passed since the spring was at the position specified by value.
     */
    public func update<V>(value: inout V, velocity: inout V, target: V, deltaTime: TimeInterval) where V : VectorArithmetic {
        
        let displacement = value - target
        let springForce = displacement * -self.stiffness
        let dampingForce = velocity.scaled(by: self.damping)
        let force = springForce - dampingForce
        let acceleration = force * (1.0 / self.mass)
        
        velocity = velocity + (acceleration * deltaTime)
        value = value + (velocity * deltaTime)
    }
    
    /**
     Updates the current value and velocity of a spring.
     
     - Parameters:
        - value: The current value of the spring.
        - velocity: The current velocity of the spring.
        - target: The target that value is moving towards.
        - deltaTime: The amount of time that has passed since the spring was at the position specified by value.
     */
    public func update<V>(value: inout V, velocity: inout V, target: V, deltaTime: TimeInterval) where V : AnimatableProperty {
        var valueData = value.animatableData
        var velocityData = velocity.animatableData
        
        self.update(value: &valueData, velocity: &velocityData, target: target.animatableData, deltaTime: deltaTime)
        velocity = V(velocityData)
        value = V(valueData)
    }
    
    // MARK: - Getting spring value
    
    /**
     Calculates the value of the spring at a given time given a target amount of change.
     
     - Parameters:
        - target: The target that value is moving towards.
        - initialVelocity: The initial velocity of the spring.
        - time: The amount of time that has passed since start of the spring.
     */
    public func value<V>(target: V, initialVelocity: V, time: TimeInterval) -> V where V: AnimatableProperty {
        var value = V.zero
        var velocity = initialVelocity
        self.update(value: &value, velocity: &velocity, target: target, deltaTime: time)
        return value
    }
    
    /**
     Calculates the value of the spring at a given time given a target amount of change.
     
     - Parameters:
        - target: The target that value is moving towards.
        - initialVelocity: The initial velocity of the spring.
        - time: The amount of time that has passed since start of the spring.
     */
    public func value<V>(target: V, initialVelocity: V, time: TimeInterval) -> V where V: VectorArithmetic {
        var value = V.zero
        var velocity = initialVelocity
        self.update(value: &value, velocity: &velocity, target: target, deltaTime: time)
        return value
    }
    
    /**
     Calculates the value of the spring at a given time for a starting and ending value for the spring to travel.

     - Parameters:
        - fromValue: The starting value of the spring.
        - toValue: The target that value is moving towards.
        - initialVelocity: The initial velocity of the spring.
        - time: The amount of time that has passed since start of the spring.
     */
    public func value<V>(fromValue: V, toValue: V, initialVelocity: V, time: TimeInterval) -> V where V: AnimatableProperty {
        var value = fromValue
        let target = toValue
        var velocity = initialVelocity
        self.update(value: &value, velocity: &velocity, target: target, deltaTime: time)
        return value
    }
    
    /**
     Calculates the value of the spring at a given time for a starting and ending value for the spring to travel.

     - Parameters:
        - fromValue: The starting value of the spring.
        - toValue: The target that value is moving towards.
        - initialVelocity: The initial velocity of the spring.
        - time: The amount of time that has passed since start of the spring.
     */
    public func value<V>(fromValue: V, toValue: V, initialVelocity: V, time: TimeInterval) -> V where V: VectorArithmetic {
        var value = fromValue
        let target = toValue
        var velocity = initialVelocity
        self.update(value: &value, velocity: &velocity, target: target, deltaTime: time)
        return value
    }
    
    // MARK: - Getting spring velocity
    
    /**
     Calculates the velocity of the spring at a given time given a target amount of change.
     
     - Parameters:
        - target: The target that value is moving towards.
        - initialVelocity: The initial velocity of the spring.
        - time: The amount of time that has passed since start of the spring.
     */
    public func velocity<V>(target: V, initialVelocity: V, time: TimeInterval) -> V where V: AnimatableProperty {
        var value = V.zero
        var velocity = initialVelocity
        self.update(value: &value, velocity: &velocity, target: target, deltaTime: time)
        return velocity
    }
    
    /**
     Calculates the velocity of the spring at a given time given a target amount of change.
     
     - Parameters:
        - target: The target that value is moving towards.
        - initialVelocity: The initial velocity of the spring.
        - time: The amount of time that has passed since start of the spring.
     */
    public func velocity<V>(target: V, initialVelocity: V, time: TimeInterval) -> V where V: VectorArithmetic {
        var value = V.zero
        var velocity = initialVelocity
        self.update(value: &value, velocity: &velocity, target: target, deltaTime: time)
        return velocity
    }
    
    /**
     Calculates the velocity of the spring at a given time given a starting and ending value for the spring to travel.
     
     - Parameters:
        - fromValue: The starting value of the spring.
        - toValue: The target that value is moving towards.
        - initialVelocity: The initial velocity of the spring.
        - time: The amount of time that has passed since start of the spring.
     */
    public func velocity<V>(fromValue: V, toValue: V, initialVelocity: V, time: TimeInterval) -> V where V: AnimatableProperty {
        var value = fromValue
        let target = toValue
        var velocity = initialVelocity
        self.update(value: &value, velocity: &velocity, target: target, deltaTime: time)
        return velocity
    }
    
    /**
     Calculates the velocity of the spring at a given time given a starting and ending value for the spring to travel.
     
     - Parameters:
        - fromValue: The starting value of the spring.
        - toValue: The target that value is moving towards.
        - initialVelocity: The initial velocity of the spring.
        - time: The amount of time that has passed since start of the spring.
     */
    public func velocity<V>(fromValue: V, toValue: V, initialVelocity: V, time: TimeInterval) -> V where V: VectorArithmetic {
        var value = fromValue
        let target = toValue
        var velocity = initialVelocity
        self.update(value: &value, velocity: &velocity, target: target, deltaTime: time)
        return velocity
    }

    // MARK: - Spring calculation
    
    static func stiffness(response: Double, mass: Double) -> Double {
        pow(2.0 * .pi / response, 2.0) * mass
    }

    static func response(stiffness: Double, mass: Double) -> Double {
        (2.0 * .pi) / sqrt(stiffness * mass)
    }

    static func damping(dampingRatio: Double, response: Double, mass: Double) -> Double {
        4.0 * .pi * dampingRatio * mass / response
    }
    
    static func dampingRatio(damping: Double, stiffness: Double, mass: Double) -> Double {
        return damping / (2 * sqrt(stiffness * mass))
    }
    
    static func settlingTime(dampingRatio: Double, damping: Double, stiffness: Double, mass: Double) -> Double {
        if #available(macOS 14.0, iOS 17, tvOS 17, *) {
            // SwiftUI`s spring calculates a more precise settling duration.
            return SwiftUI.Spring(mass: mass, stiffness: stiffness, damping: damping, allowOverDamping: true).settlingDuration
        } else {
            return Spring.settlingTime(dampingRatio: dampingRatio, stiffness: stiffness, mass: mass)
        }
    }

    static func settlingTime(dampingRatio: Double, stiffness: Double, mass: Double, epsilon: Double = defaultSettlingPercentage) -> Double {
        if stiffness == .infinity {
            // A non-animated mode (i.e. a `response` of 0) results in a stiffness of infinity, and a settling time of 0.
            // We need the settling time to be non-zero such that the display link stays alive.
            return 1.0
        }

        if dampingRatio >= 1.0 {
            let criticallyDampedSettlingTime = settlingTime(dampingRatio: 1.0 - .ulpOfOne, stiffness: stiffness, mass: mass)
            return criticallyDampedSettlingTime * 1.25
        }

        let undampedNaturalFrequency = Spring.undampedNaturalFrequency(stiffness: stiffness, mass: mass) // ωn
        return (-1 * (log(epsilon) / (dampingRatio * undampedNaturalFrequency)))
    }
    
    static let defaultSettlingPercentage = 0.001
        
    static func undampedNaturalFrequency(stiffness: Double, mass: Double) -> Double {
        return sqrt(stiffness / mass)
    }
    
    static func dampedNaturalFrequency(stiffness: Double, mass: Double, dampingRatio: Double) -> CGFloat {
        return undampedNaturalFrequency(stiffness: stiffness, mass: mass) * sqrt(abs(1 - pow(dampingRatio, 2)))
    }
}

@available(macOS 14.0, iOS 17, tvOS 17, *)
public extension Spring {
    /// The SwiftUI representation of the spring.
    internal var swiftUI: SwiftUI.Spring {
        SwiftUI.Spring.init(mass: mass, stiffness: stiffness, damping: damping, allowOverDamping: true)
    }
    
    // MARK: - Calculating forces and durations
    
    /// Calculates the force upon the spring given a current position, target, and velocity amount of change.
    func force<V: VectorArithmetic>(target: V, position: V, velocitx: V) -> V {
        swiftUI.force(target: target, position: position, velocity: velocitx)
    }
    
    /// Calculates the force upon the spring given a current position, velocity, and divisor from the starting and end values for the spring to travel.
    func force<V: AnimatableProperty>(fromValue: V, toValue: V, position: V, velocity: V) -> V {
        let fromValue = AnimatableProxy(fromValue)
        let toValue = AnimatableProxy(toValue)
        let position = AnimatableProxy(position)
        let velocity = AnimatableProxy(velocity)
        let force = swiftUI.force(fromValue: fromValue, toValue: toValue, position: position, velocity: velocity)
        return V(force.animatableData)
    }
        
    /// The estimated duration required for the spring system to be considered at rest.
    func settlingDuration<V: VectorArithmetic>(target: V, initialVelocity: V = .zero, epsilon: Double = 0.0001) -> Double {
        swiftUI.settlingDuration(target: target, initialVelocity: initialVelocity, epsilon: epsilon)
    }
    
    /// The estimated duration required for the spring system to be considered at rest.
    func settlingDuration<V: AnimatableProperty>(fromValue: V, toValue: V, initialVelocity: V, epsilon: Double = 0.001) -> Double {
        let fromValue = AnimatableProxy(fromValue)
        let toValue = AnimatableProxy(toValue)
        let initialVelocity = AnimatableProxy(initialVelocity)
        return swiftUI.settlingDuration(fromValue: fromValue, toValue: toValue, initialVelocity: initialVelocity, epsilon: epsilon)
    }
}

extension Spring: CustomStringConvertible {
    public var description: String {
        """
        Spring(
            response: \(response)
            dampingRatio: \(dampingRatio)
            mass: \(mass)
        
            settlingDuration: \(String(format: "%.3f", settlingDuration))
            damping: \(damping)
            stiffness: \(String(format: "%.3f", stiffness))
            animated: \(response != .zero)
        )
        """
    }
}

internal struct AnimatableProxy<Value: AnimatableProperty>: Animatable {
    var animatableData: Value.AnimatableData
    
    init(_ value: Value) {
        self.animatableData = value.animatableData
    }
}

#endif