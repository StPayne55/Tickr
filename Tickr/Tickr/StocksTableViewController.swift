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
    var stocks = [Stock]()
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
        self.fetchStockUpdates()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //Listen for any updates from the Stock Manager
        notificationCenter.addObserver(self, selector: #selector(StocksTableViewController.stocksWereUpdated(_:)), name: Constants.kNotificationStockPricesUpdated, object: nil)
        
        //Reload tableView to reflect any changes in the search view
        tableView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        //No reason to update the stock data when the stock view isn't visible
        notificationCenter.removeObserver(self)
    }

    
    //MARK: - Stock Updates
    /*
        This will fetch current stock prices on a set interval.
        This interval can be changed in Constants.swift.
     
        Stocks are added to the WatchList stock array. StockManager then
        makes a query on the stocks in that array. Those stock updates 
        are parsed, and then sent back here using a NSNotification. 
        From there, they're added to the local array and displayed.
     */
    func fetchStockUpdates() {
        StockManager.sharedInstance.fetchListOfSymbols(WatchListManager.sharedInstance.stocks)
        
        //This will call fetchStockUpdates only after the update interval has elapsed
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
        //parse the notification userInfo dictionary and update the local array
        if let stocks = notification.userInfo?[Constants.kNotificationStockPricesUpdated] as? [Stock] {
            self.stocks.removeAll()
            for stock in stocks {
                self.stocks.append(stock)
            }
        }
        
        //reload the tableView to reflect the updates
        tableView.reloadData()
    }
}


// MARK: - TableView Delegate and Datasource
extension StocksTableViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stocks.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("tickrCell", forIndexPath: indexPath) as! TickrCell
        cell.configureCellWithStock(self.stocks[indexPath.row])
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let tableHeight = tableView.frame.height
        let stockCount = CGFloat(self.stocks.count)
        
        //Cells should be scaled so that there is no blank space in the tableView.
        //100 is the minimum cell height. Cells will never be smaller than that.
        let rowHeight = tableHeight / stockCount
        if stockCount > 0 && rowHeight > 80 {
            return rowHeight
        }
        return 80
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //allow user to set price alerts
    }
    
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        //Will display price alert options
        let moreRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Price\nAlerts", handler:{action, indexpath in
            
        });
        moreRowAction.backgroundColor = Constants.tickrBlue
        
        //Will delete a stock from the watch list and from the local array
        let deleteRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete", handler:{action, indexpath in
            //Remove stock watchlist and local array if successful
            let stockToDelete = self.stocks[indexPath.row]
            WatchListManager.sharedInstance.removeStockFromWatchList(stockToDelete, completion: { (didDeleteStock) in
                
                //If stock was removed from watchlist, remove it from local array also
                if didDeleteStock {
                    self.stocks.removeAtIndex(indexPath.row)
                    
                    //Delete the row corresponding to that stock
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                    StockManager.sharedInstance.shouldCancelUpdate = false
                }
            })
        });
        
        deleteRowAction.backgroundColor = Constants.tickrButtonRed
        return [deleteRowAction, moreRowAction];
    }
}


//MARK: - SearchBar Delegate Methods
extension StocksTableViewController: UISearchBarDelegate {
    //When the searchbar is selected, we want to segue to the SearchTableViewController
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        self.performSegueWithIdentifier("searchSegue", sender: nil)
        return true
    }
    
}


//MARK: - TickrCell Class - A simple UITableView cell for displaying stock data
class TickrCell: UITableViewCell {
    
    //MARK: - Cell Outlets
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var percentageButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    /*
        Will configure a TickrCell and populate outlets with stock data
     
        - parameter stock: A Stock object this cell is to display
    */
    func configureCellWithStock(stock: Stock) {
        //set price, symbol, and name label as well as the percentage button
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .CurrencyStyle
        let price = formatter.stringFromNumber(stock.price)
        let change = formatter.stringFromNumber(stock.netChange)
        priceLabel.text = price
        symbolLabel.text = "\(stock.symbol)"
        nameLabel.text = "\(stock.name)"
        percentageButton.setTitle("\(change!) (\(stock.netChangeInPercentage.roundToPlaces(2))%)", forState: .Normal)
        
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
        
        //setup the percentage button
        percentageButton.setTitleColor(Constants.tickrFontColor, forState: .Normal)
        percentageButton.setTitleShadowColor(Constants.tickrLabelShadowColor, forState: .Normal)
        percentageButton.titleLabel?.font = Constants.tickrSubTextFont
    }
    
    
    //This is used to temporarily stop updates while a cell is swiped open.
    //Otherwise, the cell will snap back when the tableView is updated.
    override func willTransitionToState(state: UITableViewCellStateMask) {
        switch(state) {
        //Cell is swiped open
        case UITableViewCellStateMask.ShowingDeleteConfirmationMask:
            StockManager.sharedInstance.shouldCancelUpdate = true
            break
        //Cell is closed
        case UITableViewCellStateMask.DefaultMask:
            StockManager.sharedInstance.shouldCancelUpdate = false
            break
        default:
            //Default case
            print(state)
        }
    }
}
