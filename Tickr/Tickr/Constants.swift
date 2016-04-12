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
    //MARK: - Font Constants
    static let tickrFontColor = UIColor.whiteColor()
    static let tickrLabelShadowOffset = CGSize(width: 0, height: 1)
    static let tickrLabelShadowColor = UIColor.blackColor().colorWithAlphaComponent(0.25)
    
    
    //MARK: - Stock Manager Constants
    static let kNotificationStockPricesUpdated = "stocksWereUpdated"
    static let kUpdateInterval = 2.0
    static let kPriceTargetWasHit = "priceTargetWasHit"
    
    
    //MARK: - URLS
    //For stock updates
    static let financeBaseURL = "https://query.yahooapis.com/v1/public/yql?q=select * from yahoo.finance.quotes where symbol IN "
    static let financeBaseURLForSingleQuery = "https://query.yahooapis.com/v1/public/yql?q=select * from yahoo.finance.quotes where symbol=*"
    static let financeEndURL = "&format=json&env=http://datatables.org/alltables.env"
    
    //For stock lookup
    static let searchURL = "https://chstocksearch.herokuapp.com/api/"
}
