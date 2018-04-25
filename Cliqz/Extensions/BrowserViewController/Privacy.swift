//
//  Privacy.swift
//  Client
//
//  Created by Sahakyan on 4/19/18.
//  Copyright © 2018 Cliqz. All rights reserved.
//

import Foundation

extension NSNotification.Name {
	
	public static let ShowControlCenterNotification = NSNotification.Name(rawValue: "showControlCenter")

	public static let HideControlCenterNotification = NSNotification.Name(rawValue: "hideControlCenter")
}

extension BrowserViewController {
	
	func showControlCenter(notification: Notification) {
		let controlCenter = ControlCenterViewController()
		
		if let pageUrl = notification.object as? String {
			controlCenter.pageURL = pageUrl
			// TODO: provide a DataSource Instead
//			controlCenter.trackers = TrackerList.instance.detectedTrackersForPage(pageUrl)
//			controlCenter.pageURL = host
		}
		self.addChildViewController(controlCenter)
		self.view.addSubview(controlCenter.view)
		controlCenter.view.snp.makeConstraints({ (make) in
			make.left.right.bottom.equalToSuperview()
			make.top.equalToSuperview().offset(0)
		})
	}

	func hideControlCenter() {
		if let cc = self.childViewControllers.last,
			let c = cc as? ControlCenterViewController {
			c.removeFromParentViewController()
			c.view.removeFromSuperview()
		}
	}
}
