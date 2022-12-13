//
//  AdButler.swift
//  AdButler
//
//  Copyright © 2018 AdButler, Inc. All rights reserved.
//

import Foundation

fileprivate let baseUrl = "https://servedbyadbutler.com/adserve"

/// The class used to make requests against the AdButler API.
@objc public class AdButler: NSObject {
    public static var frequencyCappingManager: FrequencyCappingManager = FrequencyCappingManager()
    private static var pageID: Int = 0
    private static var zonePlaceMap: [Int : Int] = [Int : Int]()
    
    public static func getPageID() -> Int {
        return pageID
    }
    
    public static func getPlace(_ zoneID:Int) -> Int {
        return zonePlaceMap[zoneID] ?? 0
    }
    
    public override init() {
        super.init()
    }
    
    public static func initialize(mainView:UIView?) {
        if(mainView !== nil){
            UAString.init(view: mainView!)
        }
        resetUniqueDelivery()
    }
    
    static var session = Session().urlSession
    
    public static func resetUniqueDelivery() -> Void {
        var number:String = String()
        for _ in 1...7 {
           number += "\(Int.random(in: 1...9))"
        }
        pageID = Int(number)!
        zonePlaceMap = [Int: Int]()
    }
    
    public static func incrementUniqueDelivery(_ zoneID:Int) -> Void {
        if(zonePlaceMap[zoneID] != nil) {
            zonePlaceMap[zoneID]! += 1
        } else {
            zonePlaceMap[zoneID] = 0
        }
    }
    
    /**
     Requests multiple placements.
     
     - Parameter with: the configurations, each used for one placement respectively.
     - Parameter completionHandler: a callback block that you provide to handle the response. The block will be given a `Response` object.
     */
    public static func requestPlacements(with configs: [PlacementRequestConfig], completionHandler: @escaping (Response) -> Void) {
        for config in configs{
            config.freqCapData = AdButler.frequencyCappingManager.getData()
        }
        let requestManager = RequestManager(session: session, baseUrl: baseUrl, configs: configs, completionHandler: completionHandler)
        requestManager.request()
    }
    
    /**
     Requests multiple placements with explicit success and failure callbacks. Provided for Objective-C compatibility.
     
     - Parameter configs: the configurations, each used for one placement respectively.
     - Parameter success: a success callback block. The block will be given a `String` status and a list of `Placement`s.
     - Parameter failure: a failure callback block with status code, response body, and error.
     */
    @objc public static func requestPlacements(configs: [PlacementRequestConfig], success: @escaping (String, [Placement]) -> Void, failure: @escaping (NSNumber?, String?, Error?) -> Void) {
        requestPlacements(with: configs) { $0.objcCallbacks(success: success, failure: failure) }
    }
    
    /**
     Requests a single placement.
     
     - Parameter with: the configuration used for requesting one placement.
     - Parameter completionHandler: a callback block that you provide to handle the response. The block will be given a `Response` object.
     */
    public static func requestPlacement(with config: PlacementRequestConfig, completionHandler: @escaping (Response) -> Void) {
        config.freqCapData = AdButler.frequencyCappingManager.getData()
        let requestManager = RequestManager(session: session, baseUrl: baseUrl, config: config, completionHandler: completionHandler)
        requestManager.request()
    }
    
    
    /**
     Requests a single placement with explicit success and failure callbacks. Provided for Objective-C compatibility.
     
     - Parameter config: the configuration used for requesting one placement.
     - Parameter success: a success callback block. The block will be given a `String` status and a list of `Placement`s.
     - Parameter failure: a failure callback block with status code, response body, and error.
     */
    @objc public static func requestPlacement(config: PlacementRequestConfig, success: @escaping (String, [Placement]) -> Void, failure: @escaping (NSNumber?, String?, Error?) -> Void) {
        requestPlacement(with: config) { $0.objcCallbacks(success: success, failure: failure) }
    }
    
    public static func refreshPlacement(with placement: Placement, config:PlacementRequestConfig, completionHandler: @escaping (Response) -> Void){
        let placementOperation = PlacementRequestOperation(session:session, baseUrl: baseUrl, config:config, completionHandler: completionHandler)
        placementOperation.refresh(url:placement.refreshUrl!)
    }
    
    @objc public static func refreshPlacement(placement: Placement, config:PlacementRequestConfig, success: @escaping(String, [Placement]) -> Void, failure: @escaping(NSNumber?, String?, Error?) -> Void) {
        refreshPlacement(with: placement, config:config) { $0.objcCallbacks(success: success, failure: failure) }
    }
    
    /**
     Requests a pixel.
     
     - Parameter with: the `URL` for this pixel.
     */
    @objc(requestPixelWithURL:)
    public static func requestPixel(with url: URL) {
        let task = session.dataTask(with: url) { (_, _, error) in
            if error != nil {
                print("Error requeseting a pixel with url \(url.absoluteString)")
            }
        }
        task.resume()
    }
}

extension Response {
    func objcCallbacks(success: @escaping (String, [Placement]) -> Void, failure: @escaping (NSNumber?, String?, Error?) -> Void) {
        switch self {
        case .success(let status, let placements):
            success(status.rawValue, placements)
        case .badRequest(let statusCode, let responseBody):
            var statusCodeNumber: NSNumber? = nil
            if let statusCode = statusCode {
                statusCodeNumber = statusCode as NSNumber
            }
            failure(statusCodeNumber, responseBody, nil)
        case .invalidJson(let responseBody):
            failure(nil, responseBody, nil)
        case .requestError(let error):
            failure(nil, nil, error)
        }
    }
}
