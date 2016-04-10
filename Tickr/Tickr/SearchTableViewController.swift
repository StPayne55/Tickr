//
//  SearchTableViewController.swift
//  Tickr
//
//  Created by Stephen Payne on 4/10/16.
//  Copyright © 2016 Stephen Payne. All rights reserved.
//

import UIKit

class SearchTableViewController: UIViewController {
    //Class Variables
    var searchResults: [StockSearchResult] = []
    
    //Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    //MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        searchBar.becomeFirstResponder()
    }

    func searchYahooFinanceWithString(searchText: String) {
        
        StockManager.fetchStocksFromSearchTerm(term: searchText) { (stockInfoArray) -> () in
            dispatch_async(dispatch_get_main_queue(), {
                self.searchResults = stockInfoArray
                self.tableView.reloadData()
            })
        }
    }
}

extension SearchTableViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("searchResultCell") as! SearchResultCell
        
        cell.parentVC = self
        cell.configureCellWithSearchResult(searchResults[indexPath.row])
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! SearchResultCell
        cell.addButtonWasPressed(nil)
    }
}

extension SearchTableViewController: UISearchBarDelegate {
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        let length = searchText.characters.count
        
        if length > 0 {
            searchYahooFinanceWithString(searchText)
        } else {
            searchResults.removeAll()
            tableView.reloadData()
        }
    }
    
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = true
        tableView.reloadData()
        return true
    }
    
    func searchBarShouldEndEditing(searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = false
        tableView.reloadData()
        return true
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.text = ""
        self.dismissViewControllerAnimated(false, completion: nil)
    }
}


//A simple UITableView cell to display search results
class SearchResultCell: UITableViewCell {
    //Instance Variables
    var parentVC: SearchTableViewController!
    
    //Outlets
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    //Actions
    @IBAction func addButtonWasPressed(sender: UIButton?) {
        let newStock = Stock(name: nameLabel.text!, symbol: symbolLabel.text!, price: 0.0, netChange: 0.0, netChangeInPercentage: 0.0)
        WatchListManager.sharedInstance.stocks.append(newStock)
        parentVC.dismissViewControllerAnimated(false, completion: nil)
    }
    
    func configureCellWithSearchResult(term: StockSearchResult) {
        symbolLabel.text = term.symbol
        nameLabel.text = term.name
    }
    
}
