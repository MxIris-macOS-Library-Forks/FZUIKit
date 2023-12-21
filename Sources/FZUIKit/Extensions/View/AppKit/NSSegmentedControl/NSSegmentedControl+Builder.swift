//
//  NSSegmentedControl+Builder.swift
//
//
//  Created by Florian Zand on 19.04.23.
//
#if os(macOS)
import AppKit

public extension NSSegmentedControl {
    @resultBuilder
    enum Builder {
        public static func buildBlock(_ block: [NSSegment]...) -> [NSSegment] {
            block.flatMap { $0 }
        }
        
        public static func buildOptional(_ item: NSSegment?) -> [NSSegment] {
            if let item = item {
                return [item]
            }
           return []
        }

        public static func buildOptional(_ item: [NSSegment]?) -> [NSSegment] {
            item ?? []
        }

        public static func buildEither(first: [NSSegment]?) -> [NSSegment] {
            first ?? []
        }

        public static func buildEither(second: [NSSegment]?) -> [NSSegment] {
            second ?? []
        }

        public static func buildArray(_ components: [[NSSegment]]) -> [NSSegment] {
            components.flatMap { $0 }
        }

        public static func buildExpression(_ expr: [NSSegment]?) -> [NSSegment] {
            expr ?? []
        }

        public static func buildExpression(_ expr: NSSegment?) -> [NSSegment] {
            expr.map { [$0] } ?? []
        }

        public static func buildExpression(_ expr: [NSImage]?) -> [NSSegment] {
            return expr?.map { NSSegment($0) } ?? []
        }

        public static func buildExpression(_ expr: NSImage?) -> [NSSegment] {
            if let image = expr {
                return [NSSegment(image)]
            }
            return []
        }

        public static func buildExpression(_ expr: [String]?) -> [NSSegment] {
            return expr?.map { NSSegment($0) } ?? []
        }

        public static func buildExpression(_ expr: String?) -> [NSSegment] {
            if let string = expr {
                return [NSSegment(string)]
            }
            return []
        }
    }
}

#endif