//
//  NSTableView+ReconfigurateRows.swift
//
//
//  Created by Florian Zand on 18.05.22.
//

#if os(macOS)
import AppKit
import FZSwiftUtils

extension NSTableView {
    /**
     Updates the data for the rows at the indexes you specify, preserving the existing row views and cells for the rows.

     To update the contents of existing (including prefetched) cells without replacing them with new row views nad cells, use this method instead of `reloadData(forRowIndexes:columnIndexes:)`. For optimal performance, choose to reconfigure rows instead of reloading rows unless you have an explicit need to replace the existing row view or cells with new.

     Your cell provider must dequeue the same type of cell for the provided index path, and must return the same existing cell for a given index path. Because this method reconfigures existing cells, the table view doesn’t call `prepareForReuse()` for each cell dequeued. If you need to return a different type of cell for an index path, use `reloadData(forRowIndexes:columnIndexes:)` instead.
     
     The same applies to your row view provider.

     - Parameters:
        - indexes: The indexes you want to update.
     */
    public func reconfigureRows(at indexes: IndexSet) {
        Self.swizzleViewRegistration()
        guard let delegate = delegate else { return }
        let indexes = indexes.filter({$0 < numberOfRows})
        let columns = tableColumns
        
        for row in indexes {
            if delegate.tableView?(self, isGroupRow: row) ?? false {
                if rowView(atRow: row, makeIfNecessary: false) != nil {
                    reconfigureIndexPath = IndexPath(item: row, section: 0)
                    _ = delegate.tableView?(self, viewFor: nil, row: row)
                }
            } else {
                for (index, column) in columns.enumerated() {
                    if view(atColumn: index, row: row, makeIfNecessary: false) != nil {
                        reconfigureIndexPath = IndexPath(item: row, section: index)
                        _ = delegate.tableView?(self, viewFor: column, row: row)
                    }
                    if rowView(atRow: row, makeIfNecessary: false) != nil {
                        reconfigureIndexPath = IndexPath(item: row, section: -1)
                        _ = delegate.tableView?(self, rowViewForRow: row)
                    }
                }
            }
        }
        reconfigureIndexPath = nil
    }
    
    public func reconfigureRows(at indexes: IndexSet, columns: [NSUserInterfaceItemIdentifier]) {
        reconfigureRows(at: indexes, columns: IndexSet(columns.compactMap({ column(withIdentifier: $0) })))
    }
    
    public func reconfigureRows(at rows: IndexSet, columns: IndexSet) {
        Self.swizzleViewRegistration()
        guard let delegate = delegate else { return }
        let tableColumns = tableColumns
        let columns = columns.filter({ $0 < tableColumns.count })
        guard columns.isEmpty else { return }
        for row in rows.filter({$0 < numberOfRows}) {
            if delegate.tableView?(self, isGroupRow: row) ?? false {
                if rowView(atRow: row, makeIfNecessary: false) != nil {
                    reconfigureIndexPath = IndexPath(item: row, section: 0)
                    _ = delegate.tableView?(self, viewFor: nil, row: row)
                }
            } else {
                for column in columns {
                    if view(atColumn: column, row: row, makeIfNecessary: false) != nil {
                        reconfigureIndexPath = IndexPath(item: row, section: column)
                        _ = delegate.tableView?(self, viewFor: tableColumns[column], row: row)
                    }
                    if rowView(atRow: row, makeIfNecessary: false) != nil {
                        reconfigureIndexPath = IndexPath(item: row, section: -1)
                        _ = delegate.tableView?(self, rowViewForRow: row)
                    }
                }
            }
        }
        reconfigureIndexPath = nil
    }

    var reconfigureIndexPath: IndexPath? {
        get { getAssociatedValue("reconfigureIndexPath") }
        set { setAssociatedValue(newValue, key: "reconfigureIndexPath")
        }
    }
}
#endif
