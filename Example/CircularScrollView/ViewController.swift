//
//  ViewController.swift
//  CircularScrollView
//
//  Created by daniele margutti on 06/03/2015.
//  Copyright (c) 06/03/2015 daniele margutti. All rights reserved.
//

import UIKit
import CircularScrollView

class ViewController: UIViewController, CircularScrollViewDataSource,CircularScrollViewDelegate {
	var circularControl : CircularScrollView?
	var backColors : [UIColor]!
	var viewControllers : [AnyObject]
	var numberOfPages: Int
	
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
		backColors = [ UIColor.yellowColor(),UIColor.orangeColor(),UIColor.redColor(),UIColor.blueColor(),UIColor.cyanColor(),UIColor.lightGrayColor()]
		numberOfPages = count(backColors)
		viewControllers = []
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}

	required init(coder aDecoder: NSCoder) {
		backColors = [ UIColor.yellowColor(),UIColor.orangeColor(),UIColor.redColor(),UIColor.blueColor(),UIColor.cyanColor(),UIColor.lightGrayColor()]
		numberOfPages = count(backColors)
		viewControllers = []
	    super.init(coder: aDecoder)
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		for (var x = 0; x < numberOfPages; ++x) {
			self.viewControllers.append(NSNull())
		}
		
		circularControl = CircularScrollView(frame: self.view.bounds)
		self.view.addSubview(circularControl!)
		circularControl?.delegate = self
		circularControl?.dataSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	func numberOfPagesInCircularScrollView(#scroll: CircularScrollView!) -> Int! {
		return count(backColors!)
	}
	
	func circularScrollView(#scroll: CircularScrollView!, viewControllerAtIndex index: Int!) -> UIViewController! {
		return self.viewControllerAtIndex(index)
	}
	
	private func viewControllerAtIndex(index: Int!) -> UIViewController! {
		var item : AnyObject? = viewControllers[index]
		if let item = item as? UIViewController {
			return item
		} else {
			var vc = UIViewController()
			vc.view.backgroundColor = backColors[index]
			vc.view.frame = circularControl!.bounds
			
			let label = UILabel()
			label.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
			label.frame = vc.view.bounds
			label.font = UIFont.systemFontOfSize(40)
			label.textAlignment = NSTextAlignment.Center
			label.text = "#\(index)"
			vc.view.addSubview(label)
			
			viewControllers[index] = vc
			return vc
		}
	}

}

