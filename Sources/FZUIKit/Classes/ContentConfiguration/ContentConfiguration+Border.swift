//
//  ContentConfiguration+Border.swift
//
//
//  Created by Florian Zand on 03.09.22.
//

#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif
import FZSwiftUtils

public extension ContentConfiguration {
    /// A configuration that specifies the appearance of a border.
    struct Border: Hashable {
        
        /// The color of the border.
        public var color: NSUIColor? = nil {
            didSet { updateResolvedColor() } }
        
        /// The color transformer for resolving the border color.
        public var colorTransformer: NSUIConfigurationColorTransformer? = nil {
            didSet { updateResolvedColor() } }
        
        /// Generates the resolved border color for the specified border color, using the border color and color transformer.
        public func resolvedColor() -> NSUIColor? {
            if let color = self.color {
                return colorTransformer?(color) ?? color
            }
            return nil
        }
        
        /// The width of the border.
        public var width: CGFloat = 0.0
        
        /// The dash pattern of the border.
        public var dashPattern: [CGFloat]? = nil
        
        public init(color: NSUIColor? = nil,
                    colorTransformer: NSUIConfigurationColorTransformer? = nil,
                    width: CGFloat = 0.0,
                    dashPattern: [CGFloat]? = nil)
        {
            self.color = color
            self.width = width
            self.dashPattern = dashPattern
            self.colorTransformer = colorTransformer
            self.updateResolvedColor()
        }

        public static func none() -> Self {
            return Self()
        }
        
        public static func black() -> Self {
            Self(color: .black, width: 1.0)
        }
        
        internal var _resolvedColor: NSUIColor? = nil
        internal mutating func updateResolvedColor() {
            _resolvedColor = resolvedColor()
        }
    }
}

#if os(macOS)
@available(macOS 10.15.1, *)
public extension NSView {
    /**
     Configurates the border apperance of the view.

     - Parameters:
        - configuration:The configuration for configurating the apperance.
     */
    func configurate(using configuration: ContentConfiguration.Border) {
        wantsLayer = true
        layer?.configurate(using: configuration)
    }
}

#elseif canImport(UIKit)
@available(iOS 14.0, *)
public extension UIView {
    /**
     Configurates the border apperance of the view.

     - Parameters:
        - configuration:The configuration for configurating the apperance.
     */
    func configurate(using configuration: ContentConfiguration.Border) {
        layer.configurate(using: configuration)
    }
}
#endif

public extension CALayer {
    internal var layerBoundsObserver: NSKeyValueObservation? {
        get { getAssociatedValue(key: "CALayer.boundsObserver", object: self) }
        set { set(associatedValue: newValue, key: "boundsObserver", object: self) }
    }
    
    internal var borderLayer: CAShapeLayer? {
        get { getAssociatedValue(key: "CALayer_borderLayer", object: self, initialValue: nil) }
        set {
            if newValue != self.borderLayer {
                self.borderLayer?.removeFromSuperlayer()
                if let newValue = newValue, newValue.superlayer != self {
                    self.addSublayer(newValue)
                    newValue.sendToBack()
                }
            }
            set(associatedValue: newValue, key: "CALayer_borderLayer", object: self)
        }
    }
    
    /**
     Configurates the border apperance of the view.

     - Parameters:
        - configuration:The configuration for configurating the apperance.
     */
    func configurate(using configuration: ContentConfiguration.Border) {
        if configuration._resolvedColor == nil || configuration.width == 0.0 {
            self.borderLayer = nil
            self.layerBoundsObserver?.invalidate()
            self.layerBoundsObserver = nil
        } else {
            if self.borderLayer == nil {
                self.borderLayer = CAShapeLayer()
                self.borderLayer?.name = "_DashedBorderLayer"
            }
            
            if layerBoundsObserver == nil {
                layerBoundsObserver = self.observeChanges(for: \.bounds, handler: { [weak self] old, new in
                    guard let self = self else { return }
                    Swift.print("layerBoundsObserver", new)
                    guard new != old else { return }
                    self.borderLayer?.bounds = new
              //      self.borderLayer?.path = NSUIBezierPath(roundedRect: new, cornerRadius: self.cornerRadius).cgPath
                    self.borderLayer?.position = CGPoint(x: new.size.width/2, y: new.size.height/2)
                })
            }
            
            let frameSize = self.frame.size
            let shapeRect = CGRect(origin: .zero, size: frameSize)
            
            self.borderLayer?.bounds = shapeRect
            self.borderLayer?.position = CGPoint(x: frameSize.width/2, y: frameSize.height/2)
            self.borderLayer?.fillColor = .clear
            self.borderLayer?.strokeColor = configuration._resolvedColor?.cgColor
            self.borderLayer?.lineWidth = configuration.width
            self.borderLayer?.lineJoin = CAShapeLayerLineJoin.round
            self.borderLayer?.cornerRadius = self.cornerRadius
            self.borderLayer?.lineDashPattern = configuration.dashPattern as? [NSNumber]
      //      self.borderLayer?.path = NSUIBezierPath(roundedRect: shapeRect, cornerRadius: self.cornerRadius).cgPath
        }
    }
}
