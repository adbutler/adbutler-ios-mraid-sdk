//
//  PostMessageHandler.swift
//  AdButler
//
//  Copyright © 2019 AdButler. All rights reserved.
//

import Foundation
import WebKit

class ABPostMessageHandler: NSObject, WKScriptMessageHandler{
    
    var vast:ABVASTVideo!
    
    func initialize(vast:ABVASTVideo) {
        self.vast = vast
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "vastPlayerMessageHandler", let messageBody = message.body as? [String:Any] {
            if let xml = messageBody["xml"] as? String {
                ABVASTParser(self.vast).parseXML(xml.decodeUrl()!)
            }
                
            if let event = messageBody["event"] as? String {
                print("Event: \(event)")
                self.vast.handleEvent(event)
            }
        }
    }
}
