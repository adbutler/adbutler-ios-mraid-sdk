//
//  MRAIDCalendarEvent.swift
//  AdButler
//

//  Copyright © 2018 AdButler, Inc. All rights reserved.
//

import Foundation

internal let MRAIDJSLocation = "https://servedbyadbutler.com/mraid.js"


let MRAIDVersion:String = "2.0"

struct MRAIDCalendarEvent : Codable {
    public let description:String
    public let location:String?
    public let start:String
    public let end:String?
    public let id:String?
    public let recurrence:MRAIDCalendarRecurrence?
    public let reminder:String?
    public let status:String?
    public let summary:String?
    public let transparency:String?
}

struct MRAIDCalendarRecurrence : Codable {
    public let frequency:String?
    public var daysInWeek:[Int]?
    public var daysInMonth:[Int]?
    public var monthsInYear:[Int]?
    public var daysInYear:[Int]?
    public var weeksInYear:[Int]?
    public let expires:String?
}

public struct Size : Codable {
    public let width:Int
    public let height:Int
}

public struct OrientationProperties : Codable {
    public let allowOrientationChange: Bool?
    public var forceOrientation: String?
}

public struct ResizeProperties : Codable {
    public let width:Int?
    public let height:Int?
    public let offsetX:Int?
    public let offsetY:Int?
    public let customClosePosition:String? // Positions constant
    public let allowOffscreen:Bool?
}

public struct ExpandProperties : Codable {
    public let width:Int?
    public let height:Int?
    public let useCustomClose:Bool?
    public let isModal:Bool?
}

internal struct States {
    static let LOADING = "loading"
    static let DEFAULT = "default"
    static let EXPANDED = "expanded"
    static let RESIZED = "resized"
    static let HIDDEN = "hidden"
}

public struct Positions {
    public static let TOP_LEFT = "top-left"
    public static let TOP_RIGHT = "top-right"
    public static let TOP_CENTER = "top-center"
    public static let CENTER = "center"
    public static let BOTTOM_LEFT = "bottom-left"
    public static let BOTTOM_CENTER = "bottom-center"
    public static let BOTTOM_RIGHT = "bottom-right"
    public static let CENTER_LEFT = "center-left"
    public static let CENTER_RIGHT = "center-right"
}

internal struct PlacementTypes {
    static let INLINE = "inline"
    static let INTERSTITIAL = "interstitial"
}

internal struct Orientations {
    static let PORTRAIT = "portrait"
    static let LANDSCAPE = "landscape"
    static let NONE = "none"
}

internal struct Features {
    static let SMS = "sms"
    static let TEL = "tel"
    static let STORE_PICTURE = "storePicture"
    static let INLINE_VIDEO = "inlineVideo"
    static let CALENDAR = "calendar"
}

internal struct NativeEndpoints {
    static let EXPAND = "expand"
    static let OPEN = "open"
    static let PLAY_VIDEO = "playVideo"
    static let RESIZE = "resize"
    static let STORE_PICTURE = "storePicture"
    static let CREATE_CALENDAR_EVENT = "createCalendarEvent"
    static let CALL_NUMBER = "callNumber"
    static let SET_ORIENTATION_PROPERTIES = "setOrientationProperties"
    static let SET_RESIZE_PROPERTIES = "setResizeProperties"
    static let REPORT_DOM_SIZE = "reportDOMSize"
    static let REPORT_JS_LOG = "reportJSLog"
    static let CLOSE = "close"
    static let SET_EXPAND_PROPERTIES = "setExpandProperties"
}

internal struct Events {
    static let READY = "ready"
    static let SIZE_CHANGE = "sizeChange"
    static let STATE_CHANGE = "stateChange"
    static let VIEWABLE_CHANGE = "viewableChange"
    static let ERROR = "error"
}

enum MRAIDError: Error {
    case invalidStartDate
    case invalidEndDate
    case invalidRecurrence
    case invalidCalendarEvent
    case invalidReminder
}
