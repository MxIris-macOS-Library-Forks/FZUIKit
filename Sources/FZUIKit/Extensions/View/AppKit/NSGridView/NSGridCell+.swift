//
//  NSGridCell+.swift
//
//
//  Created by Florian Zand on 22.03.25.
//

#if os(macOS)
import AppKit

public extension NSGridCell {
    /// The column indexes of the cell.
    var columnIndexes: [Int] {
        guard let cells = column?.cells, let startIndex = cells.firstIndex(of: self), let endIndex = cells.lastIndex(of: self) else { return [] }
        return (startIndex...endIndex).map({$0})
    }
    
    /// The row indexes of the cell.
    var rowIndexes: [Int] {
        guard let cells = row?.cells, let startIndex = cells.firstIndex(of: self), let endIndex = cells.lastIndex(of: self) else { return [] }
        return (startIndex...endIndex).map({$0})
    }
    
    /// The grid cell above.
    var topCell: NSGridCell? {
        guard let row = row, let column = column, let gridView = row.gridView else { return nil }
        let rowIndex = gridView.index(of: row)
        guard rowIndex > 0 else { return nil }
        return gridView.cell(atColumnIndex: gridView.index(of: column), rowIndex: rowIndex-1)
    }
    
    /// The grid bellow.
    var bottomCell: NSGridCell? {
        guard let row = row, let column = column, let gridView = row.gridView else { return nil }
        let rowIndex = gridView.index(of: row)
        guard rowIndex+1 < gridView.numberOfRows else { return nil }
        return gridView.cell(atColumnIndex: gridView.index(of: column), rowIndex: rowIndex+1)
    }
    
    /// The grid cell leading.
    var leadingCell: NSGridCell? {
        guard let row = row, let column = column, let gridView = row.gridView else { return nil }
        let columnIndex = gridView.index(of: column)
        guard columnIndex > 0 else { return nil }
        return gridView.cell(atColumnIndex: columnIndex-1, rowIndex: gridView.index(of: row))
    }
    
    /// The grid cell trailing.
    var trailingCell: NSGridCell? {
        guard let row = row, let column = column, let gridView = row.gridView else { return nil }
        let columnIndex = gridView.index(of: column)
        guard columnIndex+1 < gridView.numberOfColumns else { return nil }
        return gridView.cell(atColumnIndex: columnIndex+1, rowIndex: gridView.index(of: row))
    }
    
    internal var rowCells: [NSGridCell] {
        row?.cells ?? []
    }
    
    internal var columnCells: [NSGridCell] {
        column?.cells ?? []
    }
    
    internal var headOfMergedCell: NSGridCell? {
        get { value(forKey: "_headOfMergedCell") as? NSGridCell }
        set { setValue(newValue, forKey: "_headOfMergedCell")}
    }
    
    internal func unmerge() {
        guard let headCell = headOfMergedCell else { return }
        columnCells.unmerge(headCell)
        rowCells.unmerge(headCell)
    }
}

fileprivate extension Collection where Element == NSGridCell {
    func unmerge(_ headCell: NSGridCell, unmergeAll: Bool = false) {
        if !unmergeAll {
            guard let index = firstIndex(where: { $0.headOfMergedCell === headCell }) else { return }
            self[safe: index...].filter({ $0.headOfMergedCell === headCell }).reversed().forEach({ $0.headOfMergedCell = nil })
            let filtered = filter({ $0.headOfMergedCell === headCell })
            if filtered.count == 1 {
                filtered.forEach({ $0.headOfMergedCell = nil })
            }
        } else {
            filter({ $0.headOfMergedCell === headCell }).reversed().forEach({ $0.headOfMergedCell = nil })
        }
    }
}

#endif
