//
//  ABVASTParser.swift
//  AdButler
//
//  Copyright © 2019 AdButler. All rights reserved.
//

import Foundation

class ABVASTParser : NSObject, XMLParserDelegate {
    private var companions:[ABVASTCompanion] = []
    private var currentCompanion:ABVASTCompanion?
    private var currentElement:String?
    private var currentEvent:String?
    private var vastVideo:ABVASTVideo!
    
    init(_ vastVideo:ABVASTVideo){
        self.vastVideo = vastVideo
        super.init()
    }
    
    internal func parseXML(_ xml:String){
        let data = xml.data(using: .utf8)
        if(data != nil){
            let xoc = XMLParser(data: data!)
            xoc.delegate = self
            xoc.parse()
        }
    }
    
    private func findBestCompanion() -> ABVASTCompanion? {
        let fsRect = CGSize(width:UIScreen.main.bounds.width, height:UIScreen.main.bounds.height)
        let aspectRatio = fsRect.width / fsRect.height
        var closestRatio:CGFloat = 0.0
        var curBest:ABVASTCompanion? = nil
        self.companions.forEach({c in
            let w = c.width!
            let h = c.height!
            let r = CGFloat(w) / CGFloat(h)
            if(closestRatio == 0.0 || (abs(aspectRatio - r) < closestRatio)){
                closestRatio = r
                curBest = c
            }
        })
        return curBest
    }
    
    
    public func parserDidStartDocument(_ parser: XMLParser) {
        
    }
    
    public func parserDidEndDocument(_ parser: XMLParser){
        if(self.vastVideo != nil){
            self.vastVideo!.endCardCompanion = findBestCompanion()
        }
    }
    
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        self.currentElement = elementName
        if(elementName == "Companion"){
            currentCompanion = ABVASTCompanion()
            let w = attributeDict["width"]
            let h = attributeDict["height"]
            
            if(w != nil){
                currentCompanion!.width = Int(w!)
            }
            if(h != nil){
                currentCompanion!.height = Int(h!)
            }
        }
        if(self.vastVideo != nil){
            if(elementName == "Linear"){
                let so = attributeDict["skipoffset"]
                if(so == nil){
                    self.vastVideo.closeButtonRequired = true
                }
            }
            if(elementName == "Tracking"){
                currentEvent = attributeDict["event"]
            }
        }
    }
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if(elementName == "Companion"){
            self.companions.append(self.currentCompanion!)
        }
    }
    
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        let data = string.trimmingCharacters(in:CharacterSet.whitespacesAndNewlines)
        if(!data.isEmpty){
            if(currentCompanion != nil){
                switch(self.currentElement){
                case "StaticResource":
                    self.currentCompanion?.staticResource = string
                case "HTMLResource":
                    self.currentCompanion?.htmlResource = string
                case "Tracking":
                    if(currentCompanion?.trackingEvents == nil){
                        currentCompanion?.trackingEvents = [String:String]()
                    }
                    self.currentCompanion?.trackingEvents![currentEvent!] = string
                case "CompanionClickThrough":
                    self.currentCompanion?.clickThrough = string
                default:
                    break
                }
            }
        }
    }
    
    public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("parse failed")
    }
    
    public func parser(_ parser: XMLParser, validationErrorOccurred validationError: Error) {
        print("validation failed")
    }
}
