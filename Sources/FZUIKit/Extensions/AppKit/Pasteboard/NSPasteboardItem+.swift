//
//  NSPasteboardItem+.swift
//
//
//  Created by Florian Zand on 01.02.24.
//

#if os(macOS)
import AppKit
import FZSwiftUtils
import UniformTypeIdentifiers

extension NSPasteboardItem {
    @available(macOS 11.0, *)
    var contentTypes: [UTType] { types.compactMap({ $0.uttype }) }
    
    @available(macOS 11.0, *)
    func contentTypes(conformingTo contentType: UTType) -> [UTType] {
        contentTypes.filter({ $0.conforms(to: contentType) })
    }
    
    /// The string of the pasteboard item.
    public var string: String? {
        get { string(forType: .string) }
        set {
            guard let newValue = newValue else { return }
            setString(newValue, forType: .string)
        }
    }
    
    /// The attributed string of the pasteboard item.
    public var attributedString: NSAttributedString? {
        get {
            guard let data = data(forType: .rtf) else { return nil }
            return NSAttributedString(rtf: data, documentAttributes: nil)
        }
        set {
            guard let newValue = newValue, let data = newValue.rtf(from: newValue.string.nsRange) else { return }
            setString(newValue.string, forType: .string)
            setData(data, forType: .rtf)
        }
    }
    
    /// The png image of the pasteboard item.
    public var pngImage: NSImage? {
        get {
            guard let data = data(forType: .png) else { return nil }
            return NSImage(data: data)
        }
        set {
            guard let data = newValue?.pngData() else { return }
            setData(data, forType: .png)
        }
    }
    
    /// The tiff image of the pasteboard item.
    public var tiffImage: NSImage? {
        get {
            guard let data = data(forType: .tiff) else { return nil }
            return NSImage(data: data)
        }
        set {
            guard let data = newValue?.tiffRepresentation else { return }
            setData(data, forType: .tiff)
        }
    }
    
    /// The color of the pasteboard item.
    public var color: NSColor? {
        get {
            if let data = data(forType: .color), let color: NSColor = try? NSKeyedUnarchiver.unarchive(data) {
                return color
            }
            return nil
        }
        set {
            guard let data = try? newValue?.archivedData() else { return }
            setData(data, forType: .color)
        }
    }
    
    /// The sound of the pasteboard item.
    public var sound: NSSound? {
        get {
            guard let data = data(forType: .sound) else { return nil }
            return NSSound(data: data)
        }
        set {
            guard let data = try? newValue?.archivedData() else { return }
            setData(data, forType: .sound)
        }
    }
    
    /// The url of the pasteboard item.
    public var url: URL? {
        get {
            guard let data = data(forType: .URL) else { return nil }
            return URL(dataRepresentation: data, relativeTo: nil)
        }
        set {
            if let data = newValue?.dataRepresentation {
                setData(data, forType: .URL)
            }
        }
    }
    
    /// The file url of the pasteboard item.
    public var fileURL: URL? {
        get {
            guard let data = data(forType: .fileURL) else { return nil }
            return URL(dataRepresentation: data, relativeTo: nil)
        }
        set {
            if let newValue = newValue, newValue.isFileURL {
                setData(newValue.dataRepresentation, forType: .fileURL)
            }
        }
    }
}

public extension Collection where Element: NSPasteboardItem {
    /// The strings of the pasteboard items.
    var strings: [String] {
        compactMap({$0.string})
    }
    
    /// The attributed strings of the pasteboard items.
    var attributedStrings: [NSAttributedString] {
        compactMap({$0.attributedString})
    }
    
    /// The images of the pasteboard items.
    var images: [NSImage] {
        compactMap({$0.tiffImage ?? $0.pngImage})
    }
    
    /// The urls of the pasteboard items.
    var urls: [URL] {
        compactMap({$0.url})
    }
    
    /// The file urls of the pasteboard items.
    var fileURLs: [URL] {
        compactMap({$0.fileURL})
    }
       
    /// The sounds of the pasteboard items.
    var sounds: [NSSound] {
        compactMap({$0.sound})
    }
    
    /// The colors of the pasteboard items.
    var colors: [NSColor] {
        compactMap({$0.color})
    }
}

#endif
