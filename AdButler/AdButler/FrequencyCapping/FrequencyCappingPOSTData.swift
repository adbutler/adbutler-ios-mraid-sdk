//
//  FrequencyCappingPOSTData.swift
//  AdButler
//
//  Need a codable container for all our data in order to serialize it... thanks Apple.

import Foundation

public class FrequencyCappingPOSTData : Codable {
   
    public var ID: Int = 0
    public var setID: Int = 0
    public var width: Int? = 0
    public var height: Int? = 0
    public var kw: [String] = []
    public var click: String?
    public var aduid : String?
    public var dnt : Int?

    // Device Details
    public var dvmake : String? = "Apple"
    public var sw : Int?
    public var sh : Int?
    public var spr : Float?
    public var spdi : Double?
    public var lat : Double?
    public var long : Double?

    public var dvmodel : String?
    public var dvtype : String?
    public var os : String?
    public var osv : String?

    // AdButler Known Custom Extras
    public var age : Int?
    public var yob : Int?
    public var gender : String?
    public var coppa : Int? = 0

    // Network Details
    public var carrier : String?
    public var carriercode : String?
    public var network : String?
    public var carriercountry : String?
    public var ua : String?

    // App Details
    public var appname : String?
    public var appcode : String?
    public var appversion : String?
    public var lang : String?

    public var type: String = "json"

    public var rct: String?
    public var rcb: String?

    public var user_freq: [FrequencyCappingData]?
    public var _abdk_json: String?
}
