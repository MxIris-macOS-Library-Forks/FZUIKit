//
//  Animation.swift
//
//  Modified by Florian Zand
//  Original: Copyright (c) 2022 Janum Trivedi.
//

#if os(macOS) || os(iOS) || os(tvOS)
import Foundation
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// An animator that animates a value using a physically-modeled spring.
public class SpringAnimation<Value: AnimatableProperty>: AnimationProviding, ConfigurableAnimationProviding, VelocityAnimationProviding {
    /// A unique identifier for the animation.
    public let id = UUID()
    
    /// A unique identifier that associates an animation with an grouped animation block.
    public internal(set) var groupUUID: UUID?
    
    /// The relative priority of the animation.
    public var relativePriority: Int = 0

    /// The current state of the animation (`inactive`, `running`, or `ended`).
    public internal(set) var state: AnimationState = .inactive {
        didSet {
            switch (oldValue, state) {
            case (.inactive, .running):
                startTime = .now

            default:
                break
            }
        }
    }

    /// The spring model that determines the animation's motion.
    public var spring: Spring
    
    /**
     How long the animation will take to complete, based off its `spring` property.

     - Note: This is useful for debugging purposes only. Do not use `settlingTime` to determine the animation's progress.
     */
    public var settlingTime: TimeInterval {
        spring.settlingDuration
    }
    
    /// A Boolean value that indicates whether the value returned in ``valueChanged`` when the animation finishes should be integralized to the screen's pixel boundaries. This helps prevent drawing frames between pixels, causing aliasing issues.
    public var integralizeValues: Bool = false
    
    /// Determines if the animation is stopped upon reaching `target`. If set to `false`,  any changes to the target value will be animated.
    public var stopsOnCompletion: Bool = true

    /// The _current_ value of the animation. This value will change as the animation executes.
    public var value: Value

    /**
     The current target value of the animation.

     You may modify this value while the animation is in-flight to "retarget" to a new target value.
     */
    public var target: Value {
        didSet {
            guard oldValue != target else {
                return
            }

            if state == .running {
                startTime = .now

                let event = AnimationEvent.retargeted(from: oldValue, to: target)
                completion?(event)
            }
        }
    }

    /**
     The current velocity of the animation.

     If animating a view's `center` or `frame` with a gesture, you may want to set `velocity` to the gesture's final velocity on touch-up.
     */
    public var velocity: Value
    
    internal var fromValue: Value

    /// The callback block to call when the animation's ``value`` changes as it executes. Use the `currentValue` to drive your application's animations.
    public var valueChanged: ((_ currentValue: Value) -> Void)?

    /// The completion block to call when the animation either finishes, or "re-targets" to a new target value.
    public var completion: ((_ event: AnimationEvent<Value>) -> Void)?
    
    /// The start time of the animation.
    var startTime: TimeInterval?
    
    /// The total running time of the animation.
    var runningTime: TimeInterval? {
        if let startTime = startTime {
            return (.now - startTime)
        } else {
            return nil
        }
    }
    
    /**
     Creates a new animation with a ``Spring/snappy`` spring, and optionally, an initial and target value.
     While `value` and `target` are optional in the initializer, they must be set to non-nil values before the animation can start.

     - Parameters:
        - value: The initial, starting value of the animation.
        - target: The target value of the animation.
     */
    public init(value: Value, target: Value, velocity: Value = .zero) {
        self.value = value
        self.target = target
        self.velocity = velocity
        self.spring = .snappy
        self.fromValue = value
    }

    /**
     Creates a new animation with a given ``Spring``, and optionally, an initial and target value.
     While `value` and `target` are optional in the initializer, they must be set to non-nil values before the animation can start.

     - Parameters:
        - spring: The spring model that determines the animation's motion.
        - value: The initial, starting value of the animation.
        - target: The target value of the animation.
     */
    public init(spring: Spring, value: Value, target: Value, velocity: Value = .zero) {
        self.value = value
        self.target = target
        self.velocity = velocity
        self.spring = spring
        self.fromValue = value
    }
    
    internal init(settings: AnimationController.AnimationParameters, value: Value, target: Value, velocity: Value = .zero) {
        self.value = value
        self.target = target
        self.velocity = velocity
        self.spring = settings.type.spring ?? .smooth
        self.fromValue = value
        self.configure(withSettings: settings)
    }
    
    deinit {
        AnimationController.shared.stopPropertyAnimation(self)
    }
    
    /// The item that starts the animation delayed.
    internal var delayedStart: DispatchWorkItem? = nil

    /// Configurates the animation with the specified settings.
    internal func configure(withSettings settings: AnimationController.AnimationParameters) {
        groupUUID = settings.groupUUID
        if let spring = settings.type.spring {
            self.spring = spring
        }
        if let gestureVelocity = settings.type.gestureVelocity {
            (self as? SpringAnimation<CGRect>)?.velocity.origin = gestureVelocity
            (self as? SpringAnimation<CGPoint>)?.velocity = gestureVelocity
        }
    }

    /// Resets the animation.
    public func reset() {
        startTime = nil
        velocity = .zero
        state = .inactive
    }
        
    /**
     Updates the progress of the animation with the specified delta time.

     - parameter deltaTime: The delta time.
     */
    public func updateAnimation(deltaTime: TimeInterval) {
        guard value != target else {
            state = .inactive
            return
        }

        state = .running

        guard let runningTime = runningTime else {
            fatalError("Found a nil `runningTime` even though the animation's state is \(state)")
        }


        let isAnimated = spring.response > .zero

        if isAnimated {
            spring.update(value: &value, velocity: &velocity, target: target, deltaTime: deltaTime)
        } else {
            self.value = target
            velocity = Value.zero
        }

        let animationFinished = (runningTime >= settlingTime) || !isAnimated
        
        /*
        if animationFinished == false, let epsilon = self.epsilon, let value = self.value?.animatableValue as? AnimatableVector, let target = self.target?.animatableValue as? AnimatableVector {
            let val = value.isApproximatelyEqual(to: target, epsilon: epsilon)
            Swift.print("isApproximatelyEqual", val)
            animationFinished = val
        }
         */
        
        if animationFinished {
            value = target
        }

        let callbackValue = (animationFinished && integralizeValues) ? value.scaledIntegral : value
        valueChanged?(callbackValue)

        if animationFinished {
            stop(at: .current)
        }
    }
}

extension SpringAnimation: CustomStringConvertible {
    public var description: String {
        """
        SpringAnimation<\(Value.self)>(
            uuid: \(id)
            groupUUID: \(String(describing: groupUUID))
            priority: \(relativePriority)
            state: \(state)

            value: \(String(describing: value))
            target: \(String(describing: target))
            velocity: \(String(describing: velocity))

            mode: \(spring.response > 0 ? "animated" : "nonAnimated")
            settlingTime: \(settlingTime)
            integralizeValues: \(integralizeValues)
            stopsOnCompletion: \(stopsOnCompletion)

            callback: \(String(describing: valueChanged))
            completion: \(String(describing: completion))
        )
        """
    }
}
#endif