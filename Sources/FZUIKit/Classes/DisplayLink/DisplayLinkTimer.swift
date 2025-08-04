//
//  DisplayLinkTimer.swift
//
//
//  Created by Florian Zand on 02.06.22.
//

#if os(macOS) || os(iOS) || os(tvOS)
import Combine
import CoreGraphics
import Foundation
import FZSwiftUtils
import QuartzCore

/**
 A timer that fires after a certain time interval has elapsed, calling a specified handler.
 
 The timer uses displaylink and is much more precices compared to a regular timer. It also allows changing the timer interval while it's running.
 */
public class DisplayLinkTimer {
    public typealias Action = (DisplayLinkTimer) -> Void
    
    /// The number of seconds between firings of the timer.
    public var timeInterval: TimeDuration = .seconds(0.0)
    
    /// If true, the timer will repeatedly reschedule itself until stopped. If false, the timer will be stopped after it fires.
    public var repeats = true
    
    /// The handler to be called whenever the timer fires.
    public let action: Action
    
    var displayLink: AnyCancellable?
    var timeIntervalSinceLastFire: TimeInterval = 0.0
    var previousTimestamp: TimeInterval = 0.0
    var lastFireDate: Date?
    
    /**
     Returns a repeats timer object with the specified time interval.
     
     - Parameters:
        - timeInterval: The number of seconds between firings of the timer.
        - shouldFire: If true, the timer will fire after Initialization.
     
     - Returns: A new repeats Timer object, configured according to the specified parameters.
     */
    public static func repeats(timeInterval: TimeDuration, shouldFire: Bool = true, action: @escaping Action) -> DisplayLinkTimer {
        DisplayLinkTimer(timeInterval: timeInterval, repeats: true, shouldFire: shouldFire, action: action)
    }
    
    /**
     Returns a repeats timer object with the specified time interval.
     
     - Parameters:
        - timeInterval: The number of seconds between firings of the timer.
        - shouldFire: If true, the timer will fire after Initialization.
     
     - Returns: A new repeats Timer object, configured according to the specified parameters.
     */
    public static func scheduledTimer(repeats: TimeDuration, action: @escaping Action) -> DisplayLinkTimer {
        DisplayLinkTimer(timeInterval: repeats, repeats: true, shouldFire: true, action: action)
    }
    
    /**
     Returns a repeats timer object with the specified time interval.
     
     - Parameters:
        - timeInterval: The number of seconds between firings of the timer.
        - shouldFire: If true, the timer will fire after Initialization.
     
     - Returns: A new repeats Timer object, configured according to the specified parameters.
     */
    public static func scheduledTimer(action: @escaping Action) -> DisplayLinkTimer {
        DisplayLinkTimer(timeInterval: .seconds(1.0), repeats: false, shouldFire: true, action: action)
    }
    
    /**
     Initializes a timer object with the specified time interval.
     
     - Parameters:
        - timeInterval: The duration between firings of the timer.
        - repeats: If true, the timer will repeatedly reschedule itself until stopped. If false, the timer will be stopped after it fires.
        - shouldFire: If true, the timer will fire after Initialization.
     
     - Returns: A new Timer object, configured according to the specified parameters.
     */
    public init(timeInterval: TimeDuration, repeats: Bool, shouldFire: Bool = true, action: @escaping Action) {
        self.timeInterval = timeInterval
        self.repeats = repeats
        self.action = action
        if shouldFire {
            fire()
        }
    }
    
    /// The date when the timer will fire next.
    public var nextFireDate: Date? {
        lastFireDate?.addingTimeInterval(timeInterval.seconds)
    }
    
    /// A Boolean value indicating whether the timer is running.
    public var isRunning: Bool {
        displayLink != nil
    }
    
    var _isRunning: Bool = false
    
    /// Causes the timer's action to be called.
    public func fire() {
        if isRunning == false {
            previousTimestamp = 0.0
            timeIntervalSinceLastFire = 0.0
            lastFireDate = Date()
            _isRunning = false
            displayLink = DisplayLinkPublisher.shared.sink { [weak self] frame in
                if let self = self {
                    if self._isRunning == false {
                        self._isRunning = true
                        self.previousTimestamp = frame.timestamp
                    }
                    let timeIntervalCount = frame.timestamp - self.previousTimestamp
                    self.timeIntervalSinceLastFire += timeIntervalCount
                    self.previousTimestamp = frame.timestamp
                    if self.timeIntervalSinceLastFire > self.timeInterval.seconds {
                        self.timeIntervalSinceLastFire = 0.0
                        self.lastFireDate = Date()
                        self.action(self)
                        if !self.repeats {
                            self.stop()
                        }
                    }
                }
            }
        }
    }
    
    /// Stops the timer from firing.
    public func stop() {
        displayLink?.cancel()
        lastFireDate = nil
        timeIntervalSinceLastFire = 0.0
        previousTimestamp = 0.0
    }
    
    deinit {
        displayLink?.cancel()
        displayLink = nil
    }
}

#endif

/*
 extension DisplayLinkTimer {
 /// The bpm (beats per minute)  firings of the timer.
 var bpm: CGFloat {
 get {
 return timeInterval * 6
 }
 set {
 timeInterval = 6 / newValue
 }
 }
 }
 */
