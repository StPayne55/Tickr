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
    var stocks = [Stock]()
    
    //singleton initialization
    class var sharedInstance: WatchListManager {
        struct Static {
            static let instance = WatchListManager()
        }
        return Static.instance
    }
    
    /*
        Will add a stock to the list as long as there isn't
        a stock that has a ticker symbol identical to it.
     
        - parameter stock: The stock we'd like to add to the list
        - parameter completion: Block invoked with a boolean indicating 
                                whether or not a stock was added to the list.
     */
    func addStockToWatchList(stock: Stock, completion: (Bool) -> Void) {
        //look for possible matches
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
        let match: Stock = stocks.filter { $0.symbol == stock.symbol }[0]
        
        //if a match is found, remove it from the watch list
        if let index = stocks.indexOf(match) {
            stocks.removeAtIndex(index)
            
            //stock was removed, let the caller know
            completion(true)
        }
        
        //stock wasn't found, let the caller know
        completion(false)
    }
}