//
//  EasingAnimation.swift
//  
//
//  Created by Florian Zand on 03.11.23.
//

#if os(macOS) || os(iOS) || os(tvOS)

import Foundation
import FZSwiftUtils

/// An animator that animates a value using an easing function.
public class EasingAnimation<Value: AnimatableProperty>: AnimationProviding, ConfigurableAnimationProviding {
    /// A unique identifier for the animation.
    public let id = UUID()
    
    /// A unique identifier that associates an animation with an grouped animation block.
    public internal(set) var groupUUID: UUID?

    /// The relative priority of the animation.
    public var relativePriority: Int = 0
    
    /// The current state of the animation (`inactive`, `running`, or `ended`).
    public internal(set) var state: AnimationState = .inactive
    
    /// The information used to determine the timing curve for the animation.
    public var timingFunction: TimingFunction = .easeInEaseOut
    
    /// The total duration (in seconds) of the animation.
    public var duration: CGFloat = 0.0
    
    /// A Boolean value indicating whether the animation repeats indefinitely.
    public var repeats: Bool = false {
        didSet {
            guard oldValue != repeats else { return }
            updateAutoreverse()
        }
    }
    
    /// A Boolean value indicating whether the animation is running backwards and forwards (must be combined with ``repeats`` `true`).
    public var autoreverse: Bool = false {
        didSet {
            guard oldValue != autoreverse else { return }
            updateAutoreverse()
        }
    }
    
    func updateAutoreverse() {
        if autoreverse, repeats {
            if isAutoreversed == nil {
                isAutoreversed = false
            }
        } else {
            isAutoreversed = nil
        }
    }
        
    /// A Boolean value indicating whether the animation is running in the reverse direction.
    public var isReversed: Bool = false {
        didSet { guard oldValue != isReversed else { return }
            fractionComplete = 1.0 - fractionComplete
        }
    }
    
    internal var isAutoreversed: Bool? = nil
    
    /// A Boolean value that indicates whether the value returned in ``valueChanged`` when the animation finishes should be integralized to the screen's pixel boundaries. This helps prevent drawing frames between pixels, causing aliasing issues.
    public var integralizeValues: Bool = false
    
    /**
     A Boolean value indicating whether a paused animation scrubs linearly or uses its specified timing information.
     
     The default value of this property is `true`, which causes the animator to use a linear timing function during scrubbing. Setting the property to `false` causes the animator to use its specified timing curve.
     */
    public var scrubsLinearly: Bool = false
    
    /// The completion percentage of the animation.
    public var fractionComplete: CGFloat = 0.0 {
        didSet {
            if (0...1.0).contains(fractionComplete) == false {
                fractionComplete = fractionComplete.clamped(max: 1.0)
            }
                updateValue()
        }
    }
    
    var resolvedFractionComplete: CGFloat {
        return timingFunction.solve(at: fractionComplete, duration: duration)
    }
    
    /// The _current_ value of the animation. This value will change as the animation executes.
    public var value: Value {
        didSet { 
            guard state != .running else { return }
            fromValue = value
        }
    }
    
    /**
     The current target value of the animation.

     You may modify this value while the animation is in-flight to "retarget" to a new target value.
     */
    public var target: Value {
        didSet {
            guard oldValue != target else { return }

          //  fromValue.animatableData.scaled(by: 1.0 - tar)
          //  fromValue.animatableData / target.animatableData
            
            if duration != 0.0, #available(macOS 13.0.0, *) {
              //  Swift.print("VectorElements type", type(of: value.animatableData), (fromValue.animatableData as? any VectorElements) != nil, (fromValue.animatableData as? any VectorElements<CGFloat>) != nil, (fromValue.animatableData as? any VectorElements<Double>) != nil)
                /*
                if let duration = self.newDuration(oldTarget: oldValue, newTarget: self.target) {
                    self.duration = duration
                }
                 */
            }
            
            if state == .running {
                let event = AnimationEvent.retargeted(from: oldValue, to: target)
                completion?(event)
            }
        }
    }
    
    /// Not in use and only used to confirm to `ConfigurableAnimationProviding`.
    internal var velocity: Value {
        get { value }
        set { }
    }
    
    /// The start value of the animation.
    var fromValue: Value
        
    /// The callback block to call when the animation's ``value`` changes as it executes. Use the `currentValue` to drive your application's animations.
    public var valueChanged: ((_ currentValue: Value) -> Void)?

    /// The completion block to call when the animation either finishes, or "re-targets" to a new target value.
    public var completion: ((_ event: AnimationEvent<Value>) -> Void)?

    /**
     Creates a new animation with the specified timing curve and duration, and optionally, an initial and target value.
     While `value` and `target` are optional in the initializer, they must be set to non-nil values before the animation can start.

     - Parameters:
        - timingFunction: The timing curve of the animation.
        - duration: The duration of the animation.
        - value: The initial, starting value of the animation.
        - target: The target value of the animation.
     */
    public init(timingFunction: TimingFunction, duration: CGFloat, value: Value, target: Value) {
        self.value = value
        self.fromValue = value
        self.target = target
        self.duration = duration
        self.timingFunction = timingFunction
    }
    
    internal init(settings: AnimationController.AnimationParameters, value: Value, target: Value, velocity: Value = .zero) {
        self.value = value
        self.fromValue = value
        self.target = target
        self.duration = settings.type.easingDuration ?? 0.25
        self.timingFunction = settings.type.timingFunction ?? .easeInEaseOut
        self.configure(withSettings: settings)
    }
    
    deinit {
        AnimationController.shared.stopPropertyAnimation(self)
    }
    
    /// The item that starts the animation delayed.
    var delayedStart: DispatchWorkItem? = nil
    
    /// Configurates the animation with the specified settings.
    func configure(withSettings settings: AnimationController.AnimationParameters) {
        groupUUID = settings.groupUUID
        if let timingFunction = settings.type.timingFunction {
            self.timingFunction = timingFunction
        }
        if let duration = settings.type.easingDuration {
            self.duration = duration
        }
    }
    
    /// Resets the animation.
    public func reset() {
        state = .inactive
    }
    
    @available(macOS 13.0.0, iOS 16.0.0, tvOS 16.0.0, *)
    func newDuration(oldTarget: Value, newTarget: Value) -> TimeInterval? {
        if let fromValueAnimatable = fromValue.animatableData as? (any VectorElements<CGFloat>), let targetAnimatable = oldTarget.animatableData as? (any VectorElements<CGFloat>), let newTargetAnimated = newTarget.animatableData as? (any VectorElements<CGFloat>) {
            Swift.print("newDuration CGFloat", fromValue, oldTarget, newTarget)

            let range: ClosedRange<[CGFloat]>
            if fromValueAnimatable.elements < targetAnimatable.elements {
                range = fromValueAnimatable.elements...targetAnimatable.elements
            } else {
                range = targetAnimatable.elements...fromValueAnimatable.elements
            }
            
            guard let usableIndex = newTargetAnimated.indices.first(where: { i -> Bool in
                let fractionComplete = newTargetAnimated.elements[i] / (range.upperBound[i] - range.lowerBound[i])
                return !(fractionComplete.doubleValue.isApproximatelyEqual(to: 0.0) || fractionComplete.doubleValue.isApproximatelyEqual(to: 1.0))
            }) else { return nil }
            
            let fractionComplete = newTargetAnimated.elements[usableIndex] / (range.upperBound[usableIndex] - range.lowerBound[usableIndex])
            /*
            if fromValueAnimatable.elements > targetAnimatable.elements {
                fractionComplete = 1.0 - fractionComplete
            }
             */
            let fractionTime = timingFunction.solve(at: fractionComplete.doubleValue, duration: self.duration)
            let newDuration = duration * fractionTime
            Swift.print("newDuration CGFloat end", newDuration, fractionComplete)
            return newDuration
        } else if let fromValueAnimatable = fromValue.animatableData as? (any VectorElements<Double>), let targetAnimatable = oldTarget.animatableData as? (any VectorElements<Double>), let newTargetAnimated = newTarget.animatableData as? (any VectorElements<Double>) {
            Swift.print("newDuration Double", fromValue, oldTarget, newTarget)

            let range: ClosedRange<[Double]>
            if fromValueAnimatable.elements < targetAnimatable.elements {
                range = fromValueAnimatable.elements...targetAnimatable.elements
            } else {
                range = targetAnimatable.elements...fromValueAnimatable.elements
            }

            guard let usableIndex = newTargetAnimated.indices.first(where: { i -> Bool in
                let fractionComplete = newTargetAnimated.elements[i] / (range.upperBound[i] - range.lowerBound[i])
                return !(fractionComplete.doubleValue.isApproximatelyEqual(to: 0.0) || fractionComplete.doubleValue.isApproximatelyEqual(to: 1.0))
            }) else { return nil }
            
            let fractionComplete = newTargetAnimated.elements[usableIndex] / (range.upperBound[usableIndex] - range.lowerBound[usableIndex])
            /*
            if fromValueAnimatable.elements > targetAnimatable.elements {
                fractionComplete = 1.0 - fractionComplete
            }
             */
            let fractionTime = timingFunction.solve(at: fractionComplete.doubleValue, duration: self.duration)

            let newDuration = duration * fractionTime
            Swift.print("newDuration Double end", newDuration, fractionComplete)
            return newDuration
        } else if let fromValueAnimatable = fromValue.animatableData as? (any VectorElements<Float>), let targetAnimatable = oldTarget.animatableData as? (any VectorElements<Float>), let newTargetAnimated = newTarget.animatableData as? (any VectorElements<Float>) {
            Swift.print("newDuration Float", fromValue, oldTarget, newTarget)

            let range: ClosedRange<[Float]>
            if fromValueAnimatable.elements < targetAnimatable.elements {
                range = fromValueAnimatable.elements...targetAnimatable.elements
            } else {
                range = targetAnimatable.elements...fromValueAnimatable.elements
            }
            
            guard let usableIndex = newTargetAnimated.indices.first(where: { i -> Bool in
                let fractionComplete = newTargetAnimated.elements[i] / (range.upperBound[i] - range.lowerBound[i])
                return !(fractionComplete.doubleValue.isApproximatelyEqual(to: 0.0) || fractionComplete.doubleValue.isApproximatelyEqual(to: 1.0))
            }) else { return nil }
            
            let fractionComplete = newTargetAnimated.elements[usableIndex] / (range.upperBound[usableIndex] - range.lowerBound[usableIndex])
            
            let fractionTime = timingFunction.solve(at: fractionComplete.doubleValue, duration: self.duration)
            /*
            if fromValueAnimatable.elements > targetAnimatable.elements {
                fractionComplete = 1.0 - fractionComplete
            }
             */
            let newDuration = duration * fractionTime
            Swift.print("newDuration Float end", newDuration, fractionComplete)
            return newDuration
        }
        Swift.print("newDuration nil", type(of: fromValue))
        return nil
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
                
        let isAnimated = duration > .zero
        
        guard deltaTime > 0.0 else { return }
                
        if isAnimated {
            let deltaTime = deltaTime/2.0 // Why?
            let secondsElapsed = deltaTime/duration
            fractionComplete = isReversed ? (fractionComplete - secondsElapsed) : (fractionComplete + secondsElapsed)
        } else {
            fractionComplete = 1.0
            self.value = target
        }
        
        let animationFinished = (isReversed ? fractionComplete <= 0.0 : fractionComplete >= 1.0) || !isAnimated
        
        if animationFinished {
            if repeats, isAnimated {
                fractionComplete = isReversed ? 1.0 : 0.0
            } else {
                self.value = isReversed ? fromValue : target
            }
        }
        
        let callbackValue = (animationFinished && integralizeValues) ? value.scaledIntegral : value
        valueChanged?(callbackValue)

        if animationFinished, !repeats || !isAnimated {
            stop(at: .current)
        }
    }
    
    func updateValue() {
        if state != .running, scrubsLinearly {
            value = Value(fromValue.animatableData.interpolated(towards: target.animatableData, amount: fractionComplete))
        } else {
            value = Value(fromValue.animatableData.interpolated(towards: target.animatableData, amount: resolvedFractionComplete))
        }
    }
}

extension EasingAnimation: CustomStringConvertible {
    public var description: String {
        """
        EasingAnimation<\(Value.self)>(
            uuid: \(id)
            groupUUID: \(String(describing: groupUUID))
            priority: \(relativePriority)
            state: \(state)
        
            value: \(String(describing: value))
            target: \(String(describing: target))
            from: \(String(describing: fromValue))
            fractionComplete: \(fractionComplete)

            timingFunction: \(timingFunction.name)
            duration: \(duration)
            repeats: \(repeats)
            isReversed: \(isReversed)
            integralizeValues: \(integralizeValues)
            scrubsLinearly: \(scrubsLinearly)

            callback: \(String(describing: valueChanged))
            completion: \(String(describing: completion))
        )
        """
    }
}

#endif