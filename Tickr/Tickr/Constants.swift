//
//  Constants.swift
//  Tickr
//
//  Created by Stephen Payne on 4/8/16.
//  Copyright © 2016 Stephen Payne. All rights reserved.
//

import Foundation
import UIKit

class Constants {
    //MARK: - System Colors
    static let tickrGreen = UIColor(red: 76.0/255.0, green: 217.0/255.0, blue: 100.0/255.0, alpha: 1.0)
    static let tickrRed = UIColor(red: 255.0/255.0, green: 59.0/255.0, blue: 48.0/255.0, alpha: 1.0)
    static let tickrGray = UIColor(red: 128.0/255.0, green: 128.0/255.0, blue: 128.0/255.0, alpha: 1.0)
    static let tickrBlue = UIColor(red: 3.0/255.0, green: 169.0/255.0, blue: 244.0/255.0, alpha: 1.0)
    static let tickrButtonRed = UIColor(red:244.0/255.0, green: 67.0/255.0, blue: 54.0/255.0, alpha: 1.0)
    //MARK: - System Fonts
    static let tickrFont = UIFont(name: "Helvetica", size: 25)
    static let tickrSubTextFont = UIFont(name: "Helvetica", size: 20)
    static let tickrFontColor = UIColor.whiteColor()
    static let tickrLabelShadowOffset = CGSize(width: 0, height: 1)
    static let tickrLabelShadowColor = UIColor.blackColor().colorWithAlphaComponent(0.25)
    
    //MARK: - Stock Manager Constants
    static let kNotificationStockPricesUpdated = "stocksWereUpdated"
    static let kUpdateInterval = 3.0
    
    //URLS for finance API
    static let financeBaseURL = "https://query.yahooapis.com/v1/public/yql?q=select * from yahoo.finance.quotes where symbol IN "
    static let financeBaseURLForSingleQuery = "https://query.yahooapis.com/v1/public/yql?q=select * from yahoo.finance.quotes where symbol=*"
    static let financeEndURL = "&format=json&env=http://datatables.org/alltables.env"
    static let searchURL = "https://chstocksearch.herokuapp.com/api/"
}

//Will round a double to the desired number of decimal places
extension Double {
    /// Rounds the double to decimal places value
    func roundToPlaces(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return round(self * divisor) / divisor
    }
}