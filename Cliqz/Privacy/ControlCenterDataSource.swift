//
//  ControlCenterDataSource.swift
//  Client
//
//  Created by Tim Palade on 4/23/18.
//  Copyright © 2018 Cliqz. All rights reserved.
//

import UIKit

protocol ControlCenterDSProtocol: class {
    func domainString() -> String
    func trackersByCategory() -> Dictionary<String, [TrackerListApp]>
    func globalTrackersByCategory() -> Dictionary<String, [TrackerListApp]>
    func countByCategory() -> Dictionary<String, Int>
    func detectedTrackerCount() -> Int
    func blockedTrackerCount() -> Int
    func domainState() -> DomainState
    func isGhosteryPaused() -> Bool
    func isGlobalAntitrackingOn() -> Bool
    func isGlobalAdblockerOn() -> Bool
    func antitrackingCount() -> Int
    func adblockCount() -> Int
}

class ControlCenterDataSource: ControlCenterDSProtocol {
    
    let allCategories = ["advertising": "Advertising",
                         "audio_video_player": "Audio/Video Player",
                         "comments": "Comments",
                         "customer_interaction": "Customer Interaction",
                         "essential": "Essential",
                         "pornvertising": "Adult Advertising",
                         "site_analytics": "Site Analytics",
                         "social_media": "Social Media",
                         "uncategorized": "Uncategorized"
    ]
    
    let categories = ["advertising", "audio_video_player", "comments", "essential", "pornvertising", "site_analytics", "social_media", "uncategorized"]
    
    enum TableType {
        case page
        case global
    }
    
    let domainStr: String
    let pageTrackers: Dictionary<String, [TrackerListApp]>
    let globalTrackers: Dictionary<String, [TrackerListApp]>
    
    //TODO: update mechanism
    init(url: URL) {
        self.domainStr = url.normalizedHost ?? url.absoluteString
        self.pageTrackers = TrackerList.instance.trackersByCategory(for: self.domainStr)
        self.globalTrackers = TrackerList.instance.trackersByCategory()
    }
    
    func source(_ tableType: TableType) -> Dictionary<String, [TrackerListApp]> {
        if tableType == .page {
            return self.pageTrackers
        }
        
        return self.globalTrackers
    }
    
    func trackers(tableType: TableType, category: String) -> [TrackerListApp] {
        return source(tableType)[category] ?? []
    }
    
    func tracker(tableType: TableType, indexPath: IndexPath) -> TrackerListApp? {
        let (section, row) = sectionAndRow(indexPath: indexPath)
        let t = trackers(tableType: tableType, category: category(section))
        guard t.isIndexValid(index: row) else { return nil }
        return t[row]
    }
    
    func category(_ section: Int) -> String {
        guard categories.isIndexValid(index: section) else { return "" }
        return categories[section]
    }
    
    func sectionAndRow(indexPath: IndexPath) -> (Int, Int) {
        return (indexPath.section, indexPath.row)
    }
    
    //Section
    func numberOfSections(tableType: TableType) -> Int {
        return source(tableType).keys.count
    }
    
    func numberOfRows(tableType: TableType, section: Int) -> Int {
        return trackers(tableType: tableType, category: category(section)).count
    }
    
    func title(tableType: TableType, section: Int) -> String {
        return allCategories[category(section)] ?? ""
    }
    
    func image(tableType: TableType, section: Int) -> UIImage? {
        return UIImage(named: category(section))
    }
 
    func trackerCount(tableType: TableType, section: Int) -> Int {
        return self.numberOfRows(tableType: tableType, section: section)
    }
    
    func blockedTrackerCount(tableType: TableType, section: Int) -> Int {
        return trackers(tableType: tableType, category: category(section)).filter({ (app) -> Bool in
            let translatedState = app.state.translatedState
            return translatedState == .blocked || translatedState == .restricted
        }).count
    }
    
    //Trackers - name, state
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
            return UIImage(named: iconForTrackerState(state: .restricted))
        }
        else if domainState == .trusted {
            return UIImage(named: iconForTrackerState(state: .trusted))
        }
        
        return UIImage(named: iconForTrackerState(state: t.state.translatedState))
    }
    
    func appId(tableType: TableType, indexPath: IndexPath) -> Int {
        guard let t = tracker(tableType: tableType, indexPath: indexPath) else { return -1 }
        return t.appId
    }
    
    func trackersByCategory() -> Dictionary<String, [TrackerListApp]> {
        return TrackerList.instance.trackersByCategory(for: self.domainStr)
    }
    
    func globalTrackersByCategory() -> Dictionary<String, [TrackerListApp]> {
        return TrackerList.instance.trackersByCategory()
    }
    
    func countByCategory() -> Dictionary<String, Int> {
        return TrackerList.instance.countByCategory(domain: self.domainStr)
    }
    
    func domainString() -> String {
        return domainStr
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
    
    func domainState() -> DomainState {
        if let domainObj = DomainStore.get(domain: self.domainStr) {
            return domainObj.translatedState
        }
        return .none //placeholder
    }
    
    func isGhosteryPaused() -> Bool {
        return false //placeholder
    }
    
    func isGlobalAntitrackingOn() -> Bool {
        return UserPreferences.instance.blockingMode == .all
    }
    
    func isGlobalAdblockerOn() -> Bool {
        return true //placeholder
    }
    
    func antitrackingCount() -> Int {
        return self.blockedTrackerCount()
    }
    
    func adblockCount() -> Int {
        return 0 //placeholder
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
}

extension Array {
    func isIndexValid(index: Int) -> Bool {
        return index >= 0 && index < self.count
    }
}
