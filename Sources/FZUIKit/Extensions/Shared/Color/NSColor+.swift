//
//  NSColor+.swift
//
//
//  Created by Florian Zand on 16.03.23.
//

#if os(macOS)
import AppKit
import FZSwiftUtils

public extension NSColor {
    /**
     Creates a dynamic catalog color with the specified light and dark color.
     
     - Parameters:
        - name: The name of the color.
        - light: The light color.
        - dark: The dark color.
     */
    convenience init(name: NSColor.Name? = nil,
                     light lightModeColor: @escaping @autoclosure () -> NSColor,
                     dark darkModeColor: @escaping @autoclosure () -> NSColor)
    {
        self.init(name: name, dynamicProvider: { appereance in
            if appereance.name == .vibrantLight || appereance.name == .aqua {
                return lightModeColor()
            } else {
                return darkModeColor()
            }
        })
    }

    /// Returns the dynamic light and dark colors.
    var dynamicColors: (light: NSColor, dark: NSColor) {
        let light = self.resolvedColor(for: .aqua)
        let dark = self.resolvedColor(for: .darkAqua)
        return (light, dark)
    }
    
    /**
     Generates the resolved color for the specified appearance.
     
     - Parameters appearance: The appearance of the resolved color.
     - Returns: A `NSColor` for the appearance.
     */
    func resolvedColor(for appearance: NSAppearance? = nil) -> NSColor {
      //  resolvedColor(for: appearance, colorSpace: nil) ?? self
        var color = self
        if #available(macOS 11.0, *) {
            let appearance = appearance ?? .currentDrawing()
            appearance.performAsCurrentDrawingAppearance {
                if self.isDynamic {
                    let dynamics = self.dynamicColors
                    if let light = dynamics.light.usingColorSpace(.sRGB), let dark = dynamics.dark.usingColorSpace(.sRGB) {
                        color = NSColor(name: self.colorNameComponent, light: light, dark: dark)
                    }
                } else {
                    color = self.usingColorSpace(.sRGB) ?? self
                }
            }
        } else {
            let appearance = appearance ?? .current
            let current = NSAppearance.current
            NSAppearance.current = appearance
            if self.isDynamic {
                let dynamics = self.dynamicColors
                if let light = dynamics.light.usingColorSpace(colorSpace), let dark = dynamics.dark.usingColorSpace(colorSpace) {
                    color = NSColor(name: self.colorNameComponent, light: light, dark: dark)
                }
            } else {
                color = usingColorSpace(.sRGB) ?? self
            }
            NSAppearance.current = current
        }
        return color
    }
    
    /**
     Generates the resolved color for the specified appearance and color space. If color space is `nil`, the color resolves to the first compatible color space.
     
     - Parameters:
        - appearance: The appearance of the resolved color.
        - colorSpace: The color space of the resolved color. If `nil`, the first compatible color space is used.
     - Returns: A color for the appearance and color space.
     */
    func resolvedColor(for appearance: NSAppearance? = nil, colorSpace: NSColorSpace?) -> NSColor? {
        var color: NSColor? = nil
        if type == .catalog {
            if let colorSpace = colorSpace {
                if #available(macOS 11.0, *) {
                    let appearance = appearance ?? .currentDrawing()
                    appearance.performAsCurrentDrawingAppearance {
                        if self.isDynamic {
                            let dynamics = self.dynamicColors
                            if let light = dynamics.light.usingColorSpace(colorSpace), let dark = dynamics.dark.usingColorSpace(colorSpace) {
                                color = NSColor(name: self.colorNameComponent, light: light, dark: dark)
                            }
                        } else {
                            color = self.usingColorSpace(colorSpace)
                        }
                    }
                } else {
                    let appearance = appearance ?? .current
                    let current = NSAppearance.current
                    NSAppearance.current = appearance
                    if self.isDynamic {
                        let dynamics = self.dynamicColors
                        if let light = dynamics.light.usingColorSpace(colorSpace), let dark = dynamics.dark.usingColorSpace(colorSpace) {
                            color = NSColor(name: self.colorNameComponent, light: light, dark: dark)
                        }
                    } else {
                        color = usingColorSpace(colorSpace)
                    }
                    NSAppearance.current = current
                }
            } else {
                let supportedColorSpaces: [NSColorSpace] = [.sRGB, .deviceRGB, .extendedSRGB, .genericRGB, .adobeRGB1998, .displayP3]
                for supportedColorSpace in supportedColorSpaces {
                    if let color = resolvedColor(for: appearance, colorSpace: supportedColorSpace) {
                        return color
                    }
                }
            }
        }
        return color
    }
    
    /**
     Generates the resolved color for the specified window,
     
     It uses the window's `effectiveAppearance` for resolving the color.
     
     - Parameters window: The window for the resolved color.
     - Returns: A resolved color for the window.
     */
    func resolvedColor(for window: NSWindow) -> NSColor {
        self.resolvedColor(for: window.effectiveAppearance)
    }

    /// Creates a new color object with a supported color space.
    func withSupportedColorSpace() -> NSColor? {
        let supportedColorSpaces: [NSColorSpace] = [.sRGB, .deviceRGB, .extendedSRGB, .genericRGB, .adobeRGB1998, .displayP3]
        let needsConverting: Bool
        if (self.isDynamic) {
            needsConverting = true
        } else {
            needsConverting = (supportedColorSpaces.contains(self.colorSpace) == false)
        }
        
        if (needsConverting) {
            for supportedColorSpace in supportedColorSpaces {
                if self.isDynamic {
                    let dynamics = self.dynamicColors
                    if let light = dynamics.light.usingColorSpace(supportedColorSpace), let dark = dynamics.dark.usingColorSpace(supportedColorSpace) {
                        return NSColor(name: self.colorNameComponent, light: light, dark: dark)
                    }
                } else if let supportedColor = usingColorSpace(supportedColorSpace) {
                    return supportedColor
                }
            }
            return nil
        }
        return self
    }
    
    /// A `CIColor` representation of the color, or `nil` if the color cannot be accurately represented as `CIColor`.
    var ciColor: CIColor? {
        CIColor(color: self)
    }

}
#endif
