//
//  NSUIImage+Modify.swift
//  
//
//  Created by Florian Zand on 19.06.23.
//

#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

public extension NSUIImage {
    /// The order of image tiles.
    enum TileSplitOrder: Int {
        /// Horizontal tiles first.
        case horizontalFirst
        /// Vertical tiles first.
        case verticalFirst
    }
    
    /**
     Splits the images to tiles with the specified vertical and horizontal count.
     
     - Parameters:
        - horizontalCount: The amount of horizontal tiles.
        - verticalCount: The amount of vertical tiles.
        - order: The order of the tiles.
     - Returns: An array with the tile images.
     */
    func splitToTiles(horizontalCount: Int, verticalCount: Int, order: TileSplitOrder = .horizontalFirst) -> [NSUIImage] {
        guard horizontalCount > 0,  verticalCount > 0 else { return [] }
        let tileSize = CGSize(self.size.width/CGFloat(horizontalCount), self.size.height/CGFloat(verticalCount))
        return self.splitToTiles(size: tileSize, order: order)
    }
    
    /**
     Splits the images to tiles with the specified size.
     
     - Parameters:
        - size: The size of an tile.
        - order: The order of the tiles.
     - Returns: An array with the tile images.
     */
    func splitToTiles(size: CGSize, order: TileSplitOrder = .horizontalFirst) -> [NSUIImage] {
           let vCount = Int(self.size.height / size.height)
           let hCount = Int(self.size.width / size.width)
           var tiles = [NSUIImage]()
    #if os(macOS)
        guard let cgImage = self.cgImage else { return [] }
    #endif
    for a in 0..<(order == .horizontalFirst ? hCount : vCount) {
        for b in 0..<(order == .horizontalFirst ? vCount : hCount) {
    let origin = CGPoint(x: CGFloat(order == .horizontalFirst  ? b : a)*size.width, y: CGFloat(order == .horizontalFirst  ? a : b)*size.height)
    #if os(macOS)
    let rect = CGRect(origin, size)
    if let tileCGImage = cgImage.cropping(to: rect) {
        let tile = NSImage(cgImage: tileCGImage, size: size)
        tiles.append(tile)
    }
    #elseif canImport(UIKit)
                   UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
                   draw(at: origin)
                   if let newImage = UIGraphicsGetImageFromCurrentImageContext() {
                       tiles.append(newImage)
                   }
                   UIGraphicsEndImageContext()
    #endif
               }
           }
           return tiles
       }
   }

#if os(macOS)
public extension NSUIImage {
    /// Returns the image resized to the specified size.
    func resized(to size: CGSize) -> NSImage {
        let scaledImage = NSImage(size: size)
        scaledImage.cacheMode = .never
        scaledImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .default
        draw(in: NSRect(x: 0, y: 0, width: size.width, height: size.height), from: .zero, operation: .copy, fraction: 1.0)
        scaledImage.unlockFocus()
        return scaledImage
    }
    
    /// Returns the image resized to fit the specified size.
    func resized(toFit size: CGSize) -> NSImage {
        let size = self.size.scaled(toFit: size)
        return resized(to: size)
    }
    
    /// Returns the image resized to fill the specified size.
    func resized(toFill size: CGSize) -> NSImage {
        let size = self.size.scaled(toFill: size)
        return resized(to: size)
    }
    
    /// Returns the image as circle.
    func rounded() -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        
        let frame = NSRect(origin: .zero, size: size)
        NSBezierPath(ovalIn: frame).addClip()
        draw(at: .zero, from: frame, operation: .sourceOver, fraction: 1)
        
        image.unlockFocus()
        return image
    }
    
    /// Returns the image rounded with the specified corner radius.
    func rounded(cornerRadius: CGFloat) -> NSImage {
        let rect = NSRect(origin: NSPoint.zero, size: size)
        if
            let cgImage = cgImage,
            let context = CGContext(data: nil,
                                    width: Int(size.width),
                                    height: Int(size.height),
                                    bitsPerComponent: 8,
                                    bytesPerRow: 4 * Int(size.width),
                                    space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
        {
            context.beginPath()
            context.addPath(CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil))
            context.closePath()
            context.clip()
            context.draw(cgImage, in: rect)
            
            if let composedImage = context.makeImage() {
                return NSImage(cgImage: composedImage, size: size)
            }
        }
        return self
    }
    
    /// Returns the image rotated to the specified degree.
    func rotated(degrees: Float) -> NSImage {
        let degrees = CGFloat(degrees)
        var imageBounds = NSZeroRect; imageBounds.size = size
        let pathBounds = NSBezierPath(rect: imageBounds)
        var transform = NSAffineTransform()
        transform.rotate(byDegrees: degrees)
        pathBounds.transform(using: transform as AffineTransform)
        let rotatedBounds: NSRect = NSMakeRect(NSZeroPoint.x, NSZeroPoint.y, pathBounds.bounds.size.width, pathBounds.bounds.size.height)
        let rotatedImage = NSImage(size: rotatedBounds.size)
        
        imageBounds.origin.x = NSMidX(rotatedBounds) - (NSWidth(imageBounds) / 2)
        imageBounds.origin.y = NSMidY(rotatedBounds) - (NSHeight(imageBounds) / 2)
        
        transform = NSAffineTransform()
        transform.translateX(by: +(NSWidth(rotatedBounds) / 2), yBy: +(NSHeight(rotatedBounds) / 2))
        transform.rotate(byDegrees: degrees)
        transform.translateX(by: -(NSWidth(rotatedBounds) / 2), yBy: -(NSHeight(rotatedBounds) / 2))
        rotatedImage.lockFocus()
        transform.concat()
        draw(in: imageBounds, from: NSZeroRect, operation: NSCompositingOperation.copy, fraction: 1.0)
        rotatedImage.unlockFocus()
        
        return rotatedImage
    }
    
    /// Returns the image with the specified opacity value.
    func withOpacity(_ value: CGFloat) -> NSUIImage {
        let opacityImage = NSImage(size: size)
        opacityImage.cacheMode = .never
        opacityImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .default
        draw(in: CGRect(origin: .zero, size: size), from: .zero, operation: .sourceOver, fraction: value)
        opacityImage.unlockFocus()
        return opacityImage
    }
}
#elseif canImport(UIKit)

public extension NSUIImage {
    /// Returns the image resized to the specified size.
    func resized(to size: CGSize) -> NSUIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// Returns the image resized to fit the specified size.
    func resized(toFit size: CGSize) -> NSUIImage? {
        let size = self.size.scaled(toFit: size)
        return resized(to: size)
    }
    
    /// Returns the image resized to fill the specified size.
    func resized(toFill size: CGSize) -> NSUIImage? {
        let size = self.size.scaled(toFill: size)
        return resized(to: size)
    }
    
    /// Returns the image rotated to the specified degree.
    func rotated(degrees: Float) -> NSUIImage {
        var newSize = CGRect(origin: CGPoint.zero, size: size).applying(CGAffineTransform(rotationAngle: CGFloat(degrees))).size
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        let context = UIGraphicsGetCurrentContext()!
        
        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        context.rotate(by: CGFloat(degrees))
        draw(in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    #if os(iOS) || os(tvOS)
    /// Returns the image as circle.
    func rounded() -> NSUIImage {
        let maxRadius = min(size.width, size.height)
        return rounded(cornerRadius: maxRadius)
    }
    
    /// Returns the image rounded with the specified corner radius.
    func rounded(cornerRadius: CGFloat) -> NSUIImage {
        let widthRatio: CGFloat = 1.0
        let heightRatio: CGFloat = 1.0
        
        let scaleFactor = min(widthRatio, heightRatio)
        
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )
        
        let newRect = CGRect(origin: .zero, size: scaledImageSize)
        let renderer = UIGraphicsImageRenderer(size: newRect.size)
        
        let scaledImage = renderer.image { _ in
            UIBezierPath(roundedRect: newRect, cornerRadius: cornerRadius).addClip()
            self.draw(in: newRect)
        }
        return scaledImage
    }
    
    /// Returns the image with the specified opacity value.
    func withOpacity(_ value: CGFloat) -> NSUIImage {
        return UIGraphicsImageRenderer(size: size, format: imageRendererFormat).image { _ in
            draw(in: CGRect(origin: .zero, size: size), blendMode: .normal, alpha: value)
        }
    }
    #endif
}
#endif
