//
//  AdButlerCustomExtras.swift
//  AdButler
//
//  Created by Will Prevett on 2018-03-19.
//  Copyright © 2018 AdButler. All rights reserved.
//

import Foundation

public class ABCustomExtras {
    private var Label : String
    public var Extras : [AnyHashable: Any]
    
    public init(label: String, values: [AnyHashable: Any] = [ : ]){
        self.Label = label
        Extras = [:]
    }
    
    public func GetLabel() -> String {
        return self.Label
    }
}
