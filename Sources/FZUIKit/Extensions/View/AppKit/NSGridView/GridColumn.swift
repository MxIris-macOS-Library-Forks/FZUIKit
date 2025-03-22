//
//  GridColumn.swift
//
//
//  Created by Florian Zand on 22.03.25.
//

#if os(macOS)
import AppKit
import FZSwiftUtils

/// A column within a `NSGridView`.
public class GridColumn: CustomStringConvertible, CustomDebugStringConvertible, Equatable {
    /// The grid view of the column.
    public var gridView: NSGridView? { gridColumn?.gridView }
    
    /// The index of the column inside it's grid view, or `nil` if the column isn't displayed in a grid view.
    public var index: Int? { gridColumn?.index }
    
    /// The cells of the column.
    public var cells: [GridCell] { (gridColumn?.cells ?? []).compactMap({ GridCell($0) }) }
    
    /// Merges the cells of the column.
    @discardableResult
    public func mergeCells() -> Self {
        if gridColumn != nil {
            mergeCells(in: 0..<numberOfCells)
        } else {
            properties.merge = true
        }
        return self
    }
    
    /// Merges the cells of the column at the specified range.
    @discardableResult
    public func mergeCells(in range: Range<Int>) -> Self {
        guard numberOfCells > 0 else { return self }
        if gridColumn != nil {
            guard numberOfCells > 0 else { return self }
            gridColumn?.mergeCells(in: range.clamped(max: numberOfCells).nsRange)
        } else {
            properties.mergeRange = range.toClosedRange
        }
        return self
    }
    
    /// Merges the cells of the column at the specified range.
    @discardableResult
    public func mergeCells(in range: ClosedRange<Int>) -> Self {
        mergeCells(in: range.toRange)
    }
    
    /// The content views of the grid column cells.
    public var views: [NSView?] {
        get { gridColumn?.views ?? properties.views }
        set {
            if let gridColumn = gridColumn {
                gridColumn.views = newValue
            } else {
                properties.views = newValue
            }
        }
    }
    
    /// Sets the content views of the grid column cells.
    @discardableResult
    public func views(@NSGridView.Builder _ views: () -> [NSView]) -> Self {
        self.views = views()
        return self
    }
    
    /// Sets the content views of the grid column cells.
    @discardableResult
    public func views(_ views: [NSView]) -> Self {
        self.views = views
        return self
    }

    /// The leading padding of the column.
    public var leadingPadding: CGFloat {
        get { gridColumn?.leadingPadding ?? properties.leadingPadding }
        set {
            gridColumn?.leadingPadding = newValue
            properties.leadingPadding = newValue
        }
    }
    
    /// Sets the leading padding of the column.
    @discardableResult
    public func leadingPadding(_ padding: CGFloat) -> Self {
        leadingPadding = padding
        return self
    }

    /// The trailing padding of the column.
    public var trailingPadding: CGFloat {
        get { gridColumn?.trailingPadding ?? properties.trailingPadding }
        set {
            gridColumn?.trailingPadding = newValue
            properties.trailingPadding = newValue
        }
    }
    
    /// Sets the trailing padding of the column.
    @discardableResult
    public func trailingPadding(_ padding: CGFloat) -> Self {
        trailingPadding = padding
        return self
    }

    /// A Boolean value that indicates whether the column is hidden.
    public var isHidden: Bool {
        get { gridColumn?.isHidden ?? properties.isHidden }
        set {
            gridColumn?.isHidden = newValue
            properties.isHidden = newValue
        }
    }
    
    /// Sets the Boolean value that indicates whether the column is hidden.
    @discardableResult
    public func isHidden(_ isHidden: Bool) -> Self {
        self.isHidden = isHidden
        return self
    }

    /// The column width.
    public var width: CGFloat {
        get { gridColumn?.width ?? properties.width }
        set {
            gridColumn?.width = newValue
            properties.width = newValue
        }
    }
    
    /// Sets the column width.
    @discardableResult
    public func width(_ width: CGFloat) -> Self {
        self.width = width
        return self
    }

    /// The x-placement of the views.
    public var xPlacement: Placement {
        get {.init(rawValue: (gridColumn?.xPlacement ?? properties.xPlacement).rawValue) ?? .inherited }
        set {
            gridColumn?.xPlacement = newValue.placement
            properties.xPlacement = newValue.placement
        }
    }
    
    /// Sets the x-placement of the views.
    @discardableResult
    public func xPlacement(_ placement: Placement) -> Self {
        xPlacement = placement
        return self
    }
    
    /// The x-placement of the views.
    public enum Placement: Int, CustomStringConvertible {
        /// Inherited.
        case inherited
        /// None.
        case none
        /// Leading.
        case leading
        /// Trailing.
        case trailing
        /// Center.
        case center
        /// Fill.
        case fill
        
        public var description: String {
            switch self {
            case .inherited: return "inherited"
            case .none: return "none"
            case .leading: return "leading"
            case .trailing: return "trailing"
            case .center: return "center"
            case .fill: return "fill"
            }
        }
        
        var placement: NSGridCell.Placement {
            .init(rawValue: rawValue)!
        }
    }
    
    /// Creates a grid column with the specified views.
    public init(views: [NSView?] = []) {
        properties.views = views
    }
    
    /// Creates a grid column with the specified views.
    public init(@NSGridView.Builder views: () -> [NSView?]) {
        properties.views = views()
    }
    
    /// Creates a grid column with the specified view.
    public init(_ view: NSView) {
        properties.views = [view]
    }
    
    init(_ gridColumn: NSGridColumn) {
        self.gridColumn = gridColumn
    }
        
    struct Properties {
        var views: [NSView?] = []
        var isHidden = false
        var xPlacement: NSGridCell.Placement = .inherited
        var width: CGFloat = 1.1754943508222875e-38
        var leadingPadding: CGFloat = 0.0
        var trailingPadding: CGFloat = 0.0
        var merge: Bool = false
        var mergeRange: ClosedRange<Int>? = nil
    }
    
    var properties = Properties()
    var numberOfCells: Int { gridColumn?.numberOfCells ?? properties.views.count }
    weak var gridColumn: NSGridColumn? {
        didSet {
            if let gridColumn = gridColumn {
                gridColumn.views = properties.views
                gridColumn.isHidden = properties.isHidden
                gridColumn.leadingPadding = properties.leadingPadding
                gridColumn.trailingPadding = properties.trailingPadding
                gridColumn.xPlacement = properties.xPlacement
                properties.views = []
            } else if let gridColumn = oldValue {
                properties.views = gridColumn.views
            }
        }
    }
    
    public var description: String {
        "GridColumn(views: \(views.count), xPlacement: \(xPlacement),  width: \(width))"
    }
    
    public var debugDescription: String {
        var strings = ["GridColumn:"]
        strings += "views: [\(views.compactMap({ if let view = $0 { return "\(type(of: view))"} else { return "Empty"} }).joined(separator: ", "))]"
        strings += "xPlacement: \(xPlacement)"
        strings += "width: \(width == 1.1754943508222875e-38 ? "automatic" : "\(width)")"
        strings += "leadingPadding: \(leadingPadding), trailingPadding: \(trailingPadding)"
        strings += "isHidden: \(isHidden)"
        return strings.joined(separator: "\n  - ")
    }
    
    public static func == (lhs: GridColumn, rhs: GridColumn) -> Bool {
        if let lhs = lhs.gridColumn, let rhs = rhs.gridColumn {
            return lhs === rhs
        }
        return lhs === rhs
    }
}

extension GridColumn {
    /// A function builder type that produces an array of grid column.
    @resultBuilder
    public enum Builder {
        public static func buildBlock(_ block: [GridColumn]...) -> [GridColumn] {
            block.flatMap { $0 }
        }

        public static func buildOptional(_ item: [GridColumn]?) -> [GridColumn] {
            item ?? []
        }

        public static func buildEither(first: [GridColumn]?) -> [GridColumn] {
            first ?? []
        }

        public static func buildEither(second: [GridColumn]?) -> [GridColumn] {
            second ?? []
        }

        public static func buildArray(_ components: [[GridColumn]]) -> [GridColumn] {
            components.flatMap { $0 }
        }

        public static func buildExpression(_ expression: [GridColumn]?) -> [GridColumn] {
            expression ?? []
        }

        public static func buildExpression(_ expression: GridColumn?) -> [GridColumn] {
            expression.map { [$0] } ?? []
        }
        
        public static func buildExpression(_ expression: NSView) -> [GridColumn] {
            [GridColumn(views: [expression])]
        }
        
        public static func buildExpression(_ expression: [NSView]) -> [GridColumn] {
            expression.map({ GridColumn(views: [$0]) })
        }
    }
}
#endif
