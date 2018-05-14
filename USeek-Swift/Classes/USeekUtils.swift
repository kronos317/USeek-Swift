//
//  USeekUtils.swift
//  Pods-USeek-Swift_Example
//
//  Created by Chris Lin on 10/8/17.
//

import UIKit

enum VideoLoadStatus {
    case none
    case load_started
    case loaded
    case load_failed
}

// MARK: Playback Result Data Model

class USeekPlaybackResultDataModel: NSObject {
    
    // MARK: Properties
    
    public var publisherid: String = ""
    public var gameId: String = ""
    public var userId: String = ""
    public var finished: Bool = false
    public var points: Int = 0
    
    // MARK: Initializer
    
    init(dictionary: Dictionary<AnyHashable, Any>?) {
        super.init()
        self.setWithDictionary(dictionary)
    }
    
    override var description: String {
        return "{\rPublisher ID = \(self.publisherid)\rGame ID = \(self.gameId)\rUser ID = \(self.userId)\rFinished = \((self.finished == true) ? "YES" : "NO")\rPoints = \(self.points)\r}"
    }
    
    func setWithDictionary (_ dictionary: Dictionary<AnyHashable, Any>?) {
        guard let _ = dictionary else {
            self.publisherid = ""
            self.gameId = ""
            self.userId = ""
            self.finished = false
            self.points = 0
            return
        }
        
        self.publisherid = USeekUtils.refineString(dictionary!["publisherId"])
        self.gameId = USeekUtils.refineString(dictionary!["gameId"])
        self.userId = USeekUtils.refineString(dictionary!["userId"])
        self.points = USeekUtils.refineInt(dictionary!["lastPlayPoints"], defValue: 0)
        self.finished = USeekUtils.refineBool(dictionary!["finished"], defValue: true)
    }
}

// MARK: Utility Class

class USeekUtils: NSObject {
    
    // MARK: String Manipulation
    
    public static func validateString (_ candidate: String?) -> Bool {
        guard let _ = candidate else {
            return false
        }
        
        if candidate?.count == 0 {
            return false
        }
        
        return true
    }
    
    public static func validateUrl (_ candidate: String?) -> Bool {
        guard let _ = candidate else {
            return false
        }
        
        guard let candidateUrl = NSURL(string: candidate!) else {
            return false
        }
        
        guard let _ = candidateUrl.scheme,
            let _ = candidateUrl.host else {
                return false
        }
        
        return true
    }
    
    public static func refineString (_ originalString: Any?) -> String {
        guard let _ = originalString else {
            return ""
        }
        
        if originalString is NSNull {
            return ""
        }
        
        let resultString = "\(originalString!)"
        return resultString
    }
    
    public static func urlEncode (_ originalString: String?) -> String {
        guard let _ = originalString else {
            return ""
        }
        
        return originalString!.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? ""
    }
    
    public static func refineInt (_ value: Any?, defValue: Int = 0) -> Int {
        guard let _ = value else {
            return defValue
        }
        
        if value is NSNull {
            return defValue
        }
        
        return (value as? Int) ?? defValue
    }
    
    public static func refineBool (_ value: Any?, defValue: Bool = false) -> Bool {
        guard let _ = value else {
            return defValue
        }
        
        if value is NSNull {
            return defValue
        }
        
        return (value as? Bool) ?? defValue
    }
    
    public static func getJSONStringRepresentation (_ object: Any?) -> String {
        guard let _ = object else {
            return ""
        }
        
        if object is NSNull {
            return ""
        }
        
        if let objectData = try? JSONSerialization.data(withJSONObject: object!, options: JSONSerialization.WritingOptions(rawValue: 0)) {
            let objectString = String(data: objectData, encoding: .utf8) ?? ""
            return objectString
        }
        
        return ""
    }
    
    public static func getURLEncodedQueryStringFromDictionary (_ params: Dictionary<String, String>?) -> String {
        guard let _ = params else {
            return ""
        }
        
        var queryItems = [String]()
        for (key, value) in params! {
            let queryPart = "\(USeekUtils.urlEncode(key))=\(USeekUtils.urlEncode(value))"
            queryItems.append(queryPart)
        }
        
        return queryItems.joined(separator: "&")
    }
    
    public static func getObjectFromJSONStringRepresentation (_ string: String?) -> Any? {
        guard let _ = string else {
            return nil
        }
        
        if let data = string!.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: [])
            } catch {
                
            }
        }
        return nil
    }
    
    
    // MARK: Network Requests
    
    public static func requestGET (URL urlString: String, Params params: Dictionary<String, String>?, Success success: ((_ responseObject: Any?) -> Void)?, Failure failure: ((_ error: Error?) -> Void)?) {
        
        var urlStringWithQueryParams = urlString
        if params == nil {
            urlStringWithQueryParams = "\(urlString)?\(USeekUtils.getURLEncodedQueryStringFromDictionary(params))"
        }
        
        guard let url = URL(string: urlStringWithQueryParams) else {
            failure?(nil)
            return
        }
        
        let session = URLSession.shared
        var request = URLRequest(url: url)
        
        request.httpMethod = "GET"
        
        let task = session.dataTask(with: request) { data, urlResponse, error in
            
            guard let responseData = data else {
                failure?(error)
                return
            }
            
            let responseString = String(data: responseData, encoding: .ascii)
            success?(USeekUtils.getObjectFromJSONStringRepresentation(responseString))
        }
        task.resume()
    }
    
    public static func requestPOST (URL urlString: String, Params params: Any?, Success success: ((_ responseObject: Any?) -> Void)?, Failure failure: ((_ error: Error?) -> Void)?) {
        let postString = USeekUtils.getJSONStringRepresentation(params)
        let postData = postString.data(using: .ascii, allowLossyConversion: true)
        let postLength = String(postData?.count ?? 0)
        
        guard let url = URL(string: urlString) else {
            failure?(nil)
            return
        }
        
        let session = URLSession.shared
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(postLength, forHTTPHeaderField: "Content-Length")
        request.httpBody = postData
        
        let task = session.dataTask(with: request) { data, urlResponse, error in
            
            guard let responseData = data else {
                failure?(error)
                return
            }
            
            let responseString = String(data: responseData, encoding: .ascii)
            success?(USeekUtils.getObjectFromJSONStringRepresentation(responseString))
        }
        task.resume()
    }
    
}

