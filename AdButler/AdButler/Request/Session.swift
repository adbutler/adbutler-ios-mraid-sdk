//
//  Session.swift
//  AdButler
//
//  Created by Ryuichi Saito on 11/12/16.
//  Copyright © 2016 AdButler. All rights reserved.
//

import Foundation
import UIKit

struct Session {
    let urlSession: URLSession
    
    init() {
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.httpAdditionalHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": "AdButler/\(AdButlerVersionNumber) (\(UIDevice.deviceModel); \(UIDevice.osVersion))"
        ]
        urlSession = URLSession(configuration: sessionConfig)
    }
}
