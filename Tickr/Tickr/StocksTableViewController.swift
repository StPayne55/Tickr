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
//    private var stocks: [(String, Double)] = [("AAPL", -1.5), ("GOOG", -2.0)]
    private var stocks = [Stock]()
    
    //Outlets
    @IBOutlet weak var tableView: UITableView!
    
    
    //MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //fake data
        let symbol = "UWTI"
        let price = 180.00
        let change = 5.4
        let changeInPrice = 10.0
        let newStock = Stock(name: "Google", symbol: symbol, price: price, netChange: change, netChangeInPercentage: changeInPrice)
        stocks.append(newStock)
        let symbol2 = "GOOG"
        let price2 = 180.00
        let change2 = 5.4
        let changeInPrice2 = 10.0
        let newStock2 = Stock(name: "Google", symbol: symbol2, price: price2, netChange: change2, netChangeInPercentage: changeInPrice2)
        stocks.append(newStock2)

        
        //Listen for any updates from the Stock Manager
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(StocksTableViewController.stocksWereUpdated(_:)), name: Constants.kNotificationStockPricesUpdated, object: nil)
        self.fetchStockUpdates()
    }


    //MARK: - Stock Updates
    /*
        This will fetch current stock prices on a set interval.
        This interval can be changed in Constants.swift
     */
    func fetchStockUpdates() {
        let stockManager = StockManager.sharedInstance
        stockManager.fetchListOfSymbols(stocks)
        
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
        //A UITableViewCell with style of Value 1 yields a cell with both a left and right label
//        let cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "tickrCell") as TickrCell
        let cell = tableView.dequeueReusableCellWithIdentifier("tickrCell", forIndexPath: indexPath) as! TickrCell
        cell.parentVC = self
        cell.configureCellWithStock(stocks[indexPath.row])
        

        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
}


//A simple UITableView cell to display stock data
class TickrCell: UITableViewCell {
    //MARK: - Cell Outlets
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var percentageButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    var parentVC: StocksTableViewController!
    
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
        

        //cell.detailTextLabel?.text = "\(stocks[indexPath.row].1)%"
    }
}
