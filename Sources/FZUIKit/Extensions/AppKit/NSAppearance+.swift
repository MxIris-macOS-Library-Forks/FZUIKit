//
//  NSAppearance+.swift
//  
//
//  Created by Florian Zand on 06.08.22.
//

#if os(macOS)

import AppKit
import Foundation

public extension NSAppearance {
    /// Returns a aqua appearance.
    static var aqua: NSAppearance {
        return NSAppearance(named: .aqua)!
    }

    /// Returns a dark aqua appearance.
    static var darkAqua: NSAppearance {
        return NSAppearance(named: .darkAqua)!
    }
    
    /// Returns a vibrant light appearance.
    static var vibrantLight: NSAppearance {
        return NSAppearance(named: .vibrantLight)!
    }
    
    /// Returns a vibrant dark appearance.
    static var vibrantDark: NSAppearance {
        return NSAppearance(named: .vibrantDark)!
    }
    
    /// Returns a high-contrast version of the standard light system appearance.
    static var accessibilityHighContrastAqua: NSAppearance {
        return NSAppearance(named: .accessibilityHighContrastAqua)!
    }
    
    /// Returns a high-contrast version of the standard dark system appearance.
    static var accessibilityHighContrastDarkAqua: NSAppearance {
        return NSAppearance(named: .accessibilityHighContrastDarkAqua)!
    }
    
    /// Returns a high-contrast version of the dark vibrant system appearance.
    static var accessibilityHighContrastVibrantDark: NSAppearance {
        return NSAppearance(named: .accessibilityHighContrastVibrantDark)!
    }
    
    /// Returns a high-contrast version of the light vibrant system appearance.
    static var accessibilityHighContrastVibrantLight: NSAppearance {
        return NSAppearance(named: .accessibilityHighContrastVibrantLight)!
    }
}

#endif