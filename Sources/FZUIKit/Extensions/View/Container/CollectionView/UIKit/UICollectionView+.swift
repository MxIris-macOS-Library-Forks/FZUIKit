//
//  UICollectionView+.swift
//
//
//  Created by Florian Zand on 26.11.23.
//

#if os(iOS) || os(tvOS)
import FZSwiftUtils
import UIKit

extension UICollectionView {
    /// The currently selected collection view cells.
    public var selectedCells: [UICollectionViewCell] {
        (indexPathsForSelectedItems ?? []).compactMap { cellForItem(at: $0) }
    }

    /// Returns the index paths of the currently displayed cells. Unlike `indexPathsForVisibleItems()`  it only returns the cells with visible frame.
    public func displayingIndexPaths() -> [IndexPath] {
        (displayingCells().compactMap { self.indexPath(for: $0) }).sorted()
    }

    /// An array of all displayed cells. Unlike `visibleCells()` it only returns the items with visible frame.
    public func displayingCells() -> [UICollectionViewCell] {
        let visibleRect = CGRect(origin: contentOffset, size: bounds.size)
        return visibleCells.filter { $0.frame.intersects(visibleRect) }
    }

    /**
     Selects the specified items and optionally scrolls the items into position.

     - Parameters:
        - indexPaths: The index paths of the items to select.
        - extend: `true` if the selection should be extended, `false` if the current selection should be changed.
        - animated: `true` if you want to animate the selection, and `false` if the change should be immediate.
        - scrollPosition: The options for scrolling the newly selected items into view.
     */
    func selectItems(at indexPaths: Set<IndexPath>, byExtendingSelection extend: Bool,  animated: Bool, scrollPosition: ScrollPosition = []) {
        let deselect = extend ? [] : (indexPathsForSelectedItems ?? []).filter({ !indexPaths.contains($0) })
        selectItems(at: indexPaths, animated: animated, scrollPosition: scrollPosition)
        deselectItems(at: deselect, animated: animated)
    }

    /**
     Changes the collection view layout animated.

     - Parameters:
        - layout: The new layout object for the collection view.
        - animationDuration: The duration for the collection view animating changes from the current layout to the new layout. Specify a value of `0.0` to make the change without animations.
        - completion: A block object to be executed when the animation sequence ends. This block has no return value and takes a single Boolean argument indicating whether or not the animations actually finished before the completion handler was called. If the duration of the animation is `0.0`, this block is performed at the beginning of the next run loop cycle. This parameter may be NULL.
     */
    func setCollectionViewLayout(_ layout: UICollectionViewLayout, animationDuration: CGFloat, completion: ((Bool) -> Void)? = nil) {
        if animationDuration > 0.0 {
            UIView.animate(withDuration: animationDuration, animations: {
                self.setCollectionViewLayout(layout, animated: true)
            }, completion: completion)
        } else {
            setCollectionViewLayout(layout, animated: false)
        }
    }

    var centerIndexPath: IndexPath? {
        let centerPoint = CGRect(origin: contentOffset, size: bounds.size).center
        if let cell = visibleCells.first(where: { $0.frame.contains(centerPoint) }) {
            return indexPath(for: cell)
        }
        let displayingIndexPath = displayingIndexPaths()
        guard !displayingIndexPath.isEmpty else { return nil }
        let index = Int((Double(displayingIndexPath.count) / 2.0).rounded(toPlaces: 0))
        return displayingIndexPath[safe: index]
    }

    func scrollToItems(at indexPaths: Set<IndexPath>, at scrollPosition: UICollectionView.ScrollPosition, animated: Bool = false) {
        let indexPaths = indexPaths.compactMap({ if let frame = layoutAttributesForItem(at: $0)?.frame { return (indexPath: $0, frame: frame) } else { return nil }})
        guard !indexPaths.isEmpty else { return }
        let frames = indexPaths.compactMap({$0.frame})
        
        if let centeredRect = frames.centeredRect, let indexPath = indexPaths[safe: frames.firstIndex(of: centeredRect)!]?.indexPath {
            scrollToItem(at: indexPath, at: scrollPosition, animated: animated)
        } else {
            scrollRectToVisible(frames.union(), animated: animated)
        }
    }

    /**
     The handlers for the displaying cells.

     The handlers get called whenever the collection view is displaying new cells (e.g. when the enclosing scrollview gets scrolled to new cells).
     */
    public var displayingCellsHandlers: DisplayingItemsHandlers {
        get { getAssociatedValue("displayingItemsHandlers", initialValue: DisplayingItemsHandlers()) }
        set {
            setAssociatedValue(newValue, key: "displayingItemsHandlers")
            setupDisplayingItemsTracking()
        }
    }

    /**
     Handlers for the displaying cells.

     The handlers get called whenever the collection view is displaying new cells.
     */
    public struct DisplayingItemsHandlers {
        /// Handler that is called whenever cells start getting displayed.
        var isDisplaying: (([IndexPath]) -> Void)?
        /// Handler that is called whenever cells end getting displayed.
        var didEndDisplaying: (([IndexPath]) -> Void)?
    }

    var previousDisplayingIndexPaths: [IndexPath] {
        get { getAssociatedValue("previousDisplayingIndexPaths", initialValue: []) }
        set {
            setAssociatedValue(newValue, key: "previousDisplayingIndexPaths")
        }
    }

    var contentOffsetObserver: KeyValueObservation? {
        get { getAssociatedValue("contentOffsetObserver") }
        set { setAssociatedValue(newValue, key: "contentOffsetObserver") }
    }

    @objc func didScroll() {
        let isDisplaying = displayingCellsHandlers.isDisplaying
        let didEndDisplaying = displayingCellsHandlers.didEndDisplaying
        guard isDisplaying != nil || didEndDisplaying != nil else { return }

        let displayingIndexPaths = displayingIndexPaths()
        let previousDisplayingIndexPaths = previousDisplayingIndexPaths
        guard displayingIndexPaths != previousDisplayingIndexPaths else { return }
        self.previousDisplayingIndexPaths = displayingIndexPaths

        if let isDisplaying = isDisplaying {
            let indexPaths = displayingIndexPaths.filter { previousDisplayingIndexPaths.contains($0) == false }
            if indexPaths.isEmpty == false {
                isDisplaying(indexPaths)
            }
        }

        if let didEndDisplaying = didEndDisplaying {
            let indexPaths = previousDisplayingIndexPaths.filter { displayingIndexPaths.contains($0) == false }
            if indexPaths.isEmpty == false {
                didEndDisplaying(indexPaths)
            }
        }
    }

    func setupDisplayingItemsTracking() {
        if displayingCellsHandlers.isDisplaying != nil || displayingCellsHandlers.didEndDisplaying != nil {
            if contentOffsetObserver == nil {
                contentOffsetObserver = observeChanges(for: \.contentOffset, handler: { [weak self] old, new in
                    guard let self = self, old != new else { return }
                    self.didScroll()
                })
            }
        } else {
            contentOffsetObserver = nil
        }
    }
}

fileprivate extension CGRect {
    func contains(any points: [CGPoint]) -> Bool {
        for point in points {
            if contains(point) {
                return true
            }
        }
        return false
    }
}

#endif
