//
//  NSUIFontDescriptor+.swift
//
//
//  Created by Florian Zand on 16.03.23.
//

#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

public extension NSUIFontDescriptor {
    /// A dictionary of the traits.
    var traits: [TraitKey: Any]? {
        fontAttributes[.traits] as? [TraitKey: Any]
    }
    
    /// The system design of the font descriptor.
    var design: NSUIFontDescriptor.SystemDesign? {
        if let rawValue = self.traits?[.design] as? String {
           return NSUIFontDescriptor.SystemDesign(rawValue: rawValue)
        }
        return nil
    }
    
    /// The weight of the font descriptor.
    var weight: NSUIFont.Weight? {
        if let rawValue = self.traits?[.weight] as? CGFloat {
           return NSUIFont.Weight(rawValue: rawValue)
        }
        return nil
    }
    
    /// The text style of the font descriptor.
    @available(macOS 11.0, iOS 10.0, tvOS 10.0, watchOS 3.0, *)
    var textStyle: NSUIFont.TextStyle? {
        if let rawValue = fontAttributes[.uiUsage] as? String, rawValue.contains("UICTFontTextStyle") {
            switch rawValue {
                case let str where str.contains("Body"): return .body
            case let str where str.contains("Callout"): return .callout
            case let str where str.contains("Caption1"): return .caption1
            case let str where str.contains("Caption2"): return .caption2
            case let str where str.contains("Headline"): return .headline
            case let str where str.contains("Subhead"): return .subheadline
                #if os(macOS) || os(iOS)
            case let str where str.contains("Title0"): return .largeTitle
                #endif
            case let str where str.contains("Title1"): return .title1
            case let str where str.contains("Title2"): return .title2
            case let str where str.contains("Title3"): return .title3
                default: break
            }
            return NSUIFont.TextStyle(rawValue: rawValue)
        }
        return nil
    }
}

public extension NSUIFontDescriptor.TraitKey {
    /// The normalized design value.
    static var design: Self {
        return .init(rawValue: "NSCTFontUIFontDesignTrait")
    }
    
    /// The normalized weight value.
    static var weight: Self {
        return .init(rawValue: "NSCTFontWeightTrait")
    }
}


public extension NSUIFontDescriptor.AttributeName {
    #if canImport(UIKit)
    /// A dictionary that fully describes the font traits.
    static var traits: Self {
        return .init(rawValue: "NSCTFontSizeCategoryAttribute")
    }
    #endif
        
    /// An optional string object that specifies the font size category.
    static var sizeCategory: Self {
        return .init(rawValue: "NSCTFontSizeCategoryAttribute")
    }

    /// An optional string object that specifies the font UI usage.
    static var uiUsage: Self {
        return .init(rawValue: "NSCTFontUIUsageAttribute")
    }

    /*
    enum UIUsage: String {
        case systemUltraLight = "CTFontUltraLightUsage"
        case systemThin = "CTFontThinUsage"
        case systemLight = "CTFontLightUsage"
        case systemRegular = "CTFontRegularUsage"
        case systemMedium = "CTFontMediumUsage"
        case systemSemiBold = "CTFontDemiUsage"
        case systemBold = "CTFontBoldUsage"
        case systemHeavy = "CTFontHeavyUsage"
        case systemBlack = "CTFontBlackUsage"

        case body = "UICTFontTextStyleBody"
        case callout = "UICTFontTextStyleCallout"
        case caption1 = "UICTFontTextStyleCaption1"
        case caption2 = "UICTFontTextStyleCaption2"
        case headline = "UICTFontTextStyleHeadline"
        case subheadline = "UICTFontTextStyleSubhead"
        case largeTitle = "UICTFontTextStyleTitle0"
        case title1 = "UICTFontTextStyleTitle1"
        case title2 = "UICTFontTextStyleTitle2"
        case title3 = "UICTFontTextStyleTitle3"
        var textstyle: NSUIFont.TextStyle? {
            switch self {
            case .body: return .body
            case .callout: return .callout
            case .caption1: return .caption1
            case .caption2: return .caption2
            case .headline: return .headline
            case .subheadline: return .subheadline
            case .largeTitle: return .largeTitle
            case .title1: return .title1
            case .title2: return .title2
            case .title3: return .title3
            default: return nil
            }
        }
    }
     */
}