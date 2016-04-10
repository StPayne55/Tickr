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
    
        manager.notififyListenersOfUpdates(manager.stockArray)
        XCTAssertEqual(mockNotification.postCount, 1, "A notification should have been posted")
    }
    
}


//MARK: - StocksTableViewControllerTests
class StocksTableViewControllerTests: XCTestCase {
    var stockVC: StocksTableViewController!
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
        stockVC.viewDidLoad()
        
        XCTAssertEqual(mockNotification.observerCount, 1, "VC should be an observer for stock update notifications")
    }
    
    func testFetchStockUpdates() {
        stockVC.stocks.append(TickrTestData.stocks[0])
        stockVC.fetchStockUpdates()
        
        XCTAssertNotNil(stockVC.stockManager.session.configuration, "Config should've been set at this point")
        
        //Defined in Constants.swift but we still want to make sure this is never less than 2
        XCTAssert(Constants.kUpdateInterval >= 2, "Update interval shouldn't be less than 5 for performance reasons")
    }
    
    func testStocksWereUpdated() {
        //This should trigger the 'stocksWereUpdated' function and
        //inject our test data
        stockVC.notificationCenter = mockNotification
        let payload = [Constants.kNotificationStockPricesUpdated : TickrTestData.stocks]
        let fakeNotification = NSNotification(name: Constants.kNotificationStockPricesUpdated, object: nil, userInfo: payload)
        stockVC.stocksWereUpdated(fakeNotification)
        
        //This function should've parsed the notification userInfo dict
        //and added all of the testData stocks to it's stock array
        XCTAssertEqual(stockVC.stocks.count, TickrTestData.stocks.count, "Expected the same number of stocks in both the test array, and parsed array")
    }
    
    //Mark: - Tableview Tests
    func testNumberOfRowsInTableView() {
        stockVC.stocks = TickrTestData.stocks
        stockVC.tableView.reloadData()
        
        XCTAssertEqual(stockVC.tableView.numberOfRowsInSection(0), TickrTestData.stocks.count, "Expected 3 rows")
    }
    
    func testCellForRowAtIndexPath() {
        stockVC.stocks = TickrTestData.stocks
        stockVC.tableView.reloadData()
        let cell = stockVC.tableView(stockVC.tableView, cellForRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 0)) as! TickrCell
        
        
        XCTAssertNotNil(cell.parentVC, "Expected cell to have parentVC")
    }
    
    func testDidSelectRow() {
        stockVC.stocks = TickrTestData.stocks
        stockVC.tableView.reloadData()
        stockVC.tableView.selectRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), animated: false, scrollPosition: UITableViewScrollPosition.None)
        
        //TODO: - Add assertions once feature is added
    }
    
    
    //MARK: - TickrCell Tests
    func testConfigureCell() {
        stockVC.stocks = TickrTestData.stocks
        stockVC.tableView.reloadData()
        let cells = stockVC.tableView.visibleCells as! [TickrCell]
        
        var i = 0
        for cell in cells {
            cell.configureCellWithStock(TickrTestData.stocks[i])
            i += 1
        }
        
        //check to make sure cells are the right color
        //stock 1 has a positive price action
        //stock 2 has a negative price action
        //stock 3 has no change in price action
        XCTAssertEqual(cells[0].contentView.backgroundColor, Constants.tickrGreen, "Cell should be green")
        XCTAssertEqual(cells[1].contentView.backgroundColor, Constants.tickrRed, "Cell should be red")
        XCTAssertEqual(cells[2].contentView.backgroundColor, Constants.tickrGray, "Cell should be gray")
        
        //check to make sure all labels are set
        XCTAssertNotNil(cells[0].priceLabel.text, "Expected a price")
        XCTAssertNotNil(cells[0].symbolLabel.text, "Expected a symbol")
        XCTAssertNotNil(cells[0].nameLabel.text, "Expected a name")
        XCTAssertNotNil(cells[0].percentageButton.titleLabel?.text, "Expected a percentage")
        XCTAssertNotNil(cells[1].priceLabel.text, "Expected a price")
        XCTAssertNotNil(cells[1].symbolLabel.text, "Expected a symbol")
        XCTAssertNotNil(cells[1].nameLabel.text, "Expected a name")
        XCTAssertNotNil(cells[1].percentageButton.titleLabel?.text, "Expected a percentage")
        XCTAssertNotNil(cells[2].priceLabel.text, "Expected a price")
        XCTAssertNotNil(cells[2].symbolLabel.text, "Expected a symbol")
        XCTAssertNotNil(cells[2].nameLabel.text, "Expected a name")
        XCTAssertNotNil(cells[2].percentageButton.titleLabel?.text, "Expected a percentage")
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


