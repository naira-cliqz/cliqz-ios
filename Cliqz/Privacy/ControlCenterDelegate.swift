//
//  ControlCenterDelegate.swift
//  Client
//
//  Created by Tim Palade on 4/23/18.
//  Copyright © 2018 Cliqz. All rights reserved.
//

import UIKit

protocol ControlCenterDelegateProtocol: class {
    func chageSiteState(to: DomainState)
    func pauseGhostery()
    func turnGlobalAntitracking(on: Bool)
    func turnGlobalAdblocking(on: Bool)
    func changeState(appId: Int, state: TrackerStateEnum)
}

class ControlCenterDelegate: ControlCenterDelegateProtocol {
    let domainStr: String
    
    init(url: URL) {
        self.domainStr = url.normalizedHost ?? url.absoluteString
    }
    
    private func getOrCreateDomain() -> Domain {
        //if we have done anything with this domain before we will have something in the DB
        //otherwise we need to create it
        if let domainO = DomainStore.get(domain: self.domainStr) {
            return domainO
        } else {
            return DomainStore.create(domain: self.domainStr)
        }
    }
    
    func chageSiteState(to: DomainState) {
        let domainObj: Domain
        domainObj = getOrCreateDomain()
        DomainStore.changeState(domain: domainObj, state: to)
    }
    
    func pauseGhostery() {
        //dunno
    }
    
    func turnGlobalAntitracking(on: Bool) {
        if on == true {
            UserPreferences.instance.antitrackingMode = .blockAll
        }
        else {
            UserPreferences.instance.antitrackingMode = .blockSomeOrNone
        }
        UserPreferences.instance.writeToDisk()
    }
    
    func turnGlobalAdblocking(on: Bool) {
        if on == true {
            UserPreferences.instance.adblockingMode = .blockAll
        }
        else {
            UserPreferences.instance.adblockingMode = .blockNone
        }
        UserPreferences.instance.writeToDisk()
    }
    
    func changeState(appId: Int, state: TrackerStateEnum) {
        if let trakerListApp = TrackerList.instance.apps[appId] {
            TrackerStateStore.change(trackerState: trakerListApp.state, toState: state)
            
            if state == .trusted {
                UserPreferences.instance.antitrackingMode = .blockSomeOrNone
                UserPreferences.instance.writeToDisk()
            }
            
            let domainObj = getOrCreateDomain()
            if state == .trusted {
                //add it to trusted sites
                DomainStore.add(appId: appId, domain: domainObj, list: .trustedList)
                //remove it from restricted if it is there
                DomainStore.remove(appId: appId, domain: domainObj, list: .restrictedList)
            }
            else if state == .restricted {
                //add it to restricted
                DomainStore.add(appId: appId, domain: domainObj, list: .restrictedList)
                //remove from trusted if it is there
                DomainStore.remove(appId: appId, domain: domainObj, list: .trustedList)
            }
            else {
                //remove from trusted and restricted
                DomainStore.remove(appId: appId, domain: domainObj, list: .trustedList)
                DomainStore.remove(appId: appId, domain: domainObj, list: .restrictedList)
            }
        }
        else {
            debugPrint("PROBLEM -- trackerState does not exist for appId = \(appId)!")
        }
    }
}
