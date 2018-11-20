//
//  CircularScrollView.swift
//  CircularScrollView
//
//  Created by Daniele Margutti on 24/05/15.
//  Copyright (c) 2015 Daniele Margutti http://www.danielemargutti.com. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit

//MARK: CircularScrollViewDataSource Protocol

public protocol CircularScrollViewDataSource: class {
	/**
	Return the number of pages to show into the scroll view
	
	:param: scroll target circular scroll view instance
	
	:returns: number of pages to show
	*/
	func numberOfPagesInCircularScrollView(_ scroll: CircularScrollView) -> Int
	
	/**
	The view controller to use into given page index
	
	:param: scroll                target circular scroll view instance
	:param: viewControllerAtIndex view controller to show into given page
	
	:returns: view controller to show
	*/
	func circularScrollView(_ scroll: CircularScrollView, viewControllerAtIndex index: Int) -> UIViewController
}

//MARK: Delegate Protocol
@objc public protocol CircularScrollViewDelegate: class {
	/**
	This method is called when user scroll between pages. It's called continuously during the scroll.
	
	:param: scroll  target circular scroll view instance
	:param: forward true if scroll is forward, false if it's backward (backward/forward is calculated using the page indexes)
	:param: index   index of the current page (the predominant page rect)
	*/
	@objc optional func circularScrollView(_ scroll: CircularScrollView, willMoveForward forward: Bool, fromPage index: Int)
	
	/**
	This method is called when a scroll task is beginning and report the current page index
	
	:param: scroll    target circular scroll view instance
	:param: fromIndex current predominant page index
	*/
	@objc optional func circularScrollView(_ scroll: CircularScrollView, willScrollFromPage fromIndex : Int)
	
	/**
	This method is called at the end of a scrolling task and report the new current page
	
	:param: scroll  target circular scroll view instance
	:param: toIndex current end page index
	*/
	@objc optional func circularScrollView(_ scroll: CircularScrollView, didScrollToPage toIndex: Int)
	
	/**
	This method is called continuously during a scroll and report the offset of the scroll view
	
	:param: scroll target circular scroll view instance
	:param: offset offset of the scrollview (note: when number of pages > 1 scroll view has 2 more extra pages at start/end, with the relative offset)
	*/
	@objc optional func circularScrollView(_ scroll: CircularScrollView, didScroll offset: CGPoint)
}

//MARK: CircularScrollView

public class CircularScrollView: UIView, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
	//MARK: Public Properties
	/// Delegate of the Circular ScrollView
	weak public var delegate : CircularScrollViewDelegate?
	/// Data Source of the Circular ScrollView
	weak public var dataSource : CircularScrollViewDataSource? {
		didSet {
			self.reloadData()
		}
	}
	/// Yes to enable pagination for circular scroll view, default is true
	public var isPaginated: Bool = true {
		didSet {
            collectionView.isPagingEnabled = isPaginated
		}
	}
	/// Yes to enable circular scroll direction horizontally, false to use vertical layout
	public var horizontalScroll: Bool = true {
		didSet {
			if horizontalScroll == true {
                layout.scrollDirection = .horizontal
			} else {
                layout.scrollDirection = .vertical
			}
			collectionView.reloadData()
		}
	}

	//MARK: Private Variables
	private lazy var collectionView = UICollectionView(
        frame: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height),
        collectionViewLayout: layout)
	private var layout = UICollectionViewFlowLayout()
	private(set) var numberOfPages: Int = 0
	private var isDecelerating: Bool = false

	//MARK: Initialization
	override public init(frame: CGRect) {
		super.init(frame: frame)
		
		collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		collectionView.showsVerticalScrollIndicator = false
		collectionView.showsHorizontalScrollIndicator = false
		collectionView.register(CircularScrollViewCell.self, forCellWithReuseIdentifier: CircularScrollViewCell.identifier)
		collectionView.dataSource = self
		collectionView.delegate = self
		collectionView.backgroundColor = .clear

        if horizontalScroll == true {
            layout.scrollDirection = .horizontal
        } else {
            layout.scrollDirection = .vertical
        }
        collectionView.reloadData()

        collectionView.isPagingEnabled = isPaginated

        self.addSubview(collectionView)
	}

	required public init(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}


	//MARK: Public Methods
	
	/**
	Reload data inside the circular scrollview. If not specified scrollview try to reposition to previously loaded page index. You can however
	specify your own start page by passing it. Invalid page bounds are ignored, initial page setup is not animated.
	
	:param: moveToPage optional starting page
	*/
	public func reloadData(moveToPage: Int? = nil) {
		if dataSource == nil {
			return
		}

		numberOfPages = self.dataSource!.numberOfPagesInCircularScrollView(self)
		collectionView.reloadData()

		if let target = moveToPage {
            _ = self.moveToPage(index: target, animated: false)
		} else if let current = self.currentPage() {
			_ = self.moveToPage(index: current, animated: false)
		}
	}
	
	/**
	This function return a list of all (2) visible pages inside the scroll view.
	At index 0 you will find the current page (the page that occupies the largest area within the control).
	At index 1 you will find the other visible page (if any. it happends when you call this method during a scroll process)
	
	:returns: visible pages
	*/
	public func visiblePages() -> [Int] {
		if numberOfPages == 1 {
			return [0]
		}

		var pages: [Int] = []
		let visibleRect = self.visibleRect()
		var maxArea : CGFloat?
		var idxMaxArea : Int?

        (0..<(numberOfPages + 2)).forEach { k in

            let index = IndexPath(item: k, section: 0)
			guard let cell = collectionView.cellForItem(at: index) as? CircularScrollViewCell
                else { return }

            let intersection = cell.frame.intersection(visibleRect)

            if !intersection.isNull {
                pages.append(self.adjustedIndexForIndex(index: k))
                let area = intersection.width * intersection.height
                if area > (maxArea ?? 0) {
                    idxMaxArea = pages.count - 1
                    maxArea = area
                }
            }
		}
		
		if pages.count > 1 && idxMaxArea != nil {
			let value = pages[idxMaxArea!]
            pages.remove(at: idxMaxArea!)
			pages.insert(value, at: 0)
		}
		
		return pages
	}
	
	/**
	This method return the current page index
	
	:returns: current page index
	*/
	public func currentPage() -> Int! {
		let pages = self.visiblePages()
		if pages.count > 0 {
			return pages[0]
		} else {
			return nil
		}
	}
	
	/**
	This method return the visible rect of the circular scroll view. Keep in mind: circular scroll view has two extra pages,
	one before page 0 and another after the last page.
	
	:returns: visible rect inside the circular scrollview
	*/
	public func visibleRect() -> CGRect {
        let visibleRect = CGRect(
            x: collectionView.contentOffset.x,
            y: collectionView.contentOffset.y,
            width: collectionView.frame.width,
            height: collectionView.frame.height)
		return visibleRect
	}

	/**
	Use this method to move to a specified page of the control
	
	:param: index    index of the page
	:param: animated YES to animate the movement
	
	:returns: true if page is valid, false otherwise
	*/
	public func moveToPage(index: Int, animated: Bool) -> Bool {
		var finalPageIdx = index
		if finalPageIdx < 0 || finalPageIdx >= numberOfPages {
			return false
		}

		if numberOfPages > 1 {
			finalPageIdx = finalPageIdx+1
		}

		let indexPath = IndexPath(item: finalPageIdx, section: 0)
        let scrollPosition: UICollectionView.ScrollPosition = (horizontalScroll == true ? .left : .top)
		collectionView.scrollToItem(
            at: indexPath,
            at: scrollPosition,
            animated: animated)
		return true
	}
	
	//MARK: Collection View Delegate & DataSource
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
		let pageSize = self.pageSize()
		let offset = self.currentOffset()
		
		if offset >= ( pageSize * CGFloat((numberOfPages+1)) ) {
			if horizontalScroll == true {
                scrollView.contentOffset = CGPoint(x: pageSize, y: 0)
			} else {
                scrollView.contentOffset = CGPoint(x: 0, y: pageSize)
			}
		} else if offset <= 0 {
			let lastItemOffset = pageSize * CGFloat(numberOfPages)
			if horizontalScroll == true {
                scrollView.contentOffset = CGPoint(x: lastItemOffset, y: 0)
			} else {
                scrollView.contentOffset = CGPoint(x: 0, y: lastItemOffset)
			}
		}
		
		self.delegate?.circularScrollView?(self, didScroll: collectionView.contentOffset)
		
		if isDecelerating == false {
			var visiblePages = self.visiblePages()
			if visiblePages.count == 2 {
				let isMovingForward = ( visiblePages[1] > visiblePages[0])
				self.delegate?.circularScrollView?(self, willMoveForward: isMovingForward, fromPage: visiblePages[0])
			}
		}
	}

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isDecelerating = false

        guard let currentPage = self.currentPage()
            else { return }

		self.delegate?.circularScrollView?(self, willScrollFromPage: currentPage)
	}
	
    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
		isDecelerating = true
	}
	
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		isDecelerating = false
		self.delegate?.circularScrollView?(self, didScrollToPage: self.currentPage())
	}

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		switch numberOfPages {
		case 0...1:
			return numberOfPages
		default:
			return numberOfPages+2
		}
	}
	
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let idx = adjustedIndexForIndex(index: indexPath.item)
		let viewController = self.dataSource!.circularScrollView(self, viewControllerAtIndex: idx)
		viewController.view.frame = cell.contentView.bounds
		cell.contentView.addSubview(viewController.view)
	}

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CircularScrollViewCell.identifier, for: indexPath) as! CircularScrollViewCell
        cell.index = self.adjustedIndexForIndex(index: indexPath.item)
		return cell
	}
	
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return self.bounds.size
	}

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
		return 0
	}
	
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
		return 0
	}
	
	//MARK: Private Methods
	private func adjustedIndexForIndex(index: Int) -> Int {
		if numberOfPages == 1 {
			return index
		}
		switch index {
		case 0:
			return (numberOfPages - 1)
		case (numberOfPages + 1):
			return 0
		default:
			return index - 1
		}
	}
	
	private func pageSize() -> CGFloat {
		return horizontalScroll == true
            ? collectionView.bounds.width
            : collectionView.bounds.height
	}
	
	private func currentOffset() -> CGFloat {
		return horizontalScroll == true
            ? collectionView.contentOffset.x
            : collectionView.contentOffset.y
	}
}

// MARK: Helper Cell
class CircularScrollViewCell: UICollectionViewCell {
	static var identifier = "CircularScrollViewCell"
	var index: Int?
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
	}
	
	required init(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
}
