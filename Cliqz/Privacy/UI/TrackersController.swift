//
//  TrackersTableViewController.swift
//  BrowserCore
//
//  Created by Tim Palade on 3/19/18.
//  Copyright © 2018 Tim Palade. All rights reserved.
//

import UIKit
import SnapKit

//This is a temporary solution until we build the Ghostery Control Center

let trackerViewDismissedNotification = Notification.Name(rawValue: "TrackerViewDismissed")

struct ControlCenterUI {
	static let separatorGray = UIColor(colorString: "E0E0E0")
}

class TrackersController: UIViewController {

	weak var dataSource: ControlCenterDSProtocol? {
		didSet {
			updateData()
		}
	}
	weak var delegate: ControlCenterDelegateProtocol?

    let tableView = UITableView()
	var expandedSectionIndex = -1

    var changes = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

		setupComponents()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	private func setupComponents() {
		let headerView = CategoriesHeaderView()
		headerView.addTarget(self, action: #selector(showActionSheet), for: .touchUpInside)
		self.tableView.tableHeaderView = headerView
		self.tableView.tableHeaderView?.frame = CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 80)
		self.tableView.tableHeaderView?.snp.makeConstraints { (make) in
			make.top.left.equalToSuperview()
			make.width.equalToSuperview()
			make.height.equalTo(80)
		}

		self.tableView.dataSource = self
		self.tableView.delegate = self
		self.tableView.register(CustomCell.self, forCellReuseIdentifier: "reuseIdentifier")
		view.addSubview(tableView)
		tableView.snp.makeConstraints { (make) in
			make.top.left.right.bottom.equalToSuperview()
		}
	}

	private func updateData() {
		self.tableView.reloadData()
	}

	@objc private func showActionSheet() {
		let blockTrustAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

		let blockAll = UIAlertAction(title: NSLocalizedString("Block All", tableName: "Cliqz", comment: "[ControlCenter - Trackers list] Block All trackers action title"), style: .default, handler: { [weak self] (alert: UIAlertAction) -> Void in
				self?.blockAllCategories()
		})
		blockTrustAlertController.addAction(blockAll)
		let trustAll = UIAlertAction(title: NSLocalizedString("Trust All", tableName: "Cliqz", comment: "[ControlCenter - Trackers list] Trust All trackers action title"), style: .default, handler: { [weak self] (alert: UIAlertAction) -> Void in
				self?.trustAllCategories()
		})
		blockTrustAlertController.addAction(trustAll)

		let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", tableName: "Cliqz", comment: "[ControlCenter - Trackers list] Cancel action title"), style: .cancel)
		blockTrustAlertController.addAction(cancelAction)
		self.present(blockTrustAlertController, animated: true, completion: nil)
	}

	private func blockAllCategories() {
		
	}

	private func trustAllCategories() {
		
	}
}

extension TrackersController: UITableViewDataSource, UITableViewDelegate {
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.dataSource?.numberOfSections(tableType: .page) ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if self.expandedSectionIndex == section {
			return self.dataSource?.numberOfRows(tableType: .page, section: section) ?? 0
		}
        return 0
    }

	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 80
	}

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath) as! CustomCell
        
        if let title = self.dataSource?.title(tableType: .page, indexPath: indexPath) {
            cell.textLabel?.text = title
        }
        else if let attrTitle = self.dataSource?.attributedTitle(tableType: .page, indexPath: indexPath) {
            cell.textLabel?.attributedText = attrTitle
        }
        else {
            cell.textLabel?.text = ""
        }

		cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
		cell.textLabel?.textColor = UIColor(colorString: "C7C7CD")
        cell.appId = self.dataSource?.appId(tableType: .page, indexPath: indexPath) ?? -1
        cell.statusIcon.image = self.dataSource?.stateIcon(tableType: .page, indexPath: indexPath)
        return cell
    }

	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let title =  self.dataSource?.title(tableType: .page, section: section)
		
        let header = UIView()
		header.backgroundColor = UIColor.white
		let titleLbl = UILabel()
		titleLbl.text = title
		header.addSubview(titleLbl)
		let icon = UIImageView()
		header.addSubview(icon)
		icon.snp.makeConstraints { (make) in
			make.left.top.equalToSuperview().offset(10)
			make.width.height.equalTo(50)
		}
		icon.image = self.dataSource?.image(tableType: .page, section: section) ?? nil
		titleLbl.snp.makeConstraints { (make) in
			make.top.right.equalToSuperview().offset(10)
			make.left.equalTo(icon.snp.right).offset(10)
			make.height.equalTo(25)
		}
		titleLbl.font = UIFont.systemFont(ofSize: 16)
		let descLbl = UILabel()
        let trackersCount = self.dataSource?.trackerCount(tableType: .page, section: section) ?? 0
        let blockedCount = self.dataSource?.blockedTrackerCount(tableType: .page, section: section) ?? 0
		descLbl.text = String(format: NSLocalizedString("%d TRACKERS %d Blocked", tableName: "Cliqz", comment: "[ControlCenter -> Trackers] Detected and Blocked trackers count"), trackersCount, blockedCount)
		descLbl.font = UIFont.systemFont(ofSize: 12)
		descLbl.textColor = ControlCenterUI.separatorGray
		header.addSubview(descLbl)
		descLbl.snp.makeConstraints { (make) in
			make.right.equalToSuperview().offset(10)
			make.top.equalTo(titleLbl.snp.bottom).offset(0)
			make.left.equalTo(icon.snp.right).offset(10)
			make.height.equalTo(25)
		}
		let statusIcon = UIImageView()
		header.addSubview(statusIcon)
		statusIcon.snp.makeConstraints { (make) in
			make.centerY.equalToSuperview()
			make.right.equalToSuperview().offset(10)
		}
		statusIcon.image = self.dataSource?.image(tableType: .page, section: section)
		header.tag = section
		let headerTapGesture = UITapGestureRecognizer()
		headerTapGesture.addTarget(self, action: #selector(sectionHeaderTapped(_:)))
		header.addGestureRecognizer(headerTapGesture)
		return header
	}

	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		let sep = UIView()
		sep.backgroundColor = ControlCenterUI.separatorGray
		return sep
	}

	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 1
	}

	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		// by default antitracking should be off until user configures manually
        let appId = self.dataSource?.appId(tableType: .page, indexPath: indexPath) ?? -1
		
        let restrictAction = UIContextualAction(style: .destructive, title: "Restrict") { (action, view, complHandler) in
			print("Restrict")
			self.delegate?.changeState(appId: appId, state: .restricted)

            tableView.beginUpdates()
            self.tableView.reloadRows(at: [indexPath], with: .none)
            tableView.endUpdates()
            complHandler(false)
		}
		let blockAction = UIContextualAction(style: .destructive, title: "Block") { (action, view, complHandler) in
			print("Block")
			self.delegate?.changeState(appId: appId, state: .blocked)

            tableView.beginUpdates()
            self.tableView.reloadRows(at: [indexPath], with: .none)
            tableView.endUpdates()
            complHandler(false)
		}
		let trustAction = UIContextualAction(style: .normal, title: "Trust") { (action, view, complHandler) in
			print("Trust")
			self.delegate?.changeState(appId: appId, state: .trusted)

            tableView.beginUpdates()
            self.tableView.reloadRows(at: [indexPath], with: .none)
            tableView.endUpdates()
            complHandler(false)
		}

		trustAction.backgroundColor = UIColor(colorString: "9ECC42")
		blockAction.backgroundColor = UIColor(colorString: "E74055")
		restrictAction.backgroundColor = UIColor(colorString: "BE4948")
		trustAction.image = UIImage(named: "trustAction")
		blockAction.image = UIImage(named: "blockAction")
		restrictAction.image = UIImage(named: "restrictAction")
		let swipeConfig = UISwipeActionsConfiguration(actions: [blockAction,  restrictAction, trustAction])
		return swipeConfig
	}

	@objc private func sectionHeaderTapped(_ sender: UITapGestureRecognizer) {
		let headerView = sender.view
		if let section = headerView?.tag {
			var set = IndexSet()
			if self.expandedSectionIndex == section {
				self.expandedSectionIndex = -1
				set.insert(section)
			} else {
				if self.expandedSectionIndex != -1 {
					set.insert(self.expandedSectionIndex)
				}
				set.insert(section)
				self.expandedSectionIndex = section
			}
			self.tableView.reloadSections(set, with: .fade)
			if set.count > 1 {
				self.tableView.scrollToRow(at: IndexPath(row: 0, section: section), at: .top, animated: false)
			}
		}
	}
}

class CustomCell: UITableViewCell {
    var appId: Int = 0
	let infoButton = UIButton(type: .custom)
	let statusIcon = UIImageView()
	
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
		self.contentView.addSubview(infoButton)
		self.contentView.addSubview(statusIcon)
		infoButton.snp.makeConstraints { (make) in
			make.left.centerY.equalToSuperview()
		}
		statusIcon.snp.makeConstraints { (make) in
			make.right.equalToSuperview().inset(10)
			make.centerY.equalToSuperview()
		}
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CategoriesHeaderView: UIControl {
	let categoriesLabel = UILabel()
	let actionButton = UIButton(type: .custom)
	let separator = UIView()

	init() {
		super.init(frame: CGRect.zero)
		self.addSubview(categoriesLabel)
		categoriesLabel.text = NSLocalizedString("Categories", tableName: "Cliqz", comment: "[Trackers -> ControlCenter] Trackers Title")
		self.addSubview(actionButton)
		actionButton.setImage(UIImage(named: "more"), for: .normal)
		self.addSubview(separator)
		setStyles()
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func setStyles() {
		categoriesLabel.textColor = UIColor.black
		categoriesLabel.font = UIFont.boldSystemFont(ofSize: 24)
		separator.backgroundColor = ControlCenterUI.separatorGray
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		self.categoriesLabel.snp.remakeConstraints { (make) in
			make.top.equalToSuperview()
			make.bottom.equalToSuperview()
			make.left.equalTo(self).offset(12)
			make.right.equalTo(actionButton.snp.left).offset(12)
		}
		self.actionButton.snp.remakeConstraints { (make) in
			make.left.equalTo(categoriesLabel.snp.right).offset(10)
			make.top.bottom.equalToSuperview()
			make.right.equalToSuperview().inset(15)
		}
		self.separator.snp.remakeConstraints { (make) in
			make.left.right.bottom.equalToSuperview()
			make.height.equalTo(1)
		}
	}

	override func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControlEvents) {
		self.actionButton.addTarget(target, action: action, for: controlEvents)
	}

}
