//
//  BlockingCoordinator.swift
//  Client
//
//  Created by Tim Palade on 4/19/18.
//  Copyright © 2018 Cliqz. All rights reserved.
//

import WebKit

final class BlockingCoordinator {
    
    private var isUpdating = false
    
    var isAdblockerOn: Bool {
        return UserPreferences.instance.adblockingMode == .blockAll
    }
    
    func isAntitrackingOn(domain: String?) -> Bool {
        //logic if I load the antitracking
        //when can this be off?
        //when the site is trusted
        if let domainStr = domain, let domainObj = DomainStore.get(domain: domainStr) {
            return !(domainObj.translatedState == .trusted)
        }
        return true
    }
    
    enum BlockListType {
        case antitracking
        case adblocker
    }
    
    //order in which to load the blocklists
    let order: [BlockListType] = [.antitracking, .adblocker]
    
    func featureIsOn(forType: BlockListType, domain: String?) -> Bool {
        return forType == .antitracking ? isAntitrackingOn(domain: domain) : isAdblockerOn
    }
    
    func identifiersForAntitracking(domain: String?) -> [String] {
        //logic what to load for antitracking
        if UserPreferences.instance.antitrackingMode == .blockAll {
            return BlockListIdentifiers.antitrackingBlockAllIdentifiers()
        }
        else {
            if let domainStr = domain, let domainObj = DomainStore.get(domain: domainStr) {
                if domainObj.translatedState == .restricted {
                    return BlockListIdentifiers.antitrackingBlockAllIdentifiers()
                }
            }
        }
        
        //assemble list of appIds for which blocklists need to loaded
        return BlockListIdentifiers.antitrackingBlockSelectedIdentifiers(domain: domain)
    }
    
    func identifiersFor(type: BlockListType, domain: String?) -> [String] {
        return type == .antitracking ? identifiersForAntitracking(domain: domain) : BlockListIdentifiers.adblockingIdentifiers()
    }
    
    //TODO: Make sure that at the time of the coordinatedUpdate, all necessary blocklists are in the cache
    func coordinatedUpdate(webView: WKWebView?) {
        guard isUpdating == false else { return }
        
        isUpdating = true
        
        guard let webView = webView else {return}
    
        var blockLists: [WKContentRuleList] = []
        let dispatchGroup = DispatchGroup()
        let domain = webView.url?.normalizedHost
        for type in order {
            if featureIsOn(forType: type, domain: domain) {
                //get the blocklists for that type
                dispatchGroup.enter()
                let identifiers = identifiersFor(type: type, domain: domain)
                BlockListManager.shared.getBlockLists(forIdentifiers: identifiers, callback: { (lists) in
                    blockLists.append(contentsOf: lists)
                    type == .antitracking ? debugPrint("Antitracking is ON") : debugPrint("Adblocking is ON")
                    dispatchGroup.leave()
                })
            }
            else {
                type == .antitracking ? debugPrint("Antitracking is OFF") : debugPrint("Adblocking is OFF")
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            webView.configuration.userContentController.removeAllContentRuleLists()
            blockLists.forEach(webView.configuration.userContentController.add)
            debugPrint("BlockLists Loaded")
            self.isUpdating = false
        }
    }
}
