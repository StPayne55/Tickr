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
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        searchBar.becomeFirstResponder()
    }

    /*
        Will take a search term and query a separate API for possible stocks
        that match that search term.
     
        - parameter searchText: The user input used for finding stocks
    */
    func searchYahooFinanceWithString(searchText: String) {
        
        //Search for stocks using the user-entered text
        StockManager.fetchStocksFromSearchTerm(term: searchText) { (stockInfoArray) -> () in
            dispatch_async(dispatch_get_main_queue(), {
                //Update the tableView with the search results
                self.searchResults = stockInfoArray
                self.tableView.reloadData()
            })
        }
    }
}

//MARK: - TableView Delegate and Datasource
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


//MARK: - SearchBar Delegate
extension SearchTableViewController: UISearchBarDelegate {
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        //If there is user input, suggest companies that match their query
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
    
    //dismiss search VC when cancel button is selected
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.text = ""
        self.dismissViewControllerAnimated(false, completion: nil)
    }
}


//MARK: - SearchResultCell Class
//A simple UITableViewCell for displaying search results
class SearchResultCell: UITableViewCell {
    //Class Variables
    var parentVC: SearchTableViewController!
    
    //Outlets
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    //Actions
    @IBAction func addButtonWasPressed(sender: UIButton?) {
        //create a new stock instance
        let newStock = Stock(
            name: nameLabel.text!,
            symbol: symbolLabel.text!,
            price: 0.0,
            netChange: 0.0,
            netChangeInPercentage: 0.0
        )
        
        //Try to add this stock to the watchlist.
        WatchListManager.sharedInstance.addStockToWatchList(newStock, completion: { (stockWasAdded: Bool) in
            //Dismiss the search view controller
            self.parentVC.dismissViewControllerAnimated(false, completion: nil)
        })
    }
    
    //Configure SearchResult cell with symbol and name
    func configureCellWithSearchResult(term: StockSearchResult) {
        symbolLabel.text = term.symbol
        nameLabel.text = term.name
    }
}
