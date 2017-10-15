//
//  USeekManager.swift
//  Pods-USeek-Swift_Example
//
//  Created by Chris Lin on 10/8/17.
//

import UIKit

/**
 *
 * This singleton class provides the following features
 *
 *  - Set / Retrieve publisher ID
 *  - Request server for the points of certain user based on game id
 *
 */
class USeekManager: NSObject {
    
    /**
     * Returns USeekManager singleton object.
     */
    public static let sharedManager = USeekManager()
    
    // MARK: Properties
    
    /**
     *
     * Mutable property to set / get publisher id.
     *
     * - Warning: You should set publisher id before loading video.
     *
     * - - -
     *
     * You can set publisher id in AppDelegate like this.
     *
     *      ```swift
     *      USeekManager.sharedManager.publisherId = "{your publisher ID}"
     *      ```
     *
     */
    public var publisherId: String
    
    // MARK: Initialization
    
    override init() {
        self.publisherId = ""
        
        super.init()
    }
    
    // MARK: Requests
    
    /**
     *
     * Queries the points user has gained while playing the game.
     * The centralized server will return user's points based on gameId and userId.
     *
     * - Precondition: Publisher ID should be set.
     *
     * @param userId      user's unique id registered in USeek
     * @param gameId      unique game id provided by USeek
     * @param success     block which will be triggered after response is successfully retrieved
     * @param failure     block which will be triggered when there is an error detected
     *
     */
    public func requestPoints(GameId gameId: String, UserId userId: String?, Success success: ((_ points: Int) -> Void)?, Failure failure: ((_ error: Error?) -> Void)?) {
        if USeekUtils.validateString(self.publisherId) == false {
            let userInfo = [NSLocalizedDescriptionKey: NSLocalizedString("Operation was cancelled due to invalid publisher id.", comment: ""),
                            NSLocalizedFailureReasonErrorKey: NSLocalizedString("Operation was cancelled due to invalid publisher id.", comment: ""),
                            NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Have you tried sending valid publisher id?", comment: "")
            ]
            
            let error = NSError(domain: NSURLErrorDomain, code: -1011, userInfo: userInfo)      // kCFURLErrorBadServerResponse
            
            failure?(error)
            return
        }
        
        if USeekUtils.validateString(gameId) == false {
            let userInfo = [NSLocalizedDescriptionKey: NSLocalizedString("Operation was cancelled due to invalid game id.", comment: ""),
                            NSLocalizedFailureReasonErrorKey: NSLocalizedString("Operation was cancelled due to invalid game id.", comment: ""),
                            NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Have you tried sending valid game id?", comment: "")
            ]
            
            let error = NSError(domain: NSURLErrorDomain, code: -1011, userInfo: userInfo)      // kCFURLErrorBadServerResponse
            
            failure?(error)
            return
        }
        
        var params = [String: String]()
        params["publisherId"] = USeekUtils.refineString(self.publisherId)
        params["gameId"] = USeekUtils.refineString(gameId)
        if USeekUtils.validateString(userId) == true {
            params["user_Id"] = USeekUtils.refineString(userId)
        }
        else {
            params["user_id"] = ""
        }
        
        let urlString = "https://www.useek.com/sdk/1.0/\(self.publisherId)/\(gameId)/get_points"
        USeekUtils.requestGET(URL: urlString, Params: params, Success: { (responseObject: Any?) -> Void in
            
            if let dictionary = responseObject as? Dictionary<AnyHashable, Any> {
                let result = USeekPlaybackResultDataModel(dictionary: dictionary)
                success?(result.points)
            }
            else {
                success?(0)
            }
            
        }, Failure: { (error: Error?) -> Void in
            
            failure?(error)
            
        })
    }
    
}

