//
//  ViewController.swift
//  Tickr
//
//  Created by Stephen Payne on 4/8/16.
//  Copyright © 2016 Stephen Payne. All rights reserved.
//

import UIKit

class StocksTableViewController: UIViewController {
    private let stocks: [(String, Double)] = [("AAPL", +1.5), ("GOOG", +2.33), ("UTWI", +3.3)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


// MARK: - TableView Delegate and Datasource
extension StocksTableViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stocks.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //A UITableViewCell with style of Value 1 yields a cell with both a left and right label
        let cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "cellID")
        
        //set the labels' text property to the stock ticker and the percentage gained/lost
        cell.textLabel?.text = stocks[indexPath.row].0
        cell.detailTextLabel?.text = "\(stocks[indexPath.row].1)%"
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("Cell tapped")
    }
}
