//
//  ControlCenterDataSource.swift
//  Client
//
//  Created by Tim Palade on 4/23/18.
//  Copyright © 2018 Cliqz. All rights reserved.
//

import UIKit

enum TableType {
    case page
    case global
}

protocol ControlCenterDSProtocol: class {
    
    func domainString() -> String
    func domainState() -> DomainState
    func countByCategory() -> Dictionary<String, Int>
    func detectedTrackerCount() -> Int
    func blockedTrackerCount() -> Int
    func isGhosteryPaused() -> Bool
    func isGlobalAntitrackingOn() -> Bool
    func isGlobalAdblockerOn() -> Bool
    func antitrackingCount() -> Int
    
    //SECTIONS
    func numberOfSections(tableType: TableType) -> Int
    func numberOfRows(tableType: TableType, section: Int) -> Int
    func title(tableType: TableType, section: Int) -> String
    func image(tableType: TableType, section: Int) -> UIImage?
    func category(_ tableType: TableType, _ section: Int) -> String
    func trackerCount(tableType: TableType, section: Int) -> Int
    func blockedTrackerCount(tableType: TableType, section: Int) -> Int
    func stateIcon(tableType: TableType, section: Int) -> UIImage?
    
    //INDIVIDUAL TRACKERS
    func title(tableType: TableType, indexPath: IndexPath) -> String?
    func attributedTitle(tableType: TableType, indexPath: IndexPath) -> NSMutableAttributedString?
    func stateIcon(tableType: TableType, indexPath: IndexPath) -> UIImage?
    func appId(tableType: TableType, indexPath: IndexPath) -> Int
}

class ControlCenterDataSource: ControlCenterDSProtocol {
    
    enum CategoryState {
        case blocked
        case restricted
        case trusted
        case none
        case other
        
        static func from(trackerState: TrackerStateEnum) -> CategoryState {
            switch trackerState {
            case .blocked:
                return .blocked
            case .restricted:
                return .restricted
            case .trusted:
                return .trusted
            case .none:
                return .none
            }
        }
    }
    
    let category2Name = ["advertising": "Advertising",
                         "audio_video_player": "Audio/Video Player",
                         "comments": "Comments",
                         "customer_interaction": "Customer Interaction",
                         "essential": "Essential",
                         "pornvertising": "Adult Advertising",
                         "site_analytics": "Site Analytics",
                         "social_media": "Social Media",
                         "uncategorized": "Uncategorized"
    ]
    
    let pageCategories: [String]
    let globalCategories: [String]
    
    let domainStr: String
    let pageTrackers: Dictionary<String, [TrackerListApp]>
    let globalTrackers: Dictionary<String, [TrackerListApp]>
    
    //TODO: update mechanism
    init(url: URL) {
        self.domainStr = url.normalizedHost ?? url.absoluteString
        self.pageTrackers = TrackerList.instance.trackersByCategory(for: self.domainStr)
        self.pageCategories = Array(self.pageTrackers.keys)
        self.globalTrackers = TrackerList.instance.trackersByCategory()
        self.globalCategories = Array(self.globalTrackers.keys)
    }
    
    func domainString() -> String {
        return domainStr
    }
    
    func domainState() -> DomainState {
        if let domainObj = DomainStore.get(domain: self.domainStr) {
            return domainObj.translatedState
        }
        return .none //placeholder
    }
    
    func countByCategory() -> Dictionary<String, Int> {
        return TrackerList.instance.countByCategory(domain: self.domainStr)
    }
    
    func detectedTrackerCount() -> Int {
        return TrackerList.instance.detectedTrackerCountForPage(self.domainStr)
    }
    
    func blockedTrackerCount() -> Int {
        let domainS = domainState()
        
        if domainS == .restricted {
            return detectedTrackerCount()
        } else if domainS == .trusted {
            return 0
        }
        else {
            return TrackerList.instance.detectedTrackersForPage(self.domainStr).filter { (app) -> Bool in
                if let domainObj = DomainStore.get(domain: self.domainStr) {
                    return app.state.translatedState == .blocked || domainObj.restrictedTrackers.contains(app.appId) //TODO: Make this more efficient. Lookup in the list is n.
                }
                return app.state.translatedState == .blocked
                }.count
        }
    }
    
    func isGhosteryPaused() -> Bool {
        return UserPreferences.instance.pauseGhosteryMode == .paused
    }
    
    func isGlobalAntitrackingOn() -> Bool {
        return UserPreferences.instance.antitrackingMode == .blockAll
    }
    
    func isGlobalAdblockerOn() -> Bool {
        return UserPreferences.instance.adblockingMode == .blockAll
    }
    
    func antitrackingCount() -> Int {
        return self.blockedTrackerCount()
    }
    
    //SECTIONS
    func numberOfSections(tableType: TableType) -> Int {
        return source(tableType).keys.count
    }
    
    func numberOfRows(tableType: TableType, section: Int) -> Int {
        return trackers(tableType: tableType, category: category(tableType, section)).count
    }
    
    func title(tableType: TableType, section: Int) -> String {
        return category2Name[category(tableType, section)] ?? ""
    }
    
    func image(tableType: TableType, section: Int) -> UIImage? {
        return UIImage(named: category(tableType, section))
    }
    
    func category(_ tableType: TableType, _ section: Int) -> String {
        let categories: [String]
        if tableType == .page {
            categories = self.pageCategories
        }
        else {
            categories = self.globalCategories
        }
        
        guard categories.isIndexValid(index: section) else { return "" }
        return categories[section]
    }
 
    func trackerCount(tableType: TableType, section: Int) -> Int {
        return self.numberOfRows(tableType: tableType, section: section)
    }
    
    func blockedTrackerCount(tableType: TableType, section: Int) -> Int {
        return trackers(tableType: tableType, category: category(tableType, section)).filter({ (app) -> Bool in
            let translatedState = app.state.translatedState
            return translatedState == .blocked || translatedState == .restricted
        }).count
    }
    
    func stateIcon(tableType: TableType, section: Int) -> UIImage? {
        
        let domainState = self.domainState()
        
        if domainState == .restricted {
            return iconForCategoryState(state: .restricted)
        }
        else if domainState == .trusted {
            return iconForCategoryState(state: .trusted)
        }
        
        let t = trackers(tableType: tableType, category: category(tableType, section))
        
        var set: Set<TrackerStateEnum> = Set()
        
        for tracker in t {
            set.insert(tracker.state.translatedState)
        }
        
        let state: CategoryState
        
        if set.count > 1 {
            state = .other
        }
        else if set.count == 1 {
            state = CategoryState.from(trackerState: set.first!)
        }
        else {
            state = .none
        }
        
        return iconForCategoryState(state: state)
    }
    
    //INDIVIDUAL TRACKERS
    func title(tableType: TableType, indexPath: IndexPath) -> String? {
        guard let t = tracker(tableType: tableType, indexPath: indexPath) else { return nil }
        let state: TrackerStateEnum = t.state.translatedState
        
        if state == .blocked || state == .restricted {
            return nil
        }
        
        return t.name
    }
    
    func attributedTitle(tableType: TableType, indexPath: IndexPath) -> NSMutableAttributedString? {
        guard let t = tracker(tableType: tableType, indexPath: indexPath) else { return nil }
        let state: TrackerStateEnum = t.state.translatedState
        
        if state == .blocked || state == .restricted {
            let str = NSMutableAttributedString(string: t.name)
            str.addAttributes([NSStrikethroughStyleAttributeName : 1], range: NSMakeRange(0, t.name.count))
            return str
        }
        
        return nil
    }
    
    func stateIcon(tableType: TableType, indexPath: IndexPath) -> UIImage? {
        guard let t = tracker(tableType: tableType, indexPath: indexPath) else { return nil }
        
        let domainState = self.domainState()
        
        if domainState == .restricted {
            return iconForTrackerState(state: .restricted)
        }
        else if domainState == .trusted {
            return iconForTrackerState(state: .trusted)
        }
        
        return iconForTrackerState(state: t.state.translatedState)
    }
    
    func appId(tableType: TableType, indexPath: IndexPath) -> Int {
        guard let t = tracker(tableType: tableType, indexPath: indexPath) else { return -1 }
        return t.appId
    }
}

// MARK: - Helpers
extension ControlCenterDataSource {
    
    fileprivate func source(_ tableType: TableType) -> Dictionary<String, [TrackerListApp]> {
        if tableType == .page {
            return self.pageTrackers
        }
        
        return self.globalTrackers
    }
    
    fileprivate func trackers(tableType: TableType, category: String) -> [TrackerListApp] {
        return source(tableType)[category] ?? []
    }
    
    fileprivate func tracker(tableType: TableType, indexPath: IndexPath) -> TrackerListApp? {
        let (section, row) = sectionAndRow(indexPath: indexPath)
        let t = trackers(tableType: tableType, category: category(tableType, section))
        guard t.isIndexValid(index: row) else { return nil }
        return t[row]
    }
    
    fileprivate func sectionAndRow(indexPath: IndexPath) -> (Int, Int) {
        return (indexPath.section, indexPath.row)
    }
    
    fileprivate func iconForTrackerState(state: TrackerStateEnum?) -> UIImage? {
        if let state = state {
            switch state {
            case .none:
                return nil
            case .blocked:
                return UIImage(named: "blockTracker")
            case .restricted:
                return UIImage(named: "restrictTracker")
            case .trusted:
                return UIImage(named: "trustTracker")
            }
        }
        return nil
    }
    
    fileprivate func iconForCategoryState(state: CategoryState?) -> UIImage? {
        if let state = state {
            switch state {
            case .none:
                return UIImage(named: "empty")
            case .blocked:
                return UIImage(named: "blockTracker")
            case .restricted:
                return UIImage(named: "restrictTracker")
            case .trusted:
                return UIImage(named: "trustTracker")
            case .other:
                return nil //should be the minus image
            }
        }
        return nil
    }
}

extension Array {
    func isIndexValid(index: Int) -> Bool {
        return index >= 0 && index < self.count
    }
}
