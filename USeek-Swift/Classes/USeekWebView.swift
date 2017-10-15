//
//  USeekWebView.swift
//  Pods-USeek-Swift_Example
//
//  Created by Chris Lin on 10/8/17.
//

import UIKit

class USeekWebView: UIWebView {
    
    public var gameId: String = ""
    public var userId: String = ""
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.scrollView.isScrollEnabled = false
        self.scrollView.bounces = false
    }
    
    override var description: String {
        return "USeek Instance (publiserId = \(USeekManager.sharedManager.publisherId), gameId = \(self.gameId), userId = \(self.userId)"
    }
    
    public func generateVideoUrl () -> URL? {
        if self.validateConfiguration() == false {
            return nil
        }
        
        var urlString = "https://www.useek.com/sdk/1.0/\(USeekManager.sharedManager.publisherId)/\(self.gameId)/play"
        if USeekUtils.validateString(self.userId) == true {
            urlString = "\(urlString)?external_user_id=\(self.userId)"
        }
        if USeekUtils.validateUrl(urlString) == false {
            return nil
        }
        
        return URL(string: urlString)
    }
    
    public func validateConfiguration () -> Bool {
        if USeekUtils.validateString(USeekManager.sharedManager.publisherId) == false {
            return false
        }
        if USeekUtils.validateString(self.gameId) == false {
            return false
        }
        return true
    }
    
    public func loadVideo () {
        if self.validateConfiguration() == false {
            print("USeek Configuration Invalid:\r \(self)")
            return
        }
        
        guard let url = self.generateVideoUrl() else {
            print("USeek Configuration Invalid:\r \(self)")
            return
        }
        
        self.allowsInlineMediaPlayback = true
        self.mediaPlaybackRequiresUserAction = false
        self.isOpaque = false
        self.backgroundColor = UIColor.clear
        
        self.loadRequest(URLRequest(url: url))
    }
    
}

