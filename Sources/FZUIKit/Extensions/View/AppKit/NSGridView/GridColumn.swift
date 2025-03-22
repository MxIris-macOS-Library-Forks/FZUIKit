//
//  GridColumn.swift
//
//
//  Created by Florian Zand on 23.02.24.
//

#if os(macOS)
import AppKit
import FZSwiftUtils

/// A column within a grid view.
public class GridColumn: CustomStringConvertible, CustomDebugStringConvertible {
    
    /// The grid view of the column.
    public var gridView: NSGridView? {
        gridColumn?.gridView
    }
    
    /// Merges the cells at the specified range.
    public func mergeCells(in range: Range<Int>) {
        guard numberOfCells > 0 else { return }
        gridColumn?.mergeCells(in: range.clamped(max: numberOfCells).nsRange)
    }
    
    /// Merges the cells at the specified range.
    public func mergeCells(in range: ClosedRange<Int>) {
        mergeCells(in: range.lowerBound..<range.upperBound-1)
    }
    
    /// The content views of the grid column cells.
    public var views: [NSView?] {
        get { gridColumn?.views ?? _views }
        set {
            if let gridColumn = self.gridColumn {
                gridColumn.views = newValue
            } else {
                _views = newValue
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
    
    /// A Boolean value that indicates whether the column is hidden.
    public var isHidden: Bool {
        get { gridColumn?.isHidden ?? _isHidden }
        set {
            gridColumn?.isHidden = newValue
            _isHidden = newValue
        }
    }
    
    /// Sets the Boolean value that indicates whether the column is hidden.
    @discardableResult
    public func isHidden(_ isHidden: Bool) -> Self {
        self.isHidden = isHidden
        return self
    }
    
    /// The number of cells of the column.
    public var numberOfCells: Int {
        get { gridColumn?.numberOfCells ?? _views.count }
    }
    
    /// The leading padding of the column.
    public var leadingPadding: CGFloat {
        get { gridColumn?.leadingPadding ?? _leadingPadding }
        set {
            gridColumn?.leadingPadding = newValue
            _leadingPadding = newValue
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
        get { gridColumn?.trailingPadding ?? _trailingPadding }
        set {
            gridColumn?.trailingPadding = newValue
            _trailingPadding = newValue
        }
    }
    
    /// Sets the trailing padding of the column.
    @discardableResult
    public func trailingPadding(_ padding: CGFloat) -> Self {
        trailingPadding = padding
        return self
    }
    
    /// The column width.
    public var width: CGFloat {
        get { gridColumn?.width ?? _width }
        set {
            gridColumn?.width = newValue
            _width = newValue
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
        get {.init(rawValue: (gridColumn?.xPlacement ?? _xPlacement).rawValue) ?? .inherited }
        set {
            gridColumn?.xPlacement = newValue.placement
            _xPlacement = newValue.placement
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
    public init(@NSGridView.Builder _ views: () -> [NSView?]) {
        _views = views()
    }
    
    /// Creates a grid column with the specified views.
    public init(views: [NSView?]) {
        _views = views
    }
    
    /// Creates a grid column.
    public init() {
        
    }
    
    init(_ gridColumn: NSGridColumn) {
        self.gridColumn = gridColumn
        _isHidden = gridColumn.isHidden
        _leadingPadding = gridColumn.leadingPadding
        _trailingPadding = gridColumn.trailingPadding
        _width = gridColumn.width
        _xPlacement = gridColumn.xPlacement
    }
    
    weak var gridColumn: NSGridColumn? {
        didSet {
            guard let gridColumn = gridColumn else { return }
            gridColumn.views = _views
            gridColumn.isHidden = _isHidden
            gridColumn.leadingPadding = _leadingPadding
            gridColumn.trailingPadding = _trailingPadding
            gridColumn.width = width
            gridColumn.xPlacement = _xPlacement
            _views = []
        }
    }
    var _views: [NSView?] = []
    var _isHidden: Bool = false
    var _leadingPadding: CGFloat = 0.0
    var _trailingPadding: CGFloat = 0.0
    var _width: CGFloat = 1.1754943508222875e-38
    var _xPlacement: NSGridCell.Placement = .inherited
    
    public var description: String {
        "GridColumn(views: \(views.count), xPlacement: \(xPlacement),  width: \(width))"
    }
    
    public var debugDescription: String {
        let views = views.compactMap({ if let view = $0 { return "\(type(of: view))"} else { return "Empty"} })
        var strings = ["GridColumn:"]
        strings += "  - views: [\(views.joined(separator: ", "))]"
        strings += "  - xPlacement: \(xPlacement)"
        strings += "  - width: \(width == 1.1754943508222875e-38 ? "automatic" : "\(width)")"
        strings += "  - leadingPadding: \(leadingPadding), trailingPadding: \(trailingPadding)"
        strings += "  - isHidden: \(isHidden)"
        return strings.joined(separator: "\n")
    }
}

#endif
