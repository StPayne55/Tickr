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
        notificationCenter.addObserver(
            self,
            selector: #selector(StocksTableViewController.stocksWereUpdated(_:)),
            name: Constants.kNotificationStockPricesUpdated,
            object: nil
        )
        
        //Listen for any stock price alerts from the WatchList Manager
        notificationCenter.addObserver(
            self,
            selector: #selector(StocksTableViewController.priceTargetWasHit(_:)),
            name: Constants.kPriceTargetWasHit,
            object: nil
        )
        
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
        
        //Update any stocks in the WatchList
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
     
        - parameter notification: a notification containing a userInfo dictionary that 
                                  contains data on the stocks that were updated.
     */
    func stocksWereUpdated(notification: NSNotification) {
        
        //reload the tableView to reflect the updates
        tableView.reloadData()
    }
    
    /*
        This will display an alert when a price target is reached
     
        - parameter notification: a notification containing userInfo dictionary that
                                  contains data on the stock that hit a price target.
    */
    func priceTargetWasHit(notification: NSNotification) {
        //Parse notification's userInfo dictionary for relevant alert data
        if let alertInfo = notification.userInfo![Constants.kPriceTargetWasHit] as? [String : AnyObject]{
            
            //Parse out symbol, price, and the price target
            if let symbol = alertInfo[WatchListManager.AlertKeys.symbol] as? String,
                let price = alertInfo[WatchListManager.AlertKeys.price] as? Double,
                    let priceTarget = alertInfo[WatchListManager.AlertKeys.priceAlert] {
                
                    //Create alert view with the alert data
                    let alert = UIAlertController(title: "Price Target Reached!", message: "\(symbol) just reached $\(price.roundToPlaces(2)) and triggered your price target of $\(priceTarget)", preferredStyle: .Alert)
                
                    //Okay button
                    let okAction = UIAlertAction(title: "OK", style: .Default, handler: { _ in })
                
                    //Add okay button to alert view
                    alert.addAction(okAction)
                
                    //Present the alert view
                    self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
}


// MARK: - TableView Delegate and Datasource
extension StocksTableViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return WatchListManager.sharedInstance.stocks.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("tickrCell", forIndexPath: indexPath) as! TickrCell
        cell.configureCellWithStock(WatchListManager.sharedInstance.stocks[indexPath.row])
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let tableHeight = tableView.frame.height
        let stockCount = CGFloat(WatchListManager.sharedInstance.stocks.count)
        
        //Cells should be scaled so that there is no blank space in the tableView.
        //80 is the minimum cell height. Cells will never be smaller than that.
        let rowHeight = tableHeight / stockCount
        if stockCount > 0 && rowHeight > 80 {
            return rowHeight
        }
        return 80
    }
    
    //When a cell is swiped to the left, the user should be able to set price alerts
    //and delete a specific stock
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        //Will display price alert options
        let moreRowAction = UITableViewRowAction(
            style: UITableViewRowActionStyle.Default,
            title: "Price\nAlerts",
            handler:{action, indexpath in
                
            //Display alert with field and options
            self.displayActionSheetForAlerts(WatchListManager.sharedInstance.stocks[indexPath.row])
        });
        
        
        //Will delete a stock from the watch list and from the local array
        let deleteRowAction = UITableViewRowAction(
            style: UITableViewRowActionStyle.Default,
            title: "Delete",
            handler:{action, indexpath in
                
            //Remove stock watchlist and local array if successful
            let stockToDelete = WatchListManager.sharedInstance.stocks[indexPath.row]
            WatchListManager.sharedInstance.removeStockFromWatchList(stockToDelete, completion: { (didDeleteStock) in
                
                //If stock was removed from watchlist, remove it from local array also
                if didDeleteStock {
                    //Delete the row corresponding to that stock
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                    StockManager.sharedInstance.shouldCancelUpdate = false
                }
            })
        });
        
        moreRowAction.backgroundColor = Constants.tickrBlue
        deleteRowAction.backgroundColor = Constants.tickrButtonRed
        return [deleteRowAction, moreRowAction];
    }
    
    //Will display an alertView that will let the user enter a price alert target
    func displayActionSheetForAlerts(stock: Stock) {
        //Create textField to get user input
        var priceTargetTextField: UITextField?
        
        //Setup alert sheet
        let alert = UIAlertController(
            title: "Price Target",
            message: "Once this stock reaches your price target, you'll be alerted.\nCurrent Price: $\(stock.price.roundToPlaces(2))",
            preferredStyle: .Alert
        )
        
        //This option will allow the user to select a high price alert
        let alertAction = UIAlertAction(
            title: "Set Price Alert",
            style: .Default,
            handler: { (alert: UIAlertAction) in
                //Check textfield input to make sure it actually has a value
                if priceTargetTextField?.text != "" {
                    priceTargetTextField?.resignFirstResponder()
                    if let value = Double((priceTargetTextField?.text)!) {
                        if stock.price > value {
                            //The user wants to set an alert lower than the current price
                            stock.lowPriceAlert = value.roundToPlaces(2)
                        } else {
                            //The user wants to set an alert higher than or equal to the current price
                            stock.highPriceAlert = value.roundToPlaces(2)
                        }
                        self.tableView.reloadData()
                    }
                }
        })
        
        //This option will allow the user to select a low price alert
        let cancelAction = UIAlertAction(title: "Cancel", style: .Destructive, handler: { (alert: UIAlertAction) in
            priceTargetTextField?.resignFirstResponder()
            self.dismissViewControllerAnimated(true, completion: nil)
        })
        
        //Add textfield to allow the user to enter a price target
        alert.addTextFieldWithConfigurationHandler({ (textField) -> Void in
            priceTargetTextField = textField
            priceTargetTextField?.placeholder = "Enter a price target"
            priceTargetTextField?.keyboardType = .DecimalPad
        })
        
        //Add the actions to the alert
        alert.addAction(cancelAction)
        alert.addAction(alertAction)
        
        //Present the alert
        presentViewController(alert, animated: true, completion: nil)
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


//MARK: - TickrCell Class
//A simple UITableView cell for displaying stock data
class TickrCell: UITableViewCell {
    
    //MARK: - Cell Outlets
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var percentageButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var lowPriceAlertLabel: UILabel!
    @IBOutlet weak var highPriceAlertLabel: UILabel!
    
    
    /*
        Will configure a TickrCell and populate outlets with stock data
     
        - parameter stock: A Stock object this cell is to display
    */
    func configureCellWithStock(stock: Stock) {
        //Create number formatter so that all Doubles are fomatted as currency
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .CurrencyStyle
        
        //Set price, symbol, and name label as well as the percentage button
        let price = formatter.stringFromNumber(stock.price)
        let change = formatter.stringFromNumber(stock.netChange)
        priceLabel.text = price
        symbolLabel.text = "\(stock.symbol.uppercaseString)"
        nameLabel.text = "\(stock.name)"
        percentageButton.setTitle("\(change!) (\(stock.netChangeInPercentage.roundToPlaces(2))%)", forState: .Normal)
        
        //Check for any price alerts that need to be displayed
        //High Alert
        if let highAlert = stock.highPriceAlert {
            let hAlert = formatter.stringFromNumber(highAlert)
            highPriceAlertLabel.text = "Price Alert: \(hAlert!)"
            highPriceAlertLabel.hidden = false
        }else {
            highPriceAlertLabel.hidden = true
        }
        
        //Low Alert
        if let lowAlert = stock.lowPriceAlert {
            let lAlert = formatter.stringFromNumber(lowAlert)
            lowPriceAlertLabel.text = "Price Alert: \(lAlert!)"
            lowPriceAlertLabel.hidden = false
        }else {
            lowPriceAlertLabel.hidden = true
        }
        
        //Set the cell color to match it's stock's performance
        switch stock.netChange {
            case let x where x < 0.0:
                self.contentView.backgroundColor = Constants.tickrRed //loss in value
            case let x where x > 0.0:
                self.contentView.backgroundColor = Constants.tickrGreen //gain in value
            default:
                self.contentView.backgroundColor = Constants.tickrGray //no price action
        }
        
        //Setup the labels to make them more legible
        symbolLabel.textColor = Constants.tickrFontColor
        symbolLabel.font = Constants.tickrFont
        symbolLabel.shadowColor = Constants.tickrLabelShadowColor
        symbolLabel.shadowOffset = Constants.tickrLabelShadowOffset
        
        //Setup the percentage button
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
