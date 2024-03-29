//
//  Placement.swift
//  AdButler
//
//  Created by Ryuichi Saito on 11/9/16.
//  Copyright © 2016 AdButler. All rights reserved.
//

import Foundation

/// Models the `Placement` with all its properties.
@objc public class Placement: NSObject {
    /// The unique ID of the banner returned.
    public let bannerId: Int
    /// A pass-through click redirect URL.
    public let redirectUrl: String?
    /// The image banner URL.
    public let imageUrl: String?
    /// The width of this placement.
    public let width: Int
    /// The height of this placement.
    public let height: Int
    /// Alternate text for screen readers on the web.
    public let altText: String?
    /// An HTML target attribute.
    public let target: String
    /// An optional user-specified tracking pixel URL.
    public let trackingPixel: String?
    /// Used to record an impression for this request.
    public let accupixelUrl: String?
    /// Contains a zone URL to request a new ad.
    public let refreshUrl: String?
    /// The user-specified delay between refresh URL requests.
    public let refreshTime: String?
    /// The HTML markup of an ad request.
    public let body: String?
    /// List of Beacons for server to server network events
    public let beacons: [[String: String]]?
    /// Frequency capping data
    public let placementId: String?
    public let views: String?
    public let start: String?
    public let expiry: String?
    /// refresh variables
    public let rct:String?
    public let rcb:String?
    
    internal var clicked: Bool = false
    
    /// Optional URL beacons for server to server events.
    public let metadata: [[String: String]]?
    
    public init(bannerId: Int, redirectUrl: String? = nil, imageUrl: String? = nil, width: Int, height: Int, altText: String?, target: String, trackingPixel: String? = nil, accupixelUrl: String? = nil, refreshUrl: String? = nil, refreshTime: String? = nil, body: String? = nil, beacons: [[String: String]]? = nil, placementId: String? = nil, views: String? = nil, start: String? = nil, expiry: String? = nil, rct: String? = nil, rcb: String? = nil, metadata: [[String: String]]? = nil) {
        self.bannerId = bannerId
        self.redirectUrl = redirectUrl
        self.imageUrl = imageUrl
        self.width = width
        self.height = height
        self.altText = altText
        self.target = target
        self.trackingPixel = trackingPixel
        self.accupixelUrl = accupixelUrl
        self.refreshUrl = refreshUrl
        self.refreshTime = refreshTime
        self.body = body
        self.beacons = beacons
        self.placementId = placementId
        self.views = views;
        self.start = start;
        self.expiry = expiry;
        self.rct = rct;
        self.rcb = rcb;
        self.metadata = metadata
    }
}

public extension Placement {
    convenience init?(from jsonDictionary: [String: AnyObject]) {
        guard let bannerIdString = jsonDictionary["banner_id"],
            let bannerId = Int(bannerIdString as! String),
            let widthObj = jsonDictionary["width"],
            let heightObj = jsonDictionary["height"],
            let target = jsonDictionary["target"] else {
                return nil
        }
        
        let mapBlankToNil: (String?) -> String? = { str in
            if let str = str, !str.isEmpty {
                return str
            } else {
                return nil
            }
        }
        
        var width: Int!
        var height: Int!
        
        if(widthObj is Int){
            width = widthObj as? Int
        }else if (widthObj is String){
            width = Int(widthObj as! String)
        }
        if(heightObj is Int){
            height = heightObj as? Int
        }else if(heightObj is String){
            height = Int(heightObj as! String)
        }
        let redirectUrl = mapBlankToNil(jsonDictionary["redirect_url"] as? String)
        let imageUrl = mapBlankToNil(jsonDictionary["image_url"] as? String)
        let trackingPixel = mapBlankToNil(jsonDictionary["tracking_pixel"] as? String)
        let accupixelUrl = mapBlankToNil(jsonDictionary["accupixel_url"] as? String)
        let refreshUrl = mapBlankToNil(jsonDictionary["refresh_url"] as? String)
        let refreshTime = mapBlankToNil(jsonDictionary["refresh_time"] as? String)
        let body = mapBlankToNil(jsonDictionary["body"] as? String)
        let beacons = jsonDictionary["beacons"] as? [[String: String]]
        let placementId = mapBlankToNil(jsonDictionary["placement_id"] as? String)
        let views = mapBlankToNil(jsonDictionary["user_frequency_views"] as? String)
        let start = mapBlankToNil(jsonDictionary["user_frequency_start"] as? String)
        let expiry = mapBlankToNil(jsonDictionary["user_frequency_expiry"] as? String)
        let rct = mapBlankToNil(jsonDictionary["rct"] as? String)
        let rcb = mapBlankToNil(jsonDictionary["rcb"] as? String)
        
        let altText = mapBlankToNil(jsonDictionary["altText"] as? String)
        let metadata = jsonDictionary["metadata"] as? [[String: String]]
        
        self.init(bannerId: bannerId, redirectUrl: redirectUrl, imageUrl: imageUrl, width: width, height: height, altText: altText, target: target as! String, trackingPixel: trackingPixel, accupixelUrl: accupixelUrl, refreshUrl: refreshUrl, refreshTime: refreshTime, body: body, beacons: beacons, placementId: placementId, views: views, start: start, expiry: expiry, rct: rct, rcb: rcb, metadata: metadata)
    }
    
    var isValid:Bool {
        if(self.imageUrl == nil){
           return self.body != "" && self.body != nil
        }
        else{
            return self.bannerId != 0// && self.width != 0 && self.height != 0
        }
    }
}
