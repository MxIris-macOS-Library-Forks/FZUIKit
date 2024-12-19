//
//  NSImage+.swift
//
//
//  Created by Florian Zand on 25.04.22.
//

import FZSwiftUtils

#if os(macOS)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif
import UniformTypeIdentifiers


#if os(macOS)
    public extension NSImage {
        
        convenience init(cgImage: CGImage) {
            self.init(cgImage: cgImage, size: .zero)
        }

        convenience init?(size: CGSize, actions: (CGContext) -> Void) {
            if let currentCGContext = NSGraphicsContext.current?.cgContext {
                self.init(size: size)
                lockFocusFlipped(false)
                actions(currentCGContext)
                unlockFocus()
            } else {
                return nil
            }
        }
        
        /// A Boolean value that indicates whether the image is a symbol.
        @available(macOS 11.0, *)
        var isSymbolImage: Bool {
            value(forKey: Keys.isSymbolImage.unmangled) as? Bool ?? (symbolName != nil)
        }
        
        /// Returns the image types supported by `NSImage`.
        @available(macOS 11.0, *)
        static var imageContentTypes: [UTType] {
            imageTypes.compactMap({UTType($0)})
        }

        /// A `cgImage` represenation of the image.
        var cgImage: CGImage? {
            if let image = self.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                return image
            }
            guard let imageData = tiffRepresentation else { return nil }
            guard let sourceData = CGImageSourceCreateWithData(imageData as CFData, nil) else { return nil }
            return CGImageSourceCreateImageAtIndex(sourceData, 0, nil)
        }

        /// A `CIImage` represenation of the image.
        var ciImage: CIImage? {
            tiffRepresentation(using: .none, factor: 0).flatMap(CIImage.init)
        }

        /**
         Creates an image source that reads the image.

         - Note: Loading an animated image takes time as each image frame is loaded initially. It's recommended to parse the animation properties and frames via the image's `NSBitmapImageRep` representation.
         */
        var cgImageSource: CGImageSource? {
            let images = representations.compactMap({$0 as? NSBitmapImageRep}).flatMap({$0.getImages()})
            guard !images.isEmpty else { return nil }
            let types = Set(images.compactMap { $0.utType })
            let outputType = types.count == 1 ? (types.first ?? kUTTypeTIFF) : kUTTypeTIFF
            guard let mutableData = CFDataCreateMutable(nil, 0), let destination = CGImageDestinationCreateWithData(mutableData, outputType, images.count, nil) else { return nil }
            images.forEach { CGImageDestinationAddImage(destination, $0, nil) }
            guard CGImageDestinationFinalize(destination) else { return nil }
            return CGImageSourceCreateWithData(mutableData, nil)
        }

        typealias ImageOrientation = ImageSource.ImageProperties.Orientation
        /// The image orientation.
        var orientation: ImageOrientation {
            ImageSource(image: self)?.properties()?.orientation ?? .up
        }
    }

    public extension NSImage {
        /**
         Returns a new version of the current image with the specified tint color.

         For bitmap images, this method draws the background tint color followed by the image contents using the `CGBlendMode.destinationIn mode. For symbol images, this method returns an image that always uses the specified tint color.

         The new image uses the same rendering mode as the original image.

         - Parameter color: The tint color to apply to the image.
         - Returns: A new version of the image that incorporates the specified tint color.
         */
        func withTintColor(_ color: NSColor) -> NSImage {
            if #available(macOS 12.0, *) {
                if isSymbolImage {
                    return withSymbolConfiguration(.init(paletteColors: [color])) ?? self
                }
            }

            if let cgImage = cgImage {
                let rect = CGRect(.zero, cgImage.size)
                if let tintedImage = try? CGImage.create(size: rect.size, { ctx, _ in

                    // draw black background to preserve color of transparent pixels
                    ctx.setBlendMode(.normal)
                    ctx.setFillColor(CGColor.black)
                    ctx.fill([rect])

                    // Draw the image
                    ctx.setBlendMode(.normal)
                    ctx.draw(cgImage, in: rect)

                    // tint image (losing alpha) - the luminosity of the original image is preserved
                    ctx.setBlendMode(.color)
                    ctx.setFillColor(color.cgColor)
                    ctx.fill([rect])

                    //   if keepingAlpha {
                    // mask by alpha values of original image
                    ctx.setBlendMode(.destinationIn)
                    ctx.draw(cgImage, in: rect)
                    //  }
                }).nsImage {
                    return tintedImage
                }
            }
            return self
        }

        /// Returns an object scaled to the curren screen that may be used as the contents of a layer.
        var scaledLayerContents: Any {
            let scale = recommendedLayerContentsScale(0.0)
            return layerContents(forContentsScale: scale)
        }

        static func maskImage(cornerRadius: CGFloat) -> NSImage {
            let image = NSImage(size: NSSize(width: cornerRadius * 2, height: cornerRadius * 2), flipped: false) { rectangle in
                let bezierPath = NSBezierPath(roundedRect: rectangle, xRadius: cornerRadius, yRadius: cornerRadius)
                NSColor.black.setFill()
                bezierPath.fill()
                return true
            }
            image.capInsets = NSEdgeInsets(top: cornerRadius, left: cornerRadius, bottom: cornerRadius, right: cornerRadius)
            return image
        }
    }

    public extension NSImage {
        /// The bitmap representation of the image
        var bitmapImageRep: NSBitmapImageRep? {
            if let representation = representations.compactMap({$0 as? NSBitmapImageRep}).first {
                return representation
            }
            
            if let cgImage = cgImage {
                let imageRep = NSBitmapImageRep(cgImage: cgImage)
                imageRep.size = size
                return imageRep
            }
            return nil
        }

        /**
         Returns a data object that contains the specified image in TIFF format.

         - Returns: A data object containing the TIFF data, or `nil` if there was a problem generating the data. This function may return `nil` if the image has no data or if the underlying `CGImageRef` contains data in an unsupported bitmap format.
         */
        func tiffData() -> Data? { tiffRepresentation }
        
        /**
         Returns a data object that contains the specified image in PNG format.

         - Returns: A data object containing the PNG data, or `nil` if there was a problem generating the data. This function may return `nil` if the image has no data or if the underlying `CGImageRef` contains data in an unsupported bitmap format.
         */
        func pngData() -> Data? { bitmapImageRep?.pngData }

        /**
         Returns a data object that contains the image in JPEG format.

         - Returns: A data object containing the JPEG data, or `nil` if there’s a problem generating the data. This function may return `nil` if the image has no data or if the underlying `CGImageRef` contains data in an unsupported bitmap format.
         */
        func jpegData() -> Data? { bitmapImageRep?.jpegData }

        /**
         Returns a data object that contains the image in JPEG format.

         - Parameter compressionFactor: The quality of the resulting JPEG image, expressed as a value from `0.0` to `1.0`. The value `0.0` represents the maximum compression (or lowest quality) while the value `1.0` represents the least compression (or best quality).

         - Returns: A data object containing the JPEG data, or `nil` if there’s a problem generating the data. This function may return `nil` if the image has no data or if the underlying `CGImageRef` contains data in an unsupported bitmap format.
         */
        func jpegData(compressionFactor factor: Double) -> Data? {
            bitmapImageRep?.jpegData(compressionFactor: factor)
        }
    }
#endif
