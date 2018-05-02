//
//  TabExtension.swift
//  Client
//
//  Created by Tim Palade on 3/27/18.
//  Copyright © 2018 Mozilla. All rights reserved.
//

import WebKit
import Shared

let urlChangedNotification = Notification.Name(rawValue: "URLChangedNotification")

extension Tab {
    
    func addPrivacy() {
        //Cliqz: Privacy - Add handler for user
        self.webView?.configuration.userContentController.add(URLInterceptor.shared, name: "cliqzTrackingProtection")
        self.webView?.configuration.userContentController.add(URLInterceptor.shared, name: "cliqzTrackingProtectionPostLoad")
        
        //Cliqz: Privacy - Add user scripts
        let preloadSource = try! String(contentsOf: Bundle.main.url(forResource: "preload", withExtension: "js")!)
        let preloadScript = WKUserScript(source: preloadSource, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        self.webView?.configuration.userContentController.addUserScript(preloadScript)
        
        let postloadSource = try! String(contentsOf: Bundle.main.url(forResource: "postload", withExtension: "js")!)
        let postloadScript = WKUserScript(source: postloadSource, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        self.webView?.configuration.userContentController.addUserScript(postloadScript)
        
        //Cliqz: Privacy - SetUpBlocking
        if let webView = self.webView {
            self.blockingCoordinator = BlockingCoordinator(webView: webView)
        }
        updateBlocking()
        
        NotificationCenter.default.addObserver(self, selector: #selector(trackersChanged), name: controlCenterDismissedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(trackersChanged), name: trackersLoadedNotification, object: nil)
    }
    
    @objc func trackersChanged(_ notification: Notification) {
//        if let userInfo = notification.userInfo {
//            if let changes = userInfo["changes"] as? Bool, changes == false {
//                return
//            }
//        }
        updateBlocking()
    }
    
    func didDomainChange() -> Bool {
        if let domain = self.webView?.url?.normalizedHost {
            return domain != lastDomain
        }
        return false
    }
    
    func updateBlocking() {
        blockingCoordinator?.coordinatedUpdate()
    }
    
    func urlChanged() {
        if didDomainChange() {
            updateBlocking()
            if let domain = self.webView?.url?.normalizedHost {
                lastDomain = domain
            }
        }
        self.sendURLChangedNotification()
    }
    
    func sendURLChangedNotification() {
        
        var userInfo: [String: URL] = [:]
        if let url = self.webView?.url {
            userInfo["url"] = url
        }
        
        NotificationCenter.default.post(name: urlChangedNotification, object: self, userInfo: userInfo)
    }
    
}
