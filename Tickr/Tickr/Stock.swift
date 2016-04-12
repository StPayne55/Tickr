//
//  Stock.swift
//  Tickr
//
//  Created by Stephen Payne on 4/9/16.
//  Copyright © 2016 Stephen Payne. All rights reserved.
//

import Foundation

class Stock: NSObject {
    //Stock Properties
    var name: String
    var symbol: String
    var price: Double
    var netChange: Double
    var netChangeInPercentage: Double
    
    //price alerts
    var lowPriceAlert: Double?
    var highPriceAlert: Double?
    
    //Serialization keys match the Yahoo Finance API keys
    internal struct SerializationKeys {
        static let symbol = "symbol"
        static let name = "Name"
        static let changeInPercent = "ChangeinPercent"
        static let changeInPrice = "Change"
        static let price = "LastTradePriceOnly"
    }
    
    /*
        This will initialize an instance of Stock with properties
     
        - parameter symbol: A String for the stock's ticker symbol
        - parameter price: A double for the stock's current price
        - parameter netChange: A double for the stock's change in price
        - parameter netChangeInPercentage: A double for the stock's net change in percentage points
    */
    init(name : String, symbol: String, price: Double, netChange: Double, netChangeInPercentage: Double) {
        self.name = name
        self.symbol = symbol
        self.price = price
        self.netChange = netChange
        self.netChangeInPercentage = netChangeInPercentage
    }
}

//For Search Results
struct StockSearchResult {
    var symbol: String?
    var name: String?
}