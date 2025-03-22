//
//  GridRow.swift
//
//
//  Created by Florian Zand on 23.02.24.
//

#if os(macOS)
import AppKit
import FZSwiftUtils

/// A row within a grid view.
public class GridRow: CustomStringConvertible, CustomDebugStringConvertible {
    
    /// The grid view of the row.
    public var gridView: NSGridView? {
        gridRow?.gridView
    }
    
    /// Merges the cells at the specified range.
    public func mergeCells(in range: Range<Int>) {
        guard numberOfCells > 0 else { return }
        gridRow?.mergeCells(in: range.clamped(max: numberOfCells).nsRange)
    }
    
    /// Merges the cells at the specified range.
    public func mergeCells(in range: ClosedRange<Int>) {
        mergeCells(in: range.lowerBound..<range.upperBound-1)
    }
    
    /// The content views of the grid row cells.
    public var views: [NSView?] {
        get { gridRow?.views ?? _views }
        set {
            if let gridRow = self.gridRow {
                gridRow.views = newValue
            } else {
                _views = newValue
            }
        }
    }
    
    /// Sets the content views of the grid row cells.
    @discardableResult
    public func views(@NSGridView.Builder _ views: () -> [NSView]) -> Self {
        self.views = views()
        return self
    }
    
    /// Sets the content views of the grid row cells.
    @discardableResult
    public func views(_ views: [NSView]) -> Self {
        self.views = views
        return self
    }
    
    /// A Boolean value that indicates whether the row is hidden.
    public var isHidden: Bool {
        get { gridRow?.isHidden ?? _isHidden }
        set {
            gridRow?.isHidden = newValue
            _isHidden = newValue
        }
    }
    
    /// Sets the boolean value that indicates whether the row is hidden.
    @discardableResult
    public func isHidden(_ isHidden: Bool) -> Self {
        self.isHidden = isHidden
        return self
    }
    
    /// The number of cells of the row.
    public var numberOfCells: Int {
        get { gridRow?.numberOfCells ?? _views.count }
    }
    
    /// The top padding of the row.
    public var topPadding: CGFloat {
        get { gridRow?.topPadding ?? _topPadding }
        set {
            gridRow?.topPadding = newValue
            _topPadding = newValue
        }
    }
    
    /// Sets the top padding of the row.
    @discardableResult
    public func topPadding(_ padding: CGFloat) -> Self {
        topPadding = padding
        return self
    }
    
    /// The bottom padding of the row.
    public var bottomPadding: CGFloat {
        get { gridRow?.bottomPadding ?? _bottomPadding }
        set {
            gridRow?.bottomPadding = newValue
            _bottomPadding = newValue
        }
    }
    
    /// Sets the bottom padding of the row.
    @discardableResult
    public func bottomPadding(_ padding: CGFloat) -> Self {
        bottomPadding = padding
        return self
    }
    
    /// The row alignment.
    public var rowAlignment: NSGridRow.Alignment {
        get { gridRow?.rowAlignment ?? _rowAlignment }
        set {
            gridRow?.rowAlignment = newValue
            _rowAlignment = newValue
        }
    }
    
    /// Sets the row alignment.
    @discardableResult
    public func rowAlignment(_ alignment: NSGridRow.Alignment) -> Self {
        rowAlignment = alignment
        return self
    }
    
    /// The row height.
    public var height: CGFloat {
        get { gridRow?.height ?? _height }
        set {
            gridRow?.height = newValue
            _height = newValue
        }
    }
    
    /// Sets the row height.
    @discardableResult
    public func height(_ height: CGFloat) -> Self {
        self.height = height
        return self
    }
    
    /// The y-placement of the row.
    public var yPlacement: NSGridCell.Placement {
        get { gridRow?.yPlacement ?? _yPlacement }
        set {
            gridRow?.yPlacement = newValue
            _yPlacement = newValue
        }
    }
    
    /// Sets the y-placement of the row.
    @discardableResult
    public func yPlacement(_ placement: NSGridCell.Placement) -> Self {
        yPlacement = placement
        return self
    }
    
    /// Creates a grid row with the specified views.
    public init(@NSGridView.Builder _ views: () -> [NSView?]) {
        _views = views()
    }
    
    /// Creates a grid row with the specified views.
    public init(views: [NSView?]) {
        _views = views
    }
    
    /// Creates a grid row.
    public init() {
        
    }
    
    init(_ gridRow: NSGridRow) {
        self.gridRow = gridRow
        _isHidden = gridRow.isHidden
        _topPadding = gridRow.topPadding
        _bottomPadding = gridRow.bottomPadding
        _height = gridRow.height
        _yPlacement = gridRow.yPlacement
        _rowAlignment = gridRow.rowAlignment
    }
    
    weak var gridRow: NSGridRow?
    var _views: [NSView?] = []
    var _isHidden: Bool = false
    var _topPadding: CGFloat = 0.0
    var _bottomPadding: CGFloat = 0.0
    var _height: CGFloat = 1.1754943508222875e-38
    var _yPlacement: NSGridCell.Placement = .inherited
    var _rowAlignment: NSGridRow.Alignment = .inherited
    
    public var description: String {
        return "GridRow(views: \(views.count), yPlacement: \(yPlacement),  height: \(height))"
    }
    
    public var debugDescription: String {
        let views = views.compactMap({ if let view = $0 { return "\(type(of: view))"} else { return "Empty"} })
        var strings = ["GridColumn:"]
        strings += "  - views: [\(views.joined(separator: ", "))]"
        strings += "  - yPlacement: \(yPlacement)"
        strings += "  - rowAlignment: \(rowAlignment)"
        strings += "  - height: \(height == 1.1754943508222875e-38 ? "automatic" : "\(height)")"
        strings += "  - bottomPadding: \(bottomPadding), topPadding: \(topPadding)"
        strings += "  - isHidden: \(isHidden)"
        return strings.joined(separator: "\n")
    }
}

extension NSGridRow.Alignment: CustomStringConvertible {
    public var description: String {
        switch self {
        case .inherited: return "inherited"
        case .firstBaseline: return "firstBaseline"
        case .lastBaseline: return "lastBaseline"
        default: return "none"
        }
    }
}

#endif
