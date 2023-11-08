//
//  AnimationState.swift
//
//  Modified by Florian Zand
//  Original: Copyright (c) 2022 Janum Trivedi.
//

#if os(macOS) || os(iOS) || os(tvOS)

/// The current state of an `Animation`.
public enum AnimationState {
    /// The animation is not currently running, but is ready.
    case inactive

    /// The animation is currently active and executing.
    case running

    /// The animation has just stopped, and will be reset to the ``inactive`` state.
    case ended
}

#endif
