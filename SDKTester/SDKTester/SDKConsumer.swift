//
//  SDKConsumer.swift
//  SDKTester
//
//  Created by Will Prevett on 2019-06-05.
//  Copyright © 2019 Will Prevett. All rights reserved.
//

import Foundation
import AdButler

class SDKConsumer : NSObject {
    var interstitialDelegate:ABInterstitialDelegate? = nil
    var VASTDelegate:ABVASTDelegate? = nil
    var parentViewController:ViewController!
    
    var banner:ABBanner? = nil
    var interstitial:ABInterstitial? = nil
    var log:(String)->Void = { str in }
    var position:String? = nil
    var vast:ABVASTVideo?
    
    init(parentViewController:ViewController) {
        self.parentViewController = parentViewController
        super.init()
    }
    
    func setInterstitialDelegate(_ delegate:ABInterstitialDelegate){
        self.interstitialDelegate = delegate
    }
    
    func setVASTDelegate(_ delegate:ABVASTDelegate){
        self.VASTDelegate = delegate
    }
    
    func setLoggingFunction(_ log:@escaping (String) -> Void){
        self.log = log
    }
    
    func setPosition(_ position:String?){
        self.position = position
    }
    
    func displayInterstitial(){
        self.interstitial?.display()
    }
    
    func getBanner(accountID:Int, zoneID:Int){
        let config = PlacementRequestConfig(accountId: accountID, zoneId: zoneID, width:0, height:0, customExtras:nil)
        config.personalizedAdsEnabled = true // <-- SDK user should check for permission here
        AdButler.requestPlacement(with: config) { response in
            switch response {
            case .success(_ , let placements):
                guard placements.count == 1 else {
                    self.log("Error - Invalid number of placements returned")
                    return
                }
                guard placements[0].isValid else {
                    self.log("Error - Invalid placement")
                    return
                }
                self.banner?.destroy()
                self.banner = ABBanner(placement:placements[0], parentViewController:self.parentViewController, position:self.position!, respectSafeAreaLayoutGuide:false, placementRequestConfig:config)
            case .badRequest(let statusCode, let responseBody):
                self.log("Bad Request.  Status Code - " + String(statusCode ?? 0) + "     \nresponseBody: \n" + (responseBody ?? ""))
                return
            case .invalidJson(let responseBody):
                self.log("Invalid JSON.\nresponseBody: \n" + (responseBody ?? ""))
                return
            case .requestError( _):
                self.log("Error in request placment")
                return
            }
        }
    }
    
    func getBanner(accountID:Int, zoneID:Int, container:UIView){
        let config = PlacementRequestConfig(accountId: accountID, zoneId: zoneID, width:0, height:0, customExtras:nil)
        config.personalizedAdsEnabled = true // <-- SDK user should check for permission here
        AdButler.requestPlacement(with: config) { response in
            switch response {
            case .success(_ , let placements):
                guard placements.count == 1 else {
                    self.log("Error - Invalid number of placements returned")
                    return
                }
                guard placements[0].isValid else {
                    self.log("Error - Invalid placement")
                    return
                }
                self.banner?.destroy()
                self.banner = ABBanner(placement:placements[0], container:container, respectSafeAreaLayoutGuide: false, placementRequestConfig:config)
            case .badRequest(let statusCode, let responseBody):
                self.log("Bad Request.  Status Code - " + String(statusCode ?? 0) + "     \nresponseBody: \n" + (responseBody ?? ""))
                return
            case .invalidJson(let responseBody):
                self.log("Invalid JSON.\nresponseBody: \n" + (responseBody ?? ""))
                return
            case .requestError( _):
                self.log("Error in request placement")
                return
            }
        }
    }
    
    func getInterstitial(accountID:Int, zoneID:Int){
        if(self.interstitialDelegate == nil){
            self.log("No Interstitial Delegate was assigned")
            return
        }
        
        let config = PlacementRequestConfig(accountId: accountID, zoneId: zoneID, width:0, height:0, customExtras:nil)
        AdButler.requestPlacement(with: config) { response in
            switch response {
            case .success(_ , let placements):
                guard placements.count == 1 else {
                    self.log("Error - Invalid number of placements returned")
                    return
                }
                guard placements[0].isValid else {
                    self.log("Error - Invalid placement")
                    return
                }
                if(placements[0].body != nil && placements[0].body != ""){
                    self.interstitial = ABInterstitial(placement:placements[0], parentViewController:self.parentViewController, delegate:self.interstitialDelegate!, respectSafeAreaLayoutGuide:true)
                }
            default:
                return
            }
        }
    }
    
    func getVASTVideo(accountID:Int, zoneID:Int, publisherID:Int, orientationMask:UIInterfaceOrientationMask? = nil){
        if(self.VASTDelegate == nil){
            self.log("No VAST Delegate was assigned")
            return
        }
        vast = ABVASTVideo()
        vast!.initialize(accountID: accountID, zoneID:zoneID, publisherID:publisherID, delegate:self.VASTDelegate, orientationMask:orientationMask)
        vast!.preload(container:parentViewController!.view)
    }
    
    func displayVASTVideo(){
        self.vast!.display()
    }
}
