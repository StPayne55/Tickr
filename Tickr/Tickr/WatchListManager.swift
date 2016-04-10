//
//  WatchListManager.swift
//  Tickr
//
//  Created by Stephen Payne on 4/10/16.
//  Copyright © 2016 Stephen Payne. All rights reserved.
//

import Foundation

class WatchListManager {
    var stocks = [Stock]()
    
    //singleton initialization
    class var sharedInstance: WatchListManager {
        struct Static {
            static let instance = WatchListManager()
        }
        return Static.instance
    }
}