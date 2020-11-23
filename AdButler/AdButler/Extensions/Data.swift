//
//  Data.swift
//  AdButler
//
//  Created by Will Prevett on 2020-11-23.
//  Copyright © 2020 AdButler. All rights reserved.
//

import Foundation

extension Data {
    func toString() -> String? {
        return String(data: self, encoding: .utf8)
    }
}

extension URLRequest {
    func log() {
        print("\(httpMethod ?? "") \(self)")
        print("BODY \n \(httpBody?.toString())")
        print("HEADERS \n \(allHTTPHeaderFields)")
    }
}
