//
//  PlacementRequestConfig.swift
//  AdButler
//

//  Copyright © 2018 AdButler, Inc. All rights reserved.
//

import Foundation
import CoreTelephony
import SystemConfiguration
import CoreLocation
import AdSupport
import WebKit

/// Configures the parameters used in requesting a `Placement`.
@objc public class PlacementRequestConfig: NSObject {
    // Ad Details
    public var accountId: Int = 0
    public var zoneId: Int = 0
    public var width: Int? = 0
    public var height: Int? = 0
    public var keywords: [String] = []
    public var click: String?
    public var advertisingId : String?
    @objc public var personalizedAdsEnabled: Bool = false
    public var doNotTrack : Int?
    
    // Device Details
    public var deviceManufacturer : String? = "Apple"
    public var screenWidth : Int?
    public var screenHeight : Int?
    public var screenPixelDensity : Float?
    public var screenDotsPerInch : Double?
    public var latitude : Double?
    public var longitude : Double?
#if os(iOS) || os(watchOS) || os(tvOS)
    public var deviceModel : String? = UIDevice.current.model
    public var deviceType : String? = UIDevice.current.modelName.replacingOccurrences(of: " ", with: "_")
    public var osName : String? = UIDevice.current.systemName
    public var osVersion : String? = UIDevice.current.systemVersion
#elseif os(OSX)
    public var deviceModel : String? // unknowable?
    public var deviceType : String? = "OSX Device"
    public var osName : String? = ProcessInfo.processInfo.operatingSystemName()
    public var osVersion : String? = ProcessInfo.processInfo.operatingSystemVersion
    #else
        // unknown OS
#endif
    
    // AdButler Known Custom Extras
    public var age : Int?
    public var yearOfBirth : Int?
    public var gender : String?
    public var coppa : Int? = 0
    
    // Network Details
    public var carrier : String?
    public var carrierCode : String?
    public var networkClass : String?
    public var carrierCountryIso : String?
    public var userAgent : String?
  
    // App Details
    public var appName : String?
    public var appPackageName : String?
    public var appVersion : String?
    public var language : String?
    
    public var customExtras : [AnyHashable: Any]?
    public var customExtraRaw : String?
    public var customAdServeURL : String?
    
    private let type: String = "json"
    
    public var rct: String?
    public var rcb: String?
    
    public var freqCapData: [FrequencyCappingData]?
    
    @objc public init(accountId: Int, zoneId: Int, width: Int, height: Int, personalizedAdsEnabled: Bool = false, keywords: [String] = [], click: String? = nil, customExtras: [AnyHashable: Any]?) {
        super.init()
        self.accountId = accountId
        self.zoneId = zoneId
        self.width = width == 0 ? nil : width
        self.height = height == 0 ? nil : height
        self.keywords = keywords
        self.click = click
        self.personalizedAdsEnabled = personalizedAdsEnabled
        
        getNetworkData()
        getDeviceData()
        getAppData()
        self.userAgent = UAString.userAgent
        getCustomEventData(customExtras)
    }
    
    func getIDFA() -> String? {
        if(!self.personalizedAdsEnabled){
            return nil
        }
        // Check whether advertising tracking is enabled
        guard ASIdentifierManager.shared().isAdvertisingTrackingEnabled else {
            return nil
        }
        
        // Get and return IDFA
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
    
    func getNetworkData(){
        let networkInfo = CTTelephonyNetworkInfo()
        carrier = networkInfo.subscriberCellularProvider?.carrierName
        carrierCode = networkInfo.subscriberCellularProvider?.mobileNetworkCode
        networkClass = networkInfo.currentRadioAccessTechnology
    }
    
    func getDeviceData(){
        screenWidth = Int(UIScreen.main.bounds.width)
        screenHeight = Int(UIScreen.main.bounds.height)
        screenPixelDensity = Float(UIScreen.main.scale)
        // screenDotsPerInch This is unknowable?
        
        // User location information should probably be left up to the sdk user to collect
        let locManager = CLLocationManager()
        
        if( CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
            
            latitude = (locManager.location?.coordinate.latitude)!
            longitude = (locManager.location?.coordinate.longitude)!
        }
        advertisingId = getIDFA();
    }
    
    func getAppData(){
        appName = Bundle.main.infoDictionary?["CFBundleName"] as! String?
        appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String?
        appPackageName = Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String?
        language = Locale.preferredLanguages[0]
    }
       
    func getCustomEventData(_ events : [AnyHashable: Any]?){
        if((events) != nil) {
            self.customExtras = events
            if(events!["age"] != nil && personalizedAdsEnabled){
                age = events!["age"] as! Int?
                self.customExtras!.removeValue(forKey: "age")
            }
            if(events!["gender"] != nil && personalizedAdsEnabled){
                gender = events!["gender"] as! String?
                self.customExtras!.removeValue(forKey: "gender")
            }
            if(events!["coppa"] != nil){
                coppa = events!["coppa"] as! Int?
                self.customExtras!.removeValue(forKey: "coppa")
            }
        }
    }
    
    
}

func json(from object:Any?) -> String? {
    if(object == nil){
        return nil
    }
    guard let data = try? JSONSerialization.data(withJSONObject: object!, options: []) else {
        return nil
    }
    return String(data: data, encoding: String.Encoding.utf8)
}

public extension PlacementRequestConfig {
    
    var queryStringPOST: String {
        var query = ""
        if (customExtras != nil && customExtras!.count > 0) {
            let jsonData = try? JSONSerialization.data(withJSONObject: customExtras as Any, options: [])
            let jsonString = String(data: jsonData!, encoding: .utf8)
            query += ";extra=\(jsonString as String?)"
        }else if(customExtraRaw != nil){
            query += ";extra=\(customExtraRaw!)"
        }
        let retQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return retQuery
    }
    
    var jsonBody: Data? {
        do{
            let jsonObject: FrequencyCappingPOSTData = FrequencyCappingPOSTData()
            jsonObject.ID = accountId
            jsonObject.setID = zoneId
            jsonObject.width = width
            jsonObject.height = height
            jsonObject.kw = keywords
            jsonObject.click = click
            jsonObject.aduid = advertisingId
            jsonObject.dnt = doNotTrack
            jsonObject.yob = yearOfBirth
            jsonObject.age = age
            jsonObject.gender = gender
            jsonObject.coppa = coppa
            jsonObject.carrier = carrier
            jsonObject.carriercode = carrierCode
            jsonObject.network = networkClass
            jsonObject.carriercountry = carrierCountryIso
            jsonObject.lat = latitude
            jsonObject.long = longitude
            jsonObject.dvmake = deviceManufacturer
            jsonObject.dvmodel = deviceModel
            jsonObject.dvtype = deviceType
            jsonObject.os = osName
            jsonObject.osv = osVersion
            jsonObject.lang = language
            jsonObject.sw = screenWidth
            jsonObject.sh = screenHeight
            jsonObject.spr = screenPixelDensity
            jsonObject.spdi = screenDotsPerInch
            jsonObject.ua = userAgent
            jsonObject.appname = appName
            jsonObject.appcode = appPackageName
            jsonObject.appversion = appVersion
            jsonObject.user_freq = freqCapData
            jsonObject.rct = rct
            jsonObject.rcb = rcb
            
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(jsonObject)
            return jsonData
        }catch{
            print("AdButler :: Error serializing JSON POST data")
        }
        return nil
    }
    
    var queryString: String {
        var query = ";ID=\(accountId);setID=\(zoneId)"
        if(height != nil && width != nil){query += ";size=\(width as Int?)x\(height as Int?)" }
        
        
        if !(advertisingId ?? "").isEmpty { query += ";aduid=\(advertisingId!)" }
        if (doNotTrack != nil) { query += ";dnt=\(doNotTrack!)" }
        
        if (screenWidth != nil) { query += ";sw=\(screenWidth!)" }
        if (screenHeight != nil) { query += ";sh=\(screenHeight!)" }
        if (screenPixelDensity != nil) { query += ";spr=\(screenPixelDensity!)" }
        //if (screenDotsPerInch != nil) { query += ";XXX=\(screenDotsPerInch!)" }
        if (latitude != nil) { query += ";lat=\(latitude!)" }
        if (longitude != nil) { query += ";long=\(longitude!)" }
        
        if !(deviceManufacturer ?? "").isEmpty{ query += ";dvmake=\(deviceManufacturer!)" }
        if !(deviceModel ?? "").isEmpty{ query += ";dvmodel=\(deviceModel!)" }
        if !(deviceType ?? "").isEmpty{ query += ";dvtype=\(deviceType!)" }
        if !(osName ?? "").isEmpty{ query += ";os=\(osName!)" }
        if !(osVersion ?? "").isEmpty{ query += ";osv=\(osVersion!)" }
        
        if (age != nil) { query += ";age=\(age!)" }
        if (yearOfBirth != nil) { query += ";yob=\(yearOfBirth!)" }
        if !(gender ?? "").isEmpty{ query += ";gender=\(gender!)" }
        if (coppa != nil) { query += ";coppa=\(coppa!)" }
        
        if !(carrier ?? "").isEmpty{ query += ";carrier=\(carrier!)" }
        if !(carrierCode ?? "").isEmpty{ query += ";carriercode=\(carrierCode!)" }
        if !(networkClass ?? "").isEmpty{ query += ";network=\(networkClass!)" }
        if !(carrierCountryIso ?? "").isEmpty{ query += ";carriercountry=\(carrierCountryIso!)" }
        
        if !(userAgent ?? "").isEmpty{ query += ";ua=\(userAgent!)" }
        
        if !(appName?.isEmpty)!{ query += ";appname=\(appName!)" }
        if !(appPackageName?.isEmpty)!{ query += ";appdomain=\(appPackageName!)" }
        if !(appVersion?.isEmpty)!{ query += ";appversion=\(appVersion!)" }
        if !(language?.isEmpty)!{ query += ";lang=\(language!)" }
        
        if (customExtras != nil && customExtras!.count > 0) {
            let jsonData = try? JSONSerialization.data(withJSONObject: customExtras as Any, options: [])
            let jsonString = String(data: jsonData!, encoding: .utf8)
            query += ";extra=\(jsonString as String?)"
        }else if(customExtraRaw != nil){
            query += ";extra=\(customExtraRaw!)"
        }

        
        if (keywords != []) {
            let keywordsString = keywords.joined(separator: ",")
            query += ";kw=\(keywordsString)"
        }
        if let click = click {
            query += ";click=\(click)"
        }
        
        // URL Encode query string
        let retQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        return retQuery
    }
}
