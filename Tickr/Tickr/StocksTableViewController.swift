//
//  StocksTableViewController.swift
//  Tickr
//
//  Created by Stephen Payne on 4/8/16.
//  Copyright © 2016 Stephen Payne. All rights reserved.
//

import UIKit

class StocksTableViewController: UIViewController {
    //Class Variables
    let stockManager = StockManager.sharedInstance
    let watchList = WatchListManager.sharedInstance
    
    lazy var notificationCenter: NSNotificationCenter = {
        return NSNotificationCenter.defaultCenter()
    }()
    
    //Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    
    //MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self

        //Listen for any updates from the Stock Manager
        notificationCenter.addObserver(self, selector: #selector(StocksTableViewController.stocksWereUpdated(_:)), name: Constants.kNotificationStockPricesUpdated, object: nil)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchStockUpdates()
    }

    //MARK: - Stock Updates
    /*
        This will fetch current stock prices on a set interval.
        This interval can be changed in Constants.swift
     */
    func fetchStockUpdates() {
        stockManager.fetchListOfSymbols(watchList.stocks)
        
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(Constants.kUpdateInterval * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(),
            {
                self.fetchStockUpdates()
            }
        )
    }
    
    /*
        This will be called when a stock update notification is received
     
        - parameter notification: a notification containing a userInfo dictionary that contains data on the stocks that were updated
     */
    func stocksWereUpdated(notification: NSNotification) {
        if let stocks = notification.userInfo?[Constants.kNotificationStockPricesUpdated] as? [Stock] {
            watchList.stocks.removeAll()
            for stock in stocks {
                watchList.stocks.append(stock)
            }
        }
        
        //reload the tableView to reflect the updates
        if tableView != nil {
            tableView.reloadData()
        }
    }
}


// MARK: - TableView Delegate and Datasource
extension StocksTableViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return watchList.stocks.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("tickrCell", forIndexPath: indexPath) as! TickrCell
        cell.parentVC = self
        cell.configureCellWithStock(watchList.stocks[indexPath.row])
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //allow user to set price alerts
    }
}


//A simple UITableView cell to display stock data
class TickrCell: UITableViewCell {
    //instance variables
    var parentVC: StocksTableViewController!
    
    //MARK: - Cell Outlets
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var percentageButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    
    func configureCellWithStock(stock: Stock) {
        //set the labels' text property to the stock ticker and the percentage gained/lost
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .CurrencyStyle
        let price = formatter.stringFromNumber(stock.price)
        let change = formatter.stringFromNumber(stock.netChange)
        priceLabel.text = price
        symbolLabel.text = "\(stock.symbol)"
        nameLabel.text = "\(stock.name)"
        percentageButton.setTitle("\(change!) (\(stock.netChangeInPercentage)%)", forState: .Normal)
        
        //set the cell color to match it's stock's performance
        switch stock.netChange {
            case let x where x < 0.0:
                self.contentView.backgroundColor = Constants.tickrRed //loss in value
            case let x where x > 0.0:
                self.contentView.backgroundColor = Constants.tickrGreen //gain in value
            default:
                self.contentView.backgroundColor = Constants.tickrGray //no price action
        }
        
        //setup the labels to make them more legible
        symbolLabel.textColor = Constants.tickrFontColor
        symbolLabel.font = Constants.tickrFont
        symbolLabel.shadowColor = Constants.tickrLabelShadowColor
        symbolLabel.shadowOffset = Constants.tickrLabelShadowOffset
        
        percentageButton.setTitleColor(Constants.tickrFontColor, forState: .Normal)
        percentageButton.setTitleShadowColor(Constants.tickrLabelShadowColor, forState: .Normal)
        percentageButton.titleLabel?.font = Constants.tickrSubTextFont
    }
}


//MARK: - SearchBar Delegate Methods
extension StocksTableViewController: UISearchBarDelegate {
    
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        self.performSegueWithIdentifier("searchSegue", sender: nil)
        return true
    }
    
}
