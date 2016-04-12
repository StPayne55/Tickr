//
//  TickrTests.swift
//  TickrTests
//
//  Created by Stephen Payne on 4/8/16.
//  Copyright © 2016 Stephen Payne. All rights reserved.
//

import XCTest

@testable import Tickr

class TickrTests: XCTestCase {
    let testData = TickrTestData()
    
    override func setUp() {
        super.setUp()
        //create test data for all tests to use
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
}

class StockManagerTests: TickrTests {
    var stocks = [Stock]()
    var manager = StockManager.sharedInstance
    
    //MARK: - Parsing Tests
    func testParseJSON() {
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(
                TickrTestData.singleResultData!,
                options:NSJSONReadingOptions.MutableContainers
                ) as! NSDictionary
            
            let stockArrayWithData = manager.parseJSON(json)
            XCTAssertNotNil(stockArrayWithData, "Data couldn't be parsed. Check the data file to make sure the JSON structure hasn't changed")
            
        } catch {
            //the test json files have been moved or deleted
            XCTFail("The expected data files have been moved or deleted")
        }
    }
    
    func testParseJSONWithDifferentKeys() {
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(
                TickrTestData.badResultData!,
                options:NSJSONReadingOptions.MutableContainers
                ) as! NSDictionary
            
            let stockArrayWithData = manager.parseJSON(json)
            XCTAssertNil(stockArrayWithData, "The parsing should've failed" )
        } catch {
            //the test json files have been moved or deleted
            XCTFail("The expected data files have been moved or deleted")
        }
    }
    
    func testParseStockDataWithSingleResult() {

        do {
            let json = try NSJSONSerialization.JSONObjectWithData(
                TickrTestData.singleResultData!,
                options:NSJSONReadingOptions.MutableContainers
            ) as! NSDictionary
            
            if let stockArrayWithData = manager.parseJSON(json) {
                manager.parseStockData(stockArrayWithData)
                XCTAssertEqual(manager.stockArray.count, 1, "There should be 1 stock in the array ")
                
            } else {
                XCTFail("The data couldn't be parsed. Check the data file to make sure the JSON structure hasn't been changed")
            }
            
        } catch {
            //the test json files have been moved or deleted
            XCTFail("The expected data files have been moved or deleted")
        }
    }
    
    func testParseStockDataWithMultipleResults() {
        
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(
                TickrTestData.doubleResultData!,
                options:NSJSONReadingOptions.MutableContainers
                ) as! NSDictionary
            
            if let stockArrayWithData = manager.parseJSON(json) {
                manager.parseStockData(stockArrayWithData)
                XCTAssertEqual(manager.stockArray.count, 2, "There should be 2 stocks in the array ")
                
            } else {
                XCTFail("The data couldn't be parsed. Check the data file to make sure the JSON structure hasn't been changed")
            }
            
        } catch {
            //the test json files have been moved or deleted
            XCTFail("The expected data files have been moved or deleted")
        }
    }
    
    
    //MARK: - Notifications
    func notificationWasReceived() {
        let mockNotification = MockNSNotificationCenter()
        manager.notificationCenter = mockNotification
    
        manager.notififyListenersOfUpdates()
        XCTAssertEqual(mockNotification.postCount, 1, "A notification should have been posted")
    }
    
}


//MARK: - StocksTableViewControllerTests
class StocksTableViewControllerTests: XCTestCase {
    var stockVC = StocksTableViewController()
    let mockNotification = MockNSNotificationCenter()

    override func setUp() {
        let storyboard = UIStoryboard(
            name: "Main",
            bundle: NSBundle.mainBundle()
        )
        stockVC = storyboard.instantiateViewControllerWithIdentifier("stockTableViewController") as! StocksTableViewController
        UIApplication.sharedApplication().keyWindow!.rootViewController = stockVC
       let _ = stockVC.view
    }
    
    func testViewDidLoad() {
        stockVC.notificationCenter = mockNotification
        stockVC.viewWillAppear(false)
        
        XCTAssertEqual(mockNotification.observerCount, 2, "VC should be an observer 2 notifications")
    }
    
    func testFetchStockUpdates() {
        stockVC.fetchStockUpdates()
        
        XCTAssertNotNil(StockManager.sharedInstance.session.configuration, "Config should've been set at this point")
        
        //Defined in Constants.swift but we still want to make sure this is never less than 2
        XCTAssert(Constants.kUpdateInterval >= 2, "Update interval shouldn't be less than 2 for performance reasons")
    }
    
    func testStocksWereUpdated() {
        //This simply updates the tableView
        let payload = [Constants.kNotificationStockPricesUpdated : TickrTestData.stocks]
        let fakeNotification = NSNotification(name: Constants.kNotificationStockPricesUpdated, object: nil, userInfo: payload)
        stockVC.stocksWereUpdated(fakeNotification)
        
        //No assertions can really be made
    }
    
    //Mark: - Tableview Tests
    func testNumberOfRowsInTableView() {
        let exp = expectationWithDescription("stockAdded")
        let stock = TickrTestData.stocks[0]
        WatchListManager.sharedInstance.addStockToWatchList(stock, completion: { (stockAdded) in
            self.stockVC.tableView.reloadData()
            XCTAssertEqual(self.stockVC.tableView.numberOfRowsInSection(0), 1, "Expected 1 row")
            exp.fulfill()
        })
        self.waitForExpectationsWithTimeout(5.0, handler: { error in
            print(error)
        })
    }
    
    func testCellForRowAtIndexPath() {
        weak var exp = expectationWithDescription("stockAdded")
        let stock = TickrTestData.stocks[0]
        WatchListManager.sharedInstance.addStockToWatchList(stock, completion: { (stockAdded) in
            self.stockVC.tableView.reloadData()
            let cell = self.stockVC.tableView(self.stockVC.tableView, cellForRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 0)) as! TickrCell
            XCTAssertNotNil(cell, "Expected cell to be initialized")
            exp?.fulfill()
            exp = nil
        })
        
        self.waitForExpectationsWithTimeout(5.0, handler: { error in
            print(error)
        })
    }
    
    func testEditActionsForRowAtIndexPath() {
        weak var exp = expectationWithDescription("stockAdded")
        let stock = TickrTestData.stocks[0]
        WatchListManager.sharedInstance.addStockToWatchList(stock, completion: { (stockAdded) in
            let actions = self.stockVC.tableView(self.stockVC.tableView, editActionsForRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 0))
            
            XCTAssertEqual(actions?.count, 2, "There should be a delete and Price Alerts Action")
            XCTAssertEqual(actions?[0].style, .Destructive, "This should be a destructive delete action")
            XCTAssertEqual(actions?[1].style, .Default, "This should be a default price alert action")
            exp?.fulfill()
            exp = nil
        })
        
        self.waitForExpectationsWithTimeout(5.0, handler: { error in
            print(error)
        })
    }
    
    func testDeleteActionHandler() {
        weak var exp = expectationWithDescription("stockAdded")
        let stock = TickrTestData.stocks[0]
        WatchListManager.sharedInstance.addStockToWatchList(stock, completion: { _ in
            let actions = self.stockVC.tableView(self.stockVC.tableView, editActionsForRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 0))
            self.stockVC.deleteRowActionHandler(actions![1], indexPath: NSIndexPath(forRow: 0, inSection: 0))
            
            XCTAssertFalse(StockManager.sharedInstance.shouldCancelUpdate, "Expected this to be false")
            XCTAssertEqual(self.stockVC.tableView.numberOfRowsInSection(0), 0, "The only row should've been deleted")
            exp?.fulfill()
            exp = nil
        })
        
        self.waitForExpectationsWithTimeout(5.0, handler: { error in
            print(error)
        })
    }
    
    func testDisplayActionSheetForAlerts() {
        let stock = TickrTestData.stocks[0]
        stockVC.displayActionSheetForAlerts(stock)
        
        XCTAssertEqual(stockVC.priceAlert?.actions.count, 2, "Expected 2 actions on this alert")
        XCTAssertEqual(stockVC.priceAlert?.actions[0].style, .Destructive, "Expected destructive-style action")
        XCTAssertEqual(stockVC.priceAlert?.actions[1].style, .Default, "Expected default-style action")
        XCTAssertEqual(stockVC.priceAlert?.textFields?.count, 1, "Alert should have a textfield")
    }
    
    //MARK: - SearchBar Delegate Tests
    func testSearchBarShouldBeginEditing() {
        let searchBar = stockVC.searchBar
        let value = stockVC.searchBarShouldBeginEditing(searchBar)
        
        XCTAssertTrue(value, "This should return true always")
    }
    
    
    //MARK: - TickrCell Tests
    func testConfigureCell() {
        let exp = expectationWithDescription("stockWasAdded")
        let stock = TickrTestData.stocks[0]
        
        WatchListManager.sharedInstance.addStockToWatchList(stock, completion: { (stockAdded) in
            self.stockVC.tableView.reloadData()
            let cells = self.stockVC.tableView.visibleCells as! [TickrCell]
            
            var i = 0
            for cell in cells {
                cell.configureCellWithStock(TickrTestData.stocks[i])
                i += 1
            }
            
            //check to make sure cells are the right color
            //stock has a positive price action
            XCTAssertEqual(cells[0].contentView.backgroundColor, UIColor.tickrGreen(), "Cell should be green")

            //check to make sure all labels are set
            XCTAssertNotNil(cells[0].priceLabel.text, "Expected a price")
            XCTAssertNotNil(cells[0].symbolLabel.text, "Expected a symbol")
            XCTAssertNotNil(cells[0].nameLabel.text, "Expected a name")
            XCTAssertNotNil(cells[0].percentageButton.titleLabel?.text, "Expected a percentage")
            exp.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(5.0, handler: { error in
            print(error.debugDescription)
        })
    }
}


//MARK: - Mock Objects For Testing
class MockSession: NSURLSession {
    var completionHandler: ((NSData!, NSURLResponse!, NSError!) -> Void)?
    
    static var mockResponse: (data: NSData?, urlResponse: NSURLResponse?, error: NSError?) = (data: nil, urlResponse: nil, error: nil)
    
    override class func sharedSession() -> NSURLSession {
        return MockSession()
    }
    
    override func dataTaskWithURL(url: NSURL, completionHandler: ((NSData!, NSURLResponse!, NSError!) -> Void)?) -> NSURLSessionDataTask {
        self.completionHandler = completionHandler
        return MockTask(response: MockSession.mockResponse, completionHandler: completionHandler)
    }
    
    class MockTask: NSURLSessionDataTask {
        typealias Response = (data: NSData?, urlResponse: NSURLResponse?, error: NSError?)
        var mockResponse: Response
        let completionHandler: ((NSData!, NSURLResponse!, NSError!) -> Void)?
        
        init(response: Response, completionHandler: ((NSData!, NSURLResponse!, NSError!) -> Void)?) {
            self.mockResponse = response
            self.completionHandler = completionHandler
        }
        override func resume() {
            completionHandler!(mockResponse.data, mockResponse.urlResponse, mockResponse.error)
        }
    }
}

class MockNSNotificationCenter: NSNotificationCenter {
    
    var observerCount = 0
    
    var postCount = 0
    
    var lastPostedNotificationName:String?
    
    override func addObserver(observer: AnyObject, selector aSelector: Selector, name aName: String?, object anObject: AnyObject?) {
        
        observerCount += 1
        
    }
    
    override func postNotificationName(aName: String?, object anObject: AnyObject?) {
        
        lastPostedNotificationName = aName!
        
        postCount += 1
        
    }
    
}


