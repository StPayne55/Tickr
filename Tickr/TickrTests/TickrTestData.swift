//
//  TickrTestData.swift
//  Tickr
//
//  Created by Stephen Payne on 4/10/16.
//  Copyright © 2016 Stephen Payne. All rights reserved.
//

import Foundation
@testable import Tickr

//Will create test data for unit tests upon instantiation
class TickrTestData {
    //a stock array
    static var stocks = [Stock]()
    static var singleResultData: NSData!
    static var doubleResultData: NSData!
    static var badResultData: NSData!
    
    init() {
        TickrTestData.stocks.removeAll()
        //create some fake stocks and add to array
        let symbol = "UWTI"
        let price = 180.00
        let change = 5.4
        let changeInPrice = 10.0
        let newStock = Stock(name: "Velocity Shares 3x Crude Oil", symbol: symbol, price: price, netChange: change, netChangeInPercentage: changeInPrice)
        TickrTestData.stocks.append(newStock)
        
        let symbol2 = "GOOG"
        let price2 = 180.00
        let change2 = -5.4
        let changeInPrice2 = -10.0
        let newStock2 = Stock(name: "Google", symbol: symbol2, price: price2, netChange: change2, netChangeInPercentage: changeInPrice2)
        TickrTestData.stocks.append(newStock2)
        
        let symbol3 = "TSLA"
        let price3 = 180.00
        let change3 = 0.0
        let changeInPrice3 = 0.0
        let newStock3 = Stock(name: "Tesla", symbol: symbol3, price: price3, netChange: change3, netChangeInPercentage: changeInPrice3)
        TickrTestData.stocks.append(newStock3)
        
        //create JSON data for single result
        var path = NSBundle(forClass: TickrTests.self)
            .pathForResource("SingleResult", ofType: "json")
        TickrTestData.singleResultData = NSData(contentsOfFile: path!)
        
        //create JSON data for two results
        path = NSBundle(forClass: TickrTests.self)
            .pathForResource("DoubleResult", ofType: "json")
        TickrTestData.doubleResultData = NSData(contentsOfFile: path!)
        
        //create JSON data with unexpected structure
        path = NSBundle(forClass: TickrTests.self).pathForResource("BadResponse", ofType: "json")
        TickrTestData.badResultData = NSData(contentsOfFile: path!)
        
    }
    
}