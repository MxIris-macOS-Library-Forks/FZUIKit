//
//  NSSegmentedControl+Builder.swift
//
//
//  Created by Florian Zand on 19.04.23.
//
#if os(macOS)
    import AppKit

    public extension NSSegmentedControl {
        /// A function builder type that produces an array of segments.
        @resultBuilder
        enum Builder {
            public static func buildBlock(_ block: [NSSegment]...) -> [NSSegment] {
                block.flatMap { $0 }
            }

            public static func buildOptional(_ item: NSSegment?) -> [NSSegment] {
                item != nil ? [item!] : []
            }

            public static func buildEither(first: [NSSegment]) -> [NSSegment] {
                first
            }

            public static func buildEither(second: [NSSegment]) -> [NSSegment] {
                second
            }

            public static func buildArray(_ components: [[NSSegment]]) -> [NSSegment] {
                components.flatMap { $0 }
            }

            public static func buildExpression(_ expr: NSSegment?) -> [NSSegment] {
                expr.map { [$0] } ?? []
            }

            public static func buildExpression(_ expr: NSImage) -> [NSSegment] {
                [NSSegment(expr)]
            }
            
            public static func buildExpression(_ expr: [NSImage]) -> [NSSegment] {
                expr.map { NSSegment($0) }
            }
            
            public static func buildExpression(_ expr: String) -> [NSSegment] {
                [NSSegment(expr)]
            }

            public static func buildExpression(_ expr: [String]) -> [NSSegment] {
                expr.map { NSSegment($0) }
            }
        }
    }

#endif
