//
//  Extensions.swift
//  SDKTester
//
//  Created by Will Prevett on 2019-06-05.
//  Copyright © 2019 Will Prevett. All rights reserved.
//

import Foundation
import UIKit

extension String{
    func trunc(length: Int, trailing: String = "…") -> String {
        if (self.count <= length) {
            return self
        }
        var truncated = self.prefix(length)
        while truncated.last != " " {
            truncated = truncated.dropLast()
        }
        return truncated + trailing
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}
