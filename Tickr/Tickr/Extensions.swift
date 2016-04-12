//
//  Extensions.swift
//  Tickr
//
//  Created by Stephen Payne on 4/11/16.
//  Copyright © 2016 Stephen Payne. All rights reserved.
//

import Foundation
import UIKit


//MARK: - Double
//Will round a double to the desired number of decimal places
extension Double {
    /// Rounds the double to decimal places value
    func roundToPlaces(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return round(self * divisor) / divisor
    }
}


//MARK: - UIFont
extension UIFont {
    
    class func tickrFontOfSize(size: CGFloat) -> UIFont {
        return UIFont(name: "Helvetica", size: size)!
    }
    
    class func tickrSubTextFontOfSize(size: CGFloat) -> UIFont {
        return UIFont(name: "Helvetica-Bold", size: size)!
    }
}


//MARK: - UIColor
extension UIColor {
    
    class func tickrRed() -> UIColor {
        return UIColor(red: 255.0/255.0, green: 59.0/255.0, blue: 48.0/255.0, alpha: 1.0)
    }
    
    class func tickrGreen() -> UIColor {
        return UIColor(red: 76.0/255.0, green: 217.0/255.0, blue: 100.0/255.0, alpha: 1.0)
    }
    
    class func tickrGray() -> UIColor {
        return UIColor(red: 128.0/255.0, green: 128.0/255.0, blue: 128.0/255.0, alpha: 1.0)
    }
    
    class func tickrBlue() -> UIColor {
        return UIColor(red: 3.0/255.0, green: 169.0/255.0, blue: 244.0/255.0, alpha: 1.0)
    }
    
    class func tickrButtonRed() -> UIColor {
        return UIColor(red:230.0/255.0, green: 70.0/255.0, blue: 60.0/255.0, alpha: 1.0)
    }
}
