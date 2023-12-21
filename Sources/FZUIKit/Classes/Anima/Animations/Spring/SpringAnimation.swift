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

/**
 An animation that animates a value using a physically-modeled spring.
 
 Example usage:
 ```swift
 let springAnimation = SpringAnimation(spring: .bouncy, value: CGPoint(x: 0, y: 0), target: CGPoint(x: 50, y: 100))
 springAnimation.valueChanged = { newValue in
    view.frame.origin = newValue
 }
 springAnimation.start()
 ```
 */
public class SpringAnimation<Value: AnimatableProperty>: ConfigurableAnimationProviding {
    /// A unique identifier for the animation.
    public let id = UUID()
    
    /// A unique identifier that associates an animation with an grouped animation block.
    public internal(set) var groupUUID: UUID?
    
    /// The relative priority of the animation.
    public var relativePriority: Int = 0
    
    /// The current state of the animation (`inactive`, `running`, or `ended`).
    public internal(set) var state: AnimationState = .inactive
    
    /// The delay (in seconds) after which the animations begin.
    public internal(set) var delay: TimeInterval = 0.0

    /// The spring model that determines the animation's motion.
    public var spring: Spring
    
    /// The estimated duration required for the animation to complete, based off its `spring` property.
    public var settlingTime: TimeInterval {
        spring.settlingDuration
    }
    
    /// A Boolean value that indicates whether the value returned in ``valueChanged`` should be integralized to the screen's pixel boundaries when the animation finishes. This helps prevent drawing frames between pixels, causing aliasing issues. 
    public var integralizeValues: Bool = false
    
    /// A Boolean value that indicates whether the animation automatically starts when the ``target`` value changes.
    public var autoStarts: Bool = false
    
    /// A Boolean value indicating whether the animation repeats indefinitely.
    public var repeats: Bool = false
    
    /// A Boolean value indicating whether the animation is running backwards and forwards (must be combined with ``repeats`` `true`).
    public var autoreverse: Bool = false
        
    /// A Boolean value indicating whether the animation is running in the reverse direction.
    public var isReversed: Bool = false

    /// The _current_ value of the animation. This value will change as the animation executes.
    public var value: Value {
        get { Value(_value) }
        set { _value = newValue.animatableData }
    }
    
    var _value: Value.AnimatableData {
        didSet {
            guard state != .running else { return }
            _fromValue = _value
        }
    }

    /**
     The current target value of the animation.

     You may modify this value while the animation is in-flight to "retarget" to a new target value.
     */
    public var target: Value {
        get { Value(_target) }
        set { _target = newValue.animatableData }
    }
    
    var _target: Value.AnimatableData {
        didSet {
            guard oldValue != _target else { return }
            if state == .running {
                runningTime = 0.0
                completion?(.retargeted(from: Value(oldValue), to: target))
            } else if autoStarts, _target != _value {
                start(afterDelay: 0.0)
            }
        }
    }

    /**
     The current velocity of the animation.

     If animating a view's `center` or `frame` with a gesture, you may want to set `velocity` to the gesture's final velocity on touch-up.
     */
    public var velocity: Value {
        get { Value(_velocity) }
        set { _velocity = newValue.animatableData }
    }
    
    var _velocity: Value.AnimatableData {
        didSet {
            guard state != .running else { return }
            _fromVelocity = _velocity
        }
    }

    var fromValue: Value {
        get { Value(_fromValue) }
        set { _fromValue = newValue.animatableData }
    }
    
    var _fromValue: Value.AnimatableData
    
    var fromVelocity: Value {
        get { Value(_fromVelocity) }
        set { _fromVelocity = newValue.animatableData }
    }
    
    var _fromVelocity: Value.AnimatableData

    /// The callback block to call when the animation's ``value`` changes as it executes. Use the `currentValue` to drive your application's animations.
    public var valueChanged: ((_ currentValue: Value) -> Void)?

    /// The completion block to call when the animation either finishes, or "re-targets" to a new target value.
    public var completion: ((_ event: AnimationEvent<Value>) -> Void)?
    
    /// The total running time of the animation.
    var runningTime: TimeInterval = 0.0

    /**
     Creates a new animation with a given ``Spring``, value, target and optional inital velocity.
     
     - Parameters:
        - spring: The spring model that determines the animation's motion.
        - value: The initial, starting value of the animation.
        - target: The target value of the animation.
        - initialVelocity: The initial velocity of the animation.
     */
    public init(spring: Spring, value: Value, target: Value, initialVelocity: Value = .zero) {
        self._value = value.animatableData
        self._target = target.animatableData
        self._velocity = initialVelocity.animatableData
        self.spring = spring
        self._fromValue = _value
        self._fromVelocity = _velocity
    }
    
    deinit {
        delayedStart?.cancel()
        AnimationController.shared.stopAnimation(self)
    }
    
    /// The item that starts the animation delayed.
    var delayedStart: DispatchWorkItem? = nil
    
    /// The animation type.
    let animationType: AnimationController.AnimationParameters.AnimationType = .spring

    /// Configurates the animation with the specified settings.
    func configure(withSettings settings: AnimationController.AnimationParameters) {
        groupUUID = settings.groupID
        spring = settings.configuration.spring ?? spring
        repeats = settings.repeats
        autoreverse = settings.autoreverse
        integralizeValues = settings.integralizeValues
        if settings.resetSpringVelocity {
            _velocity = .zero
        }
        
        if let gestureVelocity = settings.configuration.gestureVelocity {
            if let animation = self as? SpringAnimation<CGPoint> {
                animation.velocity = gestureVelocity
                animation.fromVelocity = gestureVelocity
            } else if let animation = self as? SpringAnimation<CGRect> {
                animation.velocity.origin = gestureVelocity
                animation.fromVelocity.origin = gestureVelocity
            }
        }
    }
        
    /**
     Updates the progress of the animation with the specified delta time.

     - parameter deltaTime: The delta time.
     */
    public func updateAnimation(deltaTime: TimeInterval) {
        state = .running
        
        let isAnimated = spring.response > .zero

        if isAnimated {
            spring.update(value: &_value, velocity: &_velocity, target: isReversed ? _fromValue : _target, deltaTime: deltaTime)
        } else {
            self._value = _target
            velocity = Value.zero
        }
                
        runningTime = runningTime + deltaTime

        let animationFinished = (runningTime >= settlingTime) || !isAnimated
        
        if animationFinished {
            if repeats, isAnimated {
                if autoreverse {
                    isReversed = !isReversed
                }
                _value = isReversed ? _target : _fromValue
                _velocity = isReversed ? .zero : _fromVelocity
            } else {
                _value = _target
            }
            runningTime = 0.0
        }

        let callbackValue = (integralizeValues && animationFinished) ? value.scaledIntegral : value
        valueChanged?(callbackValue)

        if animationFinished, !repeats || !isAnimated {
            stop(at: .current)
        }
    }
    
    public func start(afterDelay delay: TimeInterval = 0.0) {
        precondition(delay >= 0, "Animation start delay must be greater or equal to zero.")
        guard state != .running else { return }
        
        let start = {
            AnimationController.shared.runAnimation(self)
        }
        
        delayedStart?.cancel()
        self.delay = delay

        if delay == .zero {
            start()
        } else {
            let task = DispatchWorkItem {
                start()
            }
            delayedStart = task
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: task)
        }
    }

    public func pause() {
        guard state == .running else { return }
        AnimationController.shared.stopAnimation(self)
        state = .inactive
        delayedStart?.cancel()
        delay = 0.0
    }
    
    public func stop(at position: AnimationPosition, immediately: Bool = true) {
        delayedStart?.cancel()
        delay = 0.0
        if immediately == false {
            switch position {
            case .start:
                target = fromValue
            case .current:
                target = value
            default: break
            }
        } else {
            AnimationController.shared.stopAnimation(self)
            state = .inactive
            switch position {
            case .start:
                value = fromValue
                valueChanged?(value)
            case .end:
                value = target
                valueChanged?(value)
            default: break
            }
            reset()
            velocity = .zero
            completion?(.finished(at: value))
        }
    }
    
    func reset() {
        runningTime = 0.0
        delayedStart?.cancel()
    }
}

extension SpringAnimation: CustomStringConvertible {
    public var description: String {
        """
        SpringAnimation<\(Value.self)>(
            uuid: \(id)
            groupUUID: \(groupUUID?.description ?? "nil")
            priority: \(relativePriority)
            state: \(state)

            value: \(value)
            target: \(target)
            velocity: \(velocity)

            mode: \(spring.response > 0 ? "animated" : "nonAnimated")
            settlingTime: \(settlingTime)
            isReversed: \(isReversed)
            repeats: \(repeats)
            autoreverse: \(autoreverse)
            integralizeValues: \(integralizeValues)
            autoStarts: \(autoStarts)

            callback: \(String(describing: valueChanged))
            completion: \(String(describing: completion))
        )
        """
    }
}
#endif

/*
 if (Math.abs(velocity) < mVelocityThreshold
               && Math.abs(value - getFinalPosition()) < mValueThreshold) {
 
 /**
   * This threshold defines how close the animation value needs to be before the animation can
   * finish. This default value is based on the property being animated, e.g. animations on alpha,
   * scale, translation or rotation would have different thresholds. This value should be small
   * enough to avoid visual glitch of "jumping to the end". But it shouldn't be so small that
   * animations take seconds to finish.
   *
   * @param threshold the difference between the animation value and final spring position that
   *                  is allowed to end the animation when velocity is very low
   */
  void setValueThreshold(double threshold) {
      mValueThreshold = Math.abs(threshold);
      mVelocityThreshold = mValueThreshold * VELOCITY_THRESHOLD_MULTIPLIER;
  }
 
 // This multiplier is used to calculate the velocity threshold given a certain value threshold.
    // The idea is that if it takes >= 1 frame to move the value threshold amount, then the velocity
    // is a reasonable threshold.
    private static final double VELOCITY_THRESHOLD_MULTIPLIER = 1000.0 / 16.0;
 */