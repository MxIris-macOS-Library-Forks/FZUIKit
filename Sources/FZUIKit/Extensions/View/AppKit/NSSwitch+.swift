//
//  NSSwitch+.swift
//  
//
//  Created by Florian Zand on 18.07.24.
//

#if os(macOS)

import AppKit
public extension NSSwitch {
    /// Sets the switch’s state.
    @discardableResult
    func state(_ state: StateValue) -> Self {
        self.state = state
        return self
    }
    
    /// Sets the switch’s state.
    @discardableResult
    func state(_ state: Bool) -> Self {
        self.state = state ? .on : .off
        return self
    }
}
#endif
