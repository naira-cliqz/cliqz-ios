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

let AllCategories = ["advertising": "Advertising",
					 "audio_video_player": "Audio/Video Player",
					 "comments": "Comments",
					 "customer_interaction": "Customer Interaction",
					 "essential": "Essential",
					 "pornvertising": "Adult Advertising",
					 "site_analytics": "Site Analytics",
					 "social_media": "Social Media",
					 "uncategorized": "Uncategorized"
]

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
	fileprivate var categories = [String]()

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
		self.tableView.tableHeaderView = CategoriesHeaderView()
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
		if let list = self.dataSource?.trackersByCategory().keys {
			self.categories = [String](list)
		} else {
			self.categories = [String]()
		}
		self.tableView.reloadData()
	}
}

extension TrackersController: UITableViewDataSource, UITableViewDelegate {
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return self.categories.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
		if expandedSectionIndex == section {
			let c = self.categories[section]
			return self.dataSource?.trackersByCategory()[c]?.count ?? 0
		}
		return 0
    }

	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 80
	}

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath) as! CustomCell
        
        // Configure the cell...
		let c = self.categories[indexPath.section]
		let tracker = self.dataSource?.trackersByCategory()[c]?[indexPath.row]
        
        let domainState = self.dataSource?.domainState()
        let state: TrackerStateEnum //= self.dataSource?.domainState() == .restricted ? .restricted : (tracker?.state.translatedState ?? .none)
        if domainState == .restricted {
            state = .restricted
        }
        else if domainState == .trusted {
            state = .trusted
        }
        else {
            state = tracker?.state.translatedState ?? .none
        }
        
		if let name = tracker?.name, state == .blocked || state == .restricted {
			let str = NSMutableAttributedString(string: name)
			str.addAttributes([NSStrikethroughStyleAttributeName : 1], range: NSMakeRange(0, name.count))
			cell.textLabel?.attributedText = str
		} else {
			cell.textLabel?.text = tracker?.name
		}
		cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
		cell.textLabel?.textColor = UIColor(colorString: "C7C7CD")
        cell.appId = tracker?.appId ?? 0
		cell.statusIcon.image = UIImage(named: self.iconForTrackerState(state: state))
        return cell
    }

	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let cat = self.categories[section]
		let title =  AllCategories[cat]
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
		icon.image = UIImage(named: cat)
		titleLbl.snp.makeConstraints { (make) in
			make.top.right.equalToSuperview().offset(10)
			make.left.equalTo(icon.snp.right).offset(10)
			make.height.equalTo(25)
		}
		titleLbl.font = UIFont.systemFont(ofSize: 16)
		let descLbl = UILabel()
		descLbl.text = "11 TRACKERS 11 Blocked"
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
		// E0E0E0 separator
		header.tag = section
		let headerTapGesture = UITapGestureRecognizer()
		headerTapGesture.addTarget(self, action: #selector(sectionHeaderTapped(_:)))
		header.addGestureRecognizer(headerTapGesture)
		return header
	}

	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		let sep = UIView()
		sep.backgroundColor = UIColor.gray
		return sep
	}

	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 1
	}

	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		// by default antitracking should be off until user configures manually
		let restrictAction = UIContextualAction(style: .destructive, title: "Restrict") { (action, view, complHandler) in
			print("Restrict")
			let c = self.categories[indexPath.section]
			if let tracker = self.dataSource?.trackersByCategory()[c]?[indexPath.row] {
				self.delegate?.changeState(appId: tracker.appId, state: .restricted)
				TrackerStore.shared.add(member: tracker.appId)
			}
			// TODO: not clear
			UserPreferences.instance.blockingMode = .notall
			UserPreferences.instance.writeToDisk()

			tableView.beginUpdates()
			self.tableView.reloadRows(at: [indexPath], with: .none)
			tableView.endUpdates()
			complHandler(false)
		}
		let blockAction = UIContextualAction(style: .destructive, title: "Block") { (action, view, complHandler) in
			print("Block")
			let c = self.categories[indexPath.section]
			if let tracker = self.dataSource?.trackersByCategory()[c]?[indexPath.row] {
				self.delegate?.changeState(appId: tracker.appId, state: .blocked)
				TrackerStore.shared.add(member: tracker.appId)
			}
			UserPreferences.instance.blockingMode = .notall
			UserPreferences.instance.writeToDisk()

			tableView.beginUpdates()
			self.tableView.reloadRows(at: [indexPath], with: .none)
			tableView.endUpdates()
			complHandler(false)
		}
		let trustAction = UIContextualAction(style: .normal, title: "Trust") { (action, view, complHandler) in
			print("Trust")
			let c = self.categories[indexPath.section]
			if let tracker = self.dataSource?.trackersByCategory()[c]?[indexPath.row] {
				self.delegate?.changeState(appId: tracker.appId, state: .trusted)
				TrackerStore.shared.remove(member: tracker.appId)
			}

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

	private func iconForTrackerState(state: TrackerStateEnum?) -> String {
		if let state = state {
			switch state {
			case .none:
				return ""
			case .blocked:
				return "blockTracker"
			case .restricted:
				return "restrictTracker"
			case .trusted:
				return "trustTracker"
			}
		}
		return ""
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
//		let eImageView = headerView.viewWithTag(kHeaderSectionTag + section) as? UIImageView
//		if (self.expandedSectionHeaderNumber == -1) {
//			self.expandedSectionHeaderNumber = section
//			tableViewExpandSection(section, imageView: eImageView!)
//		} else {
//			if (self.expandedSectionHeaderNumber == section) {
//				tableViewCollapeSection(section, imageView: eImageView!)
//			} else {
//				let cImageView = self.view.viewWithTag(kHeaderSectionTag + self.expandedSectionHeaderNumber) as? UIImageView
//				tableViewCollapeSection(self.expandedSectionHeaderNumber, imageView: cImageView!)
//				tableViewExpandSection(section, imageView: eImageView!)
//			}
//		}
	}
	/*
	private func getBlockedCount(category: String) -> Int {
		var count = 0
		if let t = self.trackers[category] {
			for i in t {
				if i.isBlocked {
					count += 1
				}
			}
		}
		return count
	}
*/
	
	/*
	private func getTrackersCount(category: String) -> Int {
		var count = 0
		if let t = self.trackers[category] {
			count = t.count
		}
		return count
	}
*/
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
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
			make.right.equalToSuperview().offset(10)
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
