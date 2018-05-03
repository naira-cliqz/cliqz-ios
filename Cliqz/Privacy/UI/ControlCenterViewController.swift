//
//  ControlCenterViewController.swift
//  Client
//
//  Created by Sahakyan on 4/17/18.
//  Copyright © 2018 Cliqz. All rights reserved.
//

import Foundation

let controlCenterDismissedNotification = Notification.Name(rawValue: "ControlCenterDismissed")

class ControlCenterViewController: UIViewController {
	weak var homePanelDelegate: HomePanelDelegate?

	var dataSource: ControlCenterDSProtocol?
	var delegate: ControlCenterDelegateProtocol?

	private var topTranparentView = UIView()
	fileprivate var panelSwitchControl = UISegmentedControl(items: [])
	fileprivate var panelContainerView = UIView()

	fileprivate lazy var overviewViewController: OverviewViewController = {
		let overview = OverviewViewController()
		return overview
	}()

	fileprivate lazy var trackersViewController: TrackersController = {
		let trackers = TrackersController()
		trackers.type = .page
		return trackers
	}()

	fileprivate lazy var globalTrackersViewController: TrackersController = {
		let global = TrackersController()
		global.type = .global
		return global
	}()

	var pageURL: String = "" {
		didSet {
			if !pageURL.isEmpty,
				let url = URL(string: pageURL) {
				self.dataSource = ControlCenterDataSource(url: url)
				self.delegate = ControlCenterDelegate(url: url)
				self.overviewViewController.pageURL = url.host ?? ""
			}
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		setupComponents()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.panelSwitchControl.selectedSegmentIndex = 0
		self.switchPanel(self.panelSwitchControl)
	}
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.post(name: controlCenterDismissedNotification, object: nil)
    }

	private func setupComponents() {
		setupTopTransparentView()
		setupPanelSwitchControl()
		setupPanelContainer()
	}

	func setupTopTransparentView() {
		topTranparentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideControlCenter)))
		topTranparentView.backgroundColor = UIColor.clear
		self.view.addSubview(topTranparentView)
		topTranparentView.snp.makeConstraints { (make) in
			make.top.left.right.equalToSuperview()
			make.height.equalTo(70)
		}
	}

	func setupPanelContainer() {
		view.addSubview(panelContainerView)
		panelContainerView.backgroundColor = UIColor.white
		
		panelContainerView.snp.makeConstraints { make in
			make.top.equalTo(self.panelSwitchControl.snp.bottom).offset(5)
			make.left.right.equalTo(self.view)
			make.bottom.equalTo(self.view)
		}
	}

	private func setupPanelSwitchControl() {
		let overview = NSLocalizedString("Overview", tableName: "Cliqz", comment: "[ControlCenter] Overview panel title")
		let trackers = NSLocalizedString("Trackers", tableName: "Cliqz", comment: "[ControlCenter] Trackers panel title")
		let globalTrackers = NSLocalizedString("Global Trackers", tableName: "Cliqz", comment: "[ControlCenter] Global Trackers panel title")
		
		let items = [overview, trackers, globalTrackers]
		self.view.backgroundColor = UIColor.clear
		
		let bgView = UIView()
		bgView.backgroundColor = UIColor.cliqzBluePrimary
		
		panelSwitchControl = UISegmentedControl(items: items)
		panelSwitchControl.tintColor = UIColor.white
		panelSwitchControl.backgroundColor = UIColor.cliqzBluePrimary
		panelSwitchControl.addTarget(self, action: #selector(switchPanel), for: .valueChanged)
		bgView.addSubview(panelSwitchControl)
		self.view.addSubview(bgView)
		
		bgView.snp.makeConstraints { (make) in
			make.top.equalTo(topTranparentView.snp.bottom)
			make.left.right.equalToSuperview()
			make.height.equalTo(40)
		}
		panelSwitchControl.snp.makeConstraints { make in
			make.centerY.equalTo(bgView)
			make.left.equalTo(bgView).offset(10)
			make.right.equalTo(bgView).offset(-10)
		}
	}

	@objc func donePressed(_ button: UIBarButtonItem) {
		self.dismiss(animated: true, completion: nil)
	}

	@objc private func switchPanel(_ sender: UISegmentedControl) {
		if let panel = childViewControllers.first {
			panel.willMove(toParentViewController: nil)
			panel.view.removeFromSuperview()
			panel.removeFromParentViewController()
		}

		let viewController = self.selectedPanel()
		addChildViewController(viewController)
		self.panelContainerView.addSubview(viewController.view)
		viewController.view.snp.makeConstraints { make in
			make.edges.equalToSuperview()
		}
		viewController.didMove(toParentViewController: self)
	}

	@objc private func hideControlCenter() {
		NotificationCenter.default.post(name: Notification.Name.HideControlCenterNotification, object: nil)
	}

	private func selectedPanel() -> UIViewController {
		switch panelSwitchControl.selectedSegmentIndex {
		case 0:
			self.overviewViewController.dataSource = self.dataSource
			self.overviewViewController.delegate = self.delegate
			return self.overviewViewController
		case 1:
			self.trackersViewController.dataSource = self.dataSource
			self.trackersViewController.delegate = self.delegate
			return self.trackersViewController
		case 2:
			self.globalTrackersViewController.dataSource = self.dataSource
			self.globalTrackersViewController.delegate = self.delegate
			return self.globalTrackersViewController
		default:
			return UIViewController()
		}
	}
}
