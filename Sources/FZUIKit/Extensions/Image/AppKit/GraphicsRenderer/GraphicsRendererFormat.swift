//
//  GraphicsRendererFormat.swift
//  
//
//  Created by Florian Zand on 02.03.25.
//

#if os(macOS)
import Foundation

public protocol GraphicsRendererFormat: AnyObject {
    /// Returns a default instance, configured for the current device.
    static func `default`() -> Self
    
    /// The bounds of the graphics context.
    var bounds: CGRect { get }
}

#endif
