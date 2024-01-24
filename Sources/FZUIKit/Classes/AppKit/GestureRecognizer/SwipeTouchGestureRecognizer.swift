//
//  SwipeTouchGestureRecognizer.swift
//
//
//  Created by Florian Zand on 22.09.22.
//

#if os(macOS)
    import AppKit

    /// A discrete gesture recognizer that interprets swiping gestures in one or more directions.
    open class SwipeTouchGestureRecognizer: NSGestureRecognizer {
        
        /// The permitted direction of the swipe for this gesture recognizer.
        public struct Direction: OptionSet {
            public let rawValue: UInt
            /// The touch or touches swipe to the right.
            public static let right = Direction(rawValue: 1 << 0)
            /// The touch or touches swipe to the left.
            public static let left = Direction(rawValue: 1 << 1)
            /// The touch or touches swipe upward.
            public static let up = Direction(rawValue: 1 << 2)
            /// The touch or touches swipe downward.
            public static let down = Direction(rawValue: 1 << 3)

            /// Creates a swipe direction structure with the specified raw value.
            public init(rawValue: UInt) {
                self.rawValue = rawValue
            }
        }

        /**
         The permitted direction of the swipe for this gesture recognizer.

         The default direction is right. See descriptions of `SwipeTouchGestureRecognizer.Direction` constants for more information.
         */
        open var direction: Direction = .right

        /// The number of swipes required to detect the swipe.
        open var numberOfTouchesRequired: Int = 2

        var twoFingersTouches: [String: NSTouch]?
        let kSwipeMinimumLength: Float = 0.12

        override public init(target: Any?, action: Selector?) {
            super.init(target: target, action: action)
        }

        @available(*, unavailable)
        required public init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override open func touchesBegan(with event: NSEvent) {
            super.touchesBegan(with: event)
            if event.type == .gesture {
                let touches = event.touches(matching: .any, in: view)
                if touches.count == numberOfTouchesRequired {
                    twoFingersTouches = [:]
                    touches.forEach {
                        self.twoFingersTouches?[$0.identity.description] = $0
                    }
                }
            }
        }

        override open func touchesMoved(with event: NSEvent) {
            super.touchesMoved(with: event)
            let touches = event.touches(matching: .moved, in: view)
            guard touches.count == numberOfTouchesRequired else { return }
            guard let beginTouches = twoFingersTouches else { return }

            var xMagnitudes: [Float] = []
            var yMagnitudes: [Float] = []
            for touch in touches {
                guard let beginTouch = beginTouches[touch.identity.description] else { continue }
                let xMagnitude = Float(touch.normalizedPosition.x - beginTouch.normalizedPosition.x)
                let yMagnitude = Float(touch.normalizedPosition.y - beginTouch.normalizedPosition.y)
                xMagnitudes.append(xMagnitude)
                yMagnitudes.append(yMagnitude)
            }

            let xSum = xMagnitudes.reduce(0, +)
            let ySum = yMagnitudes.reduce(0, +)

            // See if absolute sum is long enough to be considered a complete gesture
            let xAbsoluteSum = fabsf(xSum)
            let yAbsoluteSum = fabsf(ySum)

            var happened = false
            
            let previousDirection = direction
            self.direction = []

            // Handle the actual swipe
            if xAbsoluteSum >= kSwipeMinimumLength {
                happened = true
                // This might need to be > (i am using flipped coordinates)
                if xSum > 0 {
                    self.direction.insert(.right)
                } else {
                    self.direction.insert(.left)
                }
            }
            if yAbsoluteSum >= kSwipeMinimumLength {
                happened = true
                if ySum > 0 {
                    self.direction.insert(.up)
                } else {
                    self.direction.insert(.down)
                }
            }
            if happened {
                twoFingersTouches = nil
            }
            if previousDirection != direction {
                sendAction()
            }
        }
        
        func sendAction() {
            guard let action = action, let target = target else { return }
            _ = target.perform(action, with: self)
        }
    }

    extension SwipeTouchGestureRecognizer: TargetActionProtocol {}
    public extension SwipeTouchGestureRecognizer {
        convenience init(action: @escaping ActionBlock) {
            self.init()
            actionBlock = action
        }
    }
#endif
