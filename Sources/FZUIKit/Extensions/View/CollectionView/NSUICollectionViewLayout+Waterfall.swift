//
//  NSUICollectionViewLayout+Waterfall.swift
//
//  Parts taken from:
//  Created by Nicholas Tau on 6/30/14.
//  Copyright (c) 2014 Nicholas Tau. All rights reserved.
//
//  Created by Florian Zand on 06.06.22.
//

#if os(macOS) || os(iOS) || os(tvOS)
    import FZSwiftUtils
    #if os(macOS)
        import AppKit
    #elseif canImport(UIKit)
        import UIKit
    #endif

    public extension NSUICollectionViewLayout {
        /**
         Creates a waterfall collection view layout with the specifed amount of columns.
         
         - Parameters:
            - columnCount: The amount of columns.
            - spacing: The spacing between the items.
            - insets: The layout insets.
            - itemSizeProvider: The handler that provides the item sizes..
         */
        static func waterfall(columnCount: Int = 2, spacing: CGFloat = 8.0, insets: NSUIEdgeInsets = .init(8.0), isPinchable: Bool = false, itemSizeProvider: @escaping (IndexPath) -> CGSize) -> WaterfallLayout {
            let layout = WaterfallLayout(columnCount: columnCount, isPinchable: isPinchable, itemSizeProvider: itemSizeProvider)
            layout.minimumInteritemSpacing = spacing
            layout.minimumColumnSpacing = spacing
            layout.sectionInset = insets
            return layout
        }
        
        class WaterfallLayout: NSUICollectionViewLayout, PinchableCollectionViewLayout {            
            public typealias ItemSizeProvider = (IndexPath) -> CGSize

            public convenience init(columnCount: Int = 2, isPinchable: Bool = false, itemSizeProvider: @escaping ItemSizeProvider) {
                self.init()
                self.itemSizeProvider = itemSizeProvider
                self.isPinchable = isPinchable
            }

            open var itemSizeProvider: ItemSizeProvider? {
                didSet { invalidateLayout() }
            }
            
            open var isPinchable: Bool = false
            
            func setupPinch() {
                guard let collectionView = collectionView else { return }
                if isPinchable, collectionView.pinchColumnsGestureRecognizer == nil {
                    collectionView.pinchColumnsGestureRecognizer = PinchColumnsGestureRecognizer()
                    collectionView.addGestureRecognizer(collectionView.pinchColumnsGestureRecognizer!)
                } else if !isPinchable, let gestureRecognizer = collectionView.pinchColumnsGestureRecognizer {
                    collectionView.removeGestureRecognizer(gestureRecognizer)
                    collectionView.pinchColumnsGestureRecognizer = nil
                }
            }

            open var columnCount: Int = 2 {
                didSet {
                    columnCount = columnCount.clamped(min: minColumnCount)
                    if let maxColumnCount = maxColumnCount {
                        columnCount = columnCount.clamped(to: 0...maxColumnCount)
                    }
                    guard oldValue != columnCount else { return }
                    invalidateLayout(animated: animationDuration ?? 0.0) }
            }
            
            open var minColumnCount: Int = 1 {
                didSet {
                    minColumnCount = minColumnCount.clamped(min: 1)
                    if columnCount < minColumnCount {
                        columnCount = minColumnCount
                    }
                }
            }
            
            open var maxColumnCount: Int? {
                didSet {
                    if let maxColumnCount = maxColumnCount, columnCount > maxColumnCount {
                        columnCount = maxColumnCount
                    }
                }
            }

            open var minimumColumnSpacing: CGFloat = 10 {
                didSet {
                    guard oldValue != minimumColumnSpacing else { return }
                    minimumColumnSpacing = minimumColumnSpacing.clamped(min: 0)
                    invalidateLayout()
                }
            }

            open var minimumInteritemSpacing: CGFloat = 10 {
                didSet {
                    guard oldValue != minimumInteritemSpacing else { return }
                    minimumInteritemSpacing = minimumInteritemSpacing.clamped(min: 0)
                    invalidateLayout()
                }
            }

            open var headerHeight: CGFloat = 0 {
                didSet {
                    guard oldValue != headerHeight else { return }
                    headerHeight = headerHeight.clamped(min: 0)
                    invalidateLayout()
                }
            }

            open var footerHeight: CGFloat = 0 {
                didSet {
                    guard oldValue != footerHeight else { return }
                    footerHeight = footerHeight.clamped(min: 0)
                    invalidateLayout()
                }
            }

            public var sectionInset: NSUIEdgeInsets = .zero {
                didSet {
                    guard oldValue != sectionInset else { return }
                    invalidateLayout()
                }
            }

            public var itemRenderDirection: ItemRenderDirection = .shortestFirst {
                didSet {
                    guard oldValue != itemRenderDirection else { return }
                    invalidateLayout()
                }
            }

            public var sectionInsetReference: SectionInsetReference = .fromContentInset {
                didSet {
                    guard oldValue != sectionInsetReference else { return }
                    invalidateLayout()
                }
            }

            /*
             public var delegate: NSUICollectionViewWaterfallLayoutDelegate? {
             get { return collectionView!.delegate as? NSUICollectionViewWaterfallLayoutDelegate } }
             */

            public var animationDuration: TimeInterval? = 0.2

            private var columnHeights: [[CGFloat]] = []
            private var sectionItemAttributes: [[NSUICollectionViewLayoutAttributes]] = []
            private var allItemAttributes: [NSUICollectionViewLayoutAttributes] = []
            private var headersAttributes: [Int: NSUICollectionViewLayoutAttributes] = [:]
            private var footersAttributes: [Int: NSUICollectionViewLayoutAttributes] = [:]
            private var unionRects: [CGRect] = []
            private let unionSize = 20

            private func columnCount(forSection _: Int) -> Int {
                var cCount = columnCount
                if cCount == -1 {
                    cCount = columnCount
                }
                return cCount
            }

            #if os(macOS)
                private var collectionViewContentWidth: CGFloat {
                    var insets: NSUIEdgeInsets = .zero
                    switch sectionInsetReference {
                    case .fromContentInset:
                        if let contentInsets = collectionView?.enclosingScrollView?.contentInsets {
                            insets = contentInsets
                        } else { insets = .zero }
                    case .fromSafeArea:
                        if #available(macOS 11.0, *) {
                            insets = collectionView!.safeAreaInsets
                        } else { insets = .zero }
                    }
                    return collectionView!.bounds.size.width - insets.left - insets.right
                }

            #elseif canImport(UIKit)
                private var collectionViewContentWidth: CGFloat {
                    var insets: NSUIEdgeInsets = .zero
                    switch sectionInsetReference {
                    case .fromContentInset:
                        insets = collectionView?.contentInset ?? .zero
                    case .fromSafeArea:
                        insets = collectionView?.adjustedContentInset ?? .zero
                    }
                    return collectionView!.bounds.size.width - insets.left - insets.right
                }
            #endif

            private func collectionViewContentWidth(ofSection _: Int) -> CGFloat {
                var insets = sectionInset
                if insets.bottom == -1 {
                    insets = sectionInset
                }
                return collectionViewContentWidth - insets.left - insets.right
            }
            
            public func itemWidth(inSection section: Int) -> CGFloat {
                let columnCount = columnCount(forSection: section)
                let spaceColumCount = CGFloat(columnCount - 1)
                let width = collectionViewContentWidth(ofSection: section)
                return floor((width - (spaceColumCount * minimumColumnSpacing)) / CGFloat(columnCount))
            }
            
            override public func prepare() {
                super.prepare()
                
                setupPinch()
                let numberOfSections = collectionView!.numberOfSections
                if numberOfSections == 0 {
                    return
                }

                headersAttributes = [:]
                footersAttributes = [:]
                unionRects = []
                allItemAttributes = []
                sectionItemAttributes = []
                columnHeights = (0 ..< numberOfSections).map { section in
                    let columnCount = self.columnCount(forSection: section)
                    let sectionColumnHeights = (0 ..< columnCount).map { CGFloat($0) }
                    return sectionColumnHeights
                }

                var top: CGFloat = 0.0
                var attributes = NSUICollectionViewLayoutAttributes()

                for section in 0 ..< numberOfSections {
                    // MARK: 1. Get section-specific metrics (minimumInteritemSpacing, sectionInset)

                    var minimumInteritemSpacing = minimumInteritemSpacing
                    if minimumInteritemSpacing == -1 {
                        minimumInteritemSpacing = self.minimumInteritemSpacing
                    }

                    var sectionInsets = sectionInset
                    //     var sectionInsets  =  self.sectionInset
                    if sectionInsets.bottom == -1 {
                        sectionInsets = sectionInset
                    }

                    let columnCount = columnHeights[section].count
                    let itemWidth = itemWidth(inSection: section)

                    // MARK: 2. Section header

                    var heightHeader = headerHeight
                    if heightHeader == -1 {
                        heightHeader = headerHeight
                    }
                    if heightHeader > 0 {
                        attributes = NSUICollectionViewLayoutAttributes(forSupplementaryViewOfKind: NSUICollectionView.elementKindSectionHeader, with: IndexPath(item: 0, section: section))
                        attributes.frame = CGRect(x: 0, y: top, width: collectionView!.bounds.size.width, height: heightHeader)
                        headersAttributes[section] = attributes
                        allItemAttributes.append(attributes)

                        top = attributes.frame.maxY
                    }
                    top += sectionInsets.top
                    columnHeights[section] = [CGFloat](repeating: top, count: columnCount)

                    // MARK: 3. Section items

                    let itemCount = collectionView!.numberOfItems(inSection: section)
                    var itemAttributes: [NSUICollectionViewLayoutAttributes] = []

                    // Item will be put into shortest column.
                    for idx in 0 ..< itemCount {
                        let indexPath = IndexPath(item: idx, section: section)

                        let columnIndex = nextColumnIndexForItem(idx, inSection: section)
                        let xOffset = sectionInsets.left + (itemWidth + minimumColumnSpacing) * CGFloat(columnIndex)

                        let yOffset = columnHeights[section][columnIndex]
                        var itemHeight: CGFloat = 0.0
                        if let itemSize = itemSizeProvider?(indexPath),
                           itemSize.height > 0
                        {
                            itemHeight = itemSize.height
                            if itemSize.width > 0 {
                                itemHeight = floor(itemHeight * itemWidth / itemSize.width)
                            } // else use default item width based on other parameters
                        }
                        #if os(macOS)
                            attributes = NSUICollectionViewLayoutAttributes(forItemWith: indexPath)
                        #elseif canImport(UIKit)
                            attributes = NSUICollectionViewLayoutAttributes(forCellWith: indexPath)
                        #endif
                        attributes.frame = CGRect(x: xOffset, y: yOffset, width: itemWidth, height: itemHeight)
                        itemAttributes.append(attributes)
                        allItemAttributes.append(attributes)
                        columnHeights[section][columnIndex] = attributes.frame.maxY + minimumInteritemSpacing
                    }
                    sectionItemAttributes.append(itemAttributes)

                    // MARK: 4. Section footer

                    let columnIndex = longestColumnIndex(inSection: section)
                    top = columnHeights[section][columnIndex] - minimumInteritemSpacing + sectionInsets.bottom
                    var footerHeight = footerHeight
                    if footerHeight == -1 {
                        footerHeight = self.footerHeight
                    }

                    if footerHeight > 0 {
                        attributes = NSUICollectionViewLayoutAttributes(forSupplementaryViewOfKind: NSUICollectionView.elementKindSectionFooter, with: IndexPath(item: 0, section: section))
                        attributes.frame = CGRect(x: 0, y: top, width: collectionView!.bounds.size.width, height: footerHeight)
                        footersAttributes[section] = attributes
                        allItemAttributes.append(attributes)
                        top = attributes.frame.maxY
                    }

                    columnHeights[section] = [CGFloat](repeating: top, count: columnCount)
                }

                var idx = 0
                let itemCounts = allItemAttributes.count
                while idx < itemCounts {
                    let rect1 = allItemAttributes[idx].frame
                    idx = min(idx + unionSize, itemCounts) - 1
                    let rect2 = allItemAttributes[idx].frame
                    unionRects.append(rect1.union(rect2))
                    idx += 1
                }
            }

            override public var collectionViewContentSize: CGSize {
                if collectionView!.numberOfSections == 0 {
                    return .zero
                }

                var contentSize = collectionView!.bounds.size
                contentSize.width = collectionViewContentWidth

                if let height = columnHeights.last?.first {
                    contentSize.height = height
                    return contentSize
                }
                return .zero
            }

            override public func layoutAttributesForItem(at indexPath: IndexPath) -> NSUICollectionViewLayoutAttributes? {
                if indexPath.section >= sectionItemAttributes.count {
                    return nil
                }
                let list = sectionItemAttributes[indexPath.section]
                if indexPath.item >= list.count {
                    return nil
                }
                return list[indexPath.item]
            }

            override public func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> NSUICollectionViewLayoutAttributes {
                var attribute: NSUICollectionViewLayoutAttributes?
                if elementKind == NSUICollectionView.elementKindSectionHeader {
                    attribute = headersAttributes[indexPath.section]
                } else if elementKind == NSUICollectionView.elementKindSectionFooter {
                    attribute = footersAttributes[indexPath.section]
                }
                return attribute ?? NSUICollectionViewLayoutAttributes()
            }

            override public func layoutAttributesForElements(in rect: CGRect) -> [NSUICollectionViewLayoutAttributes] {
                var begin = 0, end = unionRects.count

                if let i = unionRects.firstIndex(where: { rect.intersects($0) }) {
                    begin = i * unionSize
                }
                if let i = unionRects.lastIndex(where: { rect.intersects($0) }) {
                    end = min((i + 1) * unionSize, allItemAttributes.count)
                }
                return allItemAttributes[begin ..< end]
                    .filter { rect.intersects($0.frame) }
            }

            override public func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
                newBounds.width != collectionView?.bounds.width
            }

            private func shortestColumnIndex(inSection section: Int) -> Int {
                columnHeights[section].enumerated()
                    .min(by: { $0.element < $1.element })?
                    .offset ?? 0
            }

            private func longestColumnIndex(inSection section: Int) -> Int {
                columnHeights[section].enumerated()
                    .max(by: { $0.element < $1.element })?
                    .offset ?? 0
            }

            private func nextColumnIndexForItem(_ item: Int, inSection section: Int) -> Int {
                var index = 0
                let columnCount = columnCount(forSection: section)
                switch itemRenderDirection {
                case .shortestFirst:
                    index = shortestColumnIndex(inSection: section)
                case .leftToRight:
                    index = item % columnCount
                case .rightToLeft:
                    index = (columnCount - 1) - (item % columnCount)
                }
                return index
            }
        }
    }

    public extension NSUICollectionViewLayout.WaterfallLayout {
        enum ItemRenderDirection: Int {
            case shortestFirst
            case leftToRight
            case rightToLeft
        }

        enum SectionInsetReference {
            case fromContentInset
            @available(macOS 11, *)
            case fromSafeArea
        }
    }

#if os(macOS)
protocol PinchableCollectionViewLayout: AnyObject {
    var columnCount: Int { get set }
    var minColumnCount: Int { get }
    var maxColumnCount: Int? { get }
    var isPinchable: Bool { get }
}

extension NSCollectionView {
    var pinchColumnsGestureRecognizer: PinchColumnsGestureRecognizer? {
        get { getAssociatedValue("pinchColumnsGestureRecognizer", initialValue: nil) }
        set { setAssociatedValue(newValue, key: "pinchColumnsGestureRecognizer") }
    }
}

extension NSCollectionViewLayout {
    var _columnCount: Int? {
        get { getAssociatedValue("columnCount", initialValue: nil) }
        set {
            guard newValue != _columnCount else { return }
            setAssociatedValue(newValue, key: "columnCount")
            if let newValue = newValue, let layout = columnLayoutInvalidation?(newValue) {
                collectionView?.setCollectionViewLayout(layout, animationDuration: 0.2)
            }
        }
    }
    
    var _minColumnCount: Int? {
        get { getAssociatedValue("minColumnCount", initialValue: nil) }
        set { setAssociatedValue(newValue, key: "minColumnCount") }
    }
    
    var _maxColumnCount: Int? {
        get { getAssociatedValue("maxColumnCount", initialValue: nil) }
        set { setAssociatedValue(newValue, key: "maxColumnCount") }
    }
    
    var columnLayoutInvalidation: ((_ columnCount: Int)->(NSCollectionViewLayout))? {
        get { getAssociatedValue("maxColumnCount", initialValue: nil) }
        set { setAssociatedValue(newValue, key: "maxColumnCount") }
    }
    
}

class PinchColumnsGestureRecognizer: NSMagnificationGestureRecognizer {
    var collectionView: NSCollectionView? {
        view as? NSCollectionView
    }
    
    var collectionViewLayout: NSCollectionViewLayout? {
        (view as? NSCollectionView)?.collectionViewLayout
    }
    
    var layout:  PinchableCollectionViewLayout? {
        if let layout = collectionViewLayout as? PinchableCollectionViewLayout, layout.isPinchable {
            return layout
        }
        return nil
    }
    
    var columnCount: Int {
        get { layout?.columnCount ?? collectionViewLayout?._columnCount ?? 2 }
        set {
            if let layout = layout {
                layout.columnCount = newValue
            } else {
                collectionViewLayout?._columnCount = newValue
            }
        }
    }
    
    var minColumnCount: Int {
        get { layout?.minColumnCount ?? collectionViewLayout?._minColumnCount ?? 2 }
    }
    
    var maxColumnCount: Int {
        get { layout?.maxColumnCount ?? collectionViewLayout?._maxColumnCount ?? 100000 }
    }
    
    init() {
        super.init(target: nil, action: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func keyDown(with event: NSEvent) {
        guard collectionView != nil else { return }
        if event.keyCode == 44 {
            columnCount = (columnCount + 1).clamped(to: minColumnCount...maxColumnCount)
        } else if event.keyCode == 30 {
            columnCount = (columnCount - 1).clamped(to: minColumnCount...maxColumnCount)
        }
        super.keyDown(with: event)
    }
    
    var initalColumnCount: Int = 0
    override var state: NSGestureRecognizer.State {
        didSet {
            guard collectionView != nil else { return }
            switch state {
            case .began:
                initalColumnCount = columnCount
            case .changed:
                columnCount = ((initalColumnCount + Int((magnification/(-0.5)).rounded())).clamped(to: minColumnCount...maxColumnCount))
            default: break
            }
        }
    }
}
#endif
#endif
