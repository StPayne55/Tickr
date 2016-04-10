//
//  StockManager.swift
//  Tickr
//
//  Created by Stephen Payne on 4/9/16.
//  Copyright © 2016 Stephen Payne. All rights reserved.
//

import Foundation
import UIKit

/*
    A singleton class responsible for getting stock data 
    from the API and communicating changes with any 
    View Controllers that may be listening.
*/
class StockManager {
    var isMakingRequest = false
    var session = NSURLSession.self()
    var stockArray = [Stock]()
    lazy var notificationCenter: NSNotificationCenter = {
        return NSNotificationCenter.defaultCenter()
    }()
    
    
    //singleton initialization
    class var sharedInstance : StockManager {
        struct Static {
            static let instance = StockManager()
        }
        return Static.instance
    }
    
    /*
        This will take a search term and try to look up stock symbols or company names based on that term
        - parameter term: A string to use as a search query
     */
    class func fetchStocksFromSearchTerm(term term: String, completion:(stockInfoArray: [StockSearchResult]) -> ()) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            
            //sanitize string
            let query = term.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLFragmentAllowedCharacterSet())
            let url = NSURL(string: "\(Constants.searchURL)\(query!)")
            
            //Create NSURLRequest and NSURLSession
            let request = NSURLRequest(URL: url!)
            let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
            let session = NSURLSession(configuration: sessionConfig)
            
            //setup task with completion handler
            let task : NSURLSessionDataTask = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
                
                //Make sure there was no error
                guard error == nil else {
                    print(error!.localizedDescription)
                    return
                }
                
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data!,
                        options:NSJSONReadingOptions.MutableContainers) as! NSArray
                    var stockInfoArray = [StockSearchResult]()
                    for result in json {
                        let company = result["company"] as! String
                        let symbol = result["symbol"] as! String
                        let newResult = StockSearchResult(symbol: symbol, name: company)
                        stockInfoArray.append(newResult)
                    }
                   completion(stockInfoArray: stockInfoArray)
                } catch {
                    print("Error: \(error)")
                }
            })
            
            //launch session task
            task.resume()
        }
    }

    
    /*
        Will fetch current prices from API, and send
        them to any listeners via NSNotification
        
        - parameter stocks: An array of Stock objects
     */
    func fetchListOfSymbols(stocks: [Stock]) {
        if !isMakingRequest {
            //Create quote portion of the URL
            //Example: ("AAPL","UWTI","TSLA")
            var tickers = "(";
            for stock in stocks {
                tickers = tickers+"\""+stock.symbol+"\","
            }
            tickers = tickers.substringToIndex(tickers.endIndex.predecessor())
            tickers = tickers + ")"
            tickers.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
            
            //Craft URL like so: BaseURL + Quotes + EndURL
            let fullURLString = (Constants.financeBaseURL + tickers + Constants.financeEndURL).stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLFragmentAllowedCharacterSet())
            let url = NSURL(string: fullURLString!)
            
            //Create NSURLRequest and NSURLSession
            let request = NSURLRequest(URL: url!)
            let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
            session = NSURLSession(configuration: sessionConfig)
            
            //setup task with completion handler
            let task : NSURLSessionDataTask = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
                
                //Make sure there was no error
                guard error == nil else {
                    print(error!.localizedDescription)
                    return
                }

                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data!,
                        options:NSJSONReadingOptions.MutableContainers) as! NSDictionary
                    
                    if let stockArrayWithData = self.parseJSON(json) {
                        self.parseStockData(stockArrayWithData)
                    }
                } catch {
                    print("Error: \(error)")
                }
            })
            
            //launch session task
            task.resume()
        }
    }
    
    /*
        This will parse the raw JSON and create an array of stock dictionaries. This is needed because the API will return either an array of dictionaries for multiple stocks or JUST a dictionary for a single stock. Either way, this will make sure that our parsing method receives the same data structure.
     */
    func parseJSON(json: NSDictionary) -> NSArray? {
        //parse json for expected values
        ////if updating for 1 ticker, we should expect a dictionary
        ////if updating for multiple tickers, we should expect an array of dictionaries
        if let q = json["query"] as? [String : AnyObject],
            let r = q["results"] as? [String : AnyObject] {
            if let quote = r["quote"] as? NSArray {
                return quote
            } else if let quote = r["quote"] as? NSDictionary {
                let tempArray = NSMutableArray(object: quote)
                return tempArray
            }
        }
        
        return nil
    }
    
    /*
        This will parse an array of results from the API.
     
        - parameter stockData: An array of dictionaries returned from the API
     */
    func parseStockData(stockData: NSArray) {
        stockArray.removeAll()
        for stock in stockData {
            var name: String = ""
            var symbol: String = ""
            var price: String = "0"
            var changeInPercentString: String = "0"
            var changeInPriceString: String = "0"
            var changeInPercentStringClean: NSString = "0"
            var changeInPriceStringClean: NSString = "0"
            
            let keys = Stock.SerializationKeys.self
            if let n = stock[keys.name] as? String {
                name = n
            }
            
            if let s = stock[keys.symbol] as? String {
                symbol = s
            }
            
            if let p = stock[keys.price] as? String {
                price = p
            }
            
            if let cPercent = stock[keys.changeInPercent] as? String {
                changeInPercentString = cPercent
            
                changeInPercentStringClean = (changeInPercentString as NSString).substringToIndex(changeInPercentString.characters.count-1)
            }
            
            if let cPrice = stock[keys.changeInPrice] as? String {
                changeInPriceString = cPrice
            
                changeInPriceStringClean = (changeInPriceString as NSString).substringToIndex(changeInPriceString.characters.count-1)
            }
            
            
            let newStock = Stock(name: name, symbol: symbol, price: Double(price)!, netChange: changeInPriceStringClean.doubleValue, netChangeInPercentage: changeInPercentStringClean.doubleValue)
            
            stockArray.append(newStock)
        }
        
        notififyListenersOfUpdates(stockArray)
    }
    
    /*  
        This will post a notification the contains a userInfo dictionary that has an array with stock updates
     
        - parameter data: An array of stock ticker symbols with their respective values
     */
    func notififyListenersOfUpdates(data: [Stock]) {
        //mark request as finished
        isMakingRequest = false
        dispatch_async(dispatch_get_main_queue(), {
            //Inform listeners that updates have been received and parsed
            self.notificationCenter.postNotificationName(Constants.kNotificationStockPricesUpdated, object: nil, userInfo: [Constants.kNotificationStockPricesUpdated: data])
        })
    }
}