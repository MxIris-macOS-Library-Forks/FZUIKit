//
//  AnimationProviding.swift
//
//  Modified by Florian Zand
//  Original: Copyright (c) 2022 Janum Trivedi.
//

#if os(macOS) || os(iOS) || os(tvOS)
import Foundation
///  A type that provides an animation.
public protocol AnimationProviding {
    /// A unique identifier for the animation.
    var id: UUID { get }
    
    /// A unique identifier that associates an animation with an grouped animation block.
    var groupUUID: UUID? { get }
    
    /// The relative priority of the animation.
    var relativePriority: Int { get set }
    
    /// The current state of the animation.
    var state: AnimationState { get }
    
    /**
     Updates the progress of the animation with the specified delta time.

     - parameter deltaTime: The delta time.
     */
    func updateAnimation(deltaTime: TimeInterval)
    
    /**
     Starts the animation from its current position with an optional delay.
     
     - parameter delay: The amount of time (measured in seconds) to wait before starting the animation.
     */
    func start(afterDelay delay: TimeInterval)
    
    /// Pauses the animation at the current position.
    func pause()
    
    /**
     Stops the animation at the specified position.
     
     - Parameters:
        - position: The position at which position the animation should stop (``AnimationPosition/current``, ``AnimationPosition/start`` or ``AnimationPosition/end``). The default value is `current`.
        - immediately: A Boolean value that indicates whether the animation should stop immediately at the specified position. The default value is `true`.
     */
    func stop(at position: AnimationPosition, immediately: Bool)
}

extension AnimationProviding {
    public func start(afterDelay delay: TimeInterval = 0.0) {
        precondition(delay >= 0, "`delay` must be greater or equal to zero.")
        guard var animation = self as? (any ConfigurableAnimationProviding) else { return }
        guard state != .running else { return }
        
        let start = {
            AnimationController.shared.runPropertyAnimation(self)
        }
        
        animation.delayedStart?.cancel()

        if delay == .zero {
            start()
        } else {
            let task = DispatchWorkItem {
                start()
            }
            animation.delayedStart = task
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: task)
        }
    }

    public func pause() {
        guard var animation = self as? (any ConfigurableAnimationProviding) else { return }
        guard state == .running else { return }
        animation.state = .inactive
        animation.delayedStart?.cancel()
        AnimationController.shared.stopPropertyAnimation(self)
    }
    
    public func stop(at position: AnimationPosition = .current, immediately: Bool = true) {
        guard state == .running else { return }
        (self as? any ConfigurableAnimationProviding)?.internal_stop(at: position, immediately: immediately)
    }
}

/// An internal extension to `AnimationProviding` used for configurating animations.
internal protocol ConfigurableAnimationProviding<Value>: AnimationProviding {
    associatedtype Value: AnimatableProperty
    var state: AnimationState { get set }
    var value: Value { get set }
    var target: Value { get set }
    var fromValue: Value { get set }
    var completion: ((_ event: AnimationEvent<Value>) -> Void)? { get set }
    var valueChanged: ((_ currentValue: Value) -> Void)? { get set }
    var delayedStart: DispatchWorkItem? { get set }
    func configure(withSettings settings: AnimationController.AnimationParameters)
    func reset()
}

/// An internal extension to `AnimationProviding` for animations with velocity.
internal protocol AnimationVelocityProviding: ConfigurableAnimationProviding {
    var velocity: Value { get set }
}

internal extension AnimationVelocityProviding {
    func setVelocity(_ value: Any, delay: TimeInterval = 0.0) {
        guard let value = value as? Value else { return }
        var animation = self
        
        let velocityUpdate = {
            animation.velocity = value
        }
        
        if delay == .zero {
            velocityUpdate()
        } else {
            let task = DispatchWorkItem {
                velocityUpdate()
            }
            animation.delayedStart = task
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: task)
        }
    }
}

internal extension ConfigurableAnimationProviding {
    func internal_stop(at position: AnimationPosition, immediately: Bool = true) {
        var animation = self
        self.delayedStart?.cancel()
        if immediately == false, isVelocityAnimation {
            switch position {
            case .start:
                animation.target = fromValue
            case .current:
                animation.target = value
            default: break
            }
        } else {
            animation.state = .ended
            switch position {
            case .start:
                animation.value = fromValue
                animation.valueChanged?(value)
            case .end:
                animation.value = target
                animation.valueChanged?(value)
            default: break
            }
            animation.target = value
            (self as? (any AnimationVelocityProviding))?.setVelocity(Value.zero)
            (self as? EasingAnimation<Value>)?.fractionComplete = 1.0
            completion?(.finished(at: value))
            AnimationController.shared.stopPropertyAnimation(self)
        }
    }
    
    func reset() {
        delayedStart?.cancel()
    }
    
    /// A Boolean value that indicates whether the animation can be started.
    var canBeStarted: Bool {
        guard state != .running else { return false }
        if let animation = (self as? DecayAnimation<Value>) {
            return animation._velocity != .zero
        }
        return value != target
    }
    
    /// A Boolean value that indicates whether the animation has a velocity value.
    var isVelocityAnimation: Bool {
        (self as? SpringAnimation<Value>) != nil || (self as? DecayAnimation<Value>) != nil
    }
}
#endif

/*
 public protocol PropertyAnimationProviding<Value>: AnimationProviding {
     associatedtype Value: AnimatableProperty
     /// The current state of the animation.
     var state: AnimationState { get set }
     /// The current value of the animation.
     var value: Value { get set }
     /// The target value of the animation.
     var target: Value { get set }
    /// The start value of the animation.
    var fromValue: Value { get set }
     /// The completion block to call when the animation either finishes, or "re-targets" to a new target value.
     var completion: ((_ event: AnimationEvent<Value>) -> Void)? { get set }
     /// The callback block to call when the animation's ``value`` changes as it executes. Use the `currentValue` to drive your application's animations.
     var valueChanged: ((_ currentValue: Value) -> Void)? { get set }
 }
 */
