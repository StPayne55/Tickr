//
//  WatchListManager.swift
//  Tickr
//
//  Created by Stephen Payne on 4/10/16.
//  Copyright © 2016 Stephen Payne. All rights reserved.
//

import Foundation

/*
    A singleton class responsible for managing the 
    current list of stocks the user wishes to update.
 
    StockManager will maintain an array of stocks and StockManager
    will make queries using stocks exclusively from this list.
*/
class WatchListManager {
    //ONLY this class should be able to modify the contents of this array
    private(set) var stocks = [Stock]()
    
    lazy var notificationCenter: NSNotificationCenter = {
        return NSNotificationCenter.defaultCenter()
    }()
    
    //singleton initialization
    class var sharedInstance: WatchListManager {
        struct Static {
            static let instance = WatchListManager()
        }
        return Static.instance
    }
    
    //Alert Keys
    internal struct AlertKeys {
        static let symbol = "symbol"
        static let priceAlert = "priceAlert"
        static let price = "LastTradePriceOnly"
    }
    
    /*
        Will add a stock to the list as long as there isn't
        a stock that has a ticker symbol identical to it.
     
        - parameter stock: The stock we'd like to add to the list
        - parameter completion: Block invoked with a boolean indicating 
                                whether or not a stock was added to the list.
     */
    func addStockToWatchList(stock: Stock, completion: (Bool) -> Void) {
        //look for symbol matches
        let matches = stocks.filter { $0.symbol == stock.symbol }
        
        //if none exist, add the stock to the watchlist
        if matches.count == 0 {
            stocks.append(stock)
            
            //stock was added, let the caller know
            completion(true)
        }
        
        //no stock was added, let the caller know
        completion(false)
    }
    
    /*
        Will remove a stock from the list if it exists
     
        - parameter stock: The stock we wish to remove from the list
        - parameter completion: Block invoked with a boolean indicating
                                whether or not a stock was removed from the list.
    */
    func removeStockFromWatchList(stock: Stock, completion: (Bool) -> Void) {
        //look for possible matches
        let matches: [Stock] = stocks.filter { $0.symbol == stock.symbol }
        
        if matches.count != 0 {
            //if a match is found, remove it from the watch list
            if let index = stocks.indexOf(matches[0]) {
                stocks.removeAtIndex(index)
                
                //stock was removed, let the caller know
                completion(true)
            }
        }
        
        //stock wasn't found, let the caller know
        completion(false)
    }
    
    /*
        Will update existing stocks with new price data
     
        - parameter stockArray: An array of stocks to update the WatchList with
    */
    func updateStockArrayWithNewData(stockArray: [Stock]) {
        //We need to compare the array passed in with the local array
        for stock in stockArray {
            //With every match, update the price points but leave ticker, name and alerts
            let match = self.stocks.filter( { $0.symbol == stock.symbol } )
            
            //There will only ever be 1 match since a stock cannot be added to the
            //watchlist if it already exists in the watchlist.
            if match.count == 1 {
                let s = match[0]
                
                //update the stock data
                s.netChange = stock.netChange
                s.netChangeInPercentage = stock.netChangeInPercentage
                s.price = stock.price
                
                //check to see if price alert should be triggered
                if (s.price >= s.highPriceAlert || s.price <= s.lowPriceAlert)
                    && (s.highPriceAlert != nil || s.lowPriceAlert != nil) {
                    
                    //Determine which one was triggered
                    if let priceAlert = s.price >= s.highPriceAlert ? s.highPriceAlert : s.lowPriceAlert {
                        
                        //Create a dictionary with the information we wish to display
                        let stockAlertDict: [String : AnyObject] = [
                            AlertKeys.symbol : s.symbol,
                            AlertKeys.price : s.price,
                            AlertKeys.priceAlert : priceAlert
                        ]
                        
                        //Remove the alert
                        if priceAlert == s.highPriceAlert {
                            s.highPriceAlert = nil
                        } else {
                            s.lowPriceAlert = nil
                        }
                        
                        //Pass the dictionary to the notification method
                        self.notifyListenersOfPriceAlert(stockAlertDict)
                    }

                }
            }
        }
    }
    
    /*
        Will notify any listening view controllers that a target has been reached
     
        - parameter stockAlert: A dictionary containing information about the stock alert
    */
    func notifyListenersOfPriceAlert(stockAlert: [String : AnyObject]) {
        dispatch_async(dispatch_get_main_queue(), {
            //Inform listeners that a price targer has been reached
            self.notificationCenter.postNotificationName(Constants.kPriceTargetWasHit, object: nil, userInfo: [Constants.kPriceTargetWasHit: stockAlert])
        })
    }
}