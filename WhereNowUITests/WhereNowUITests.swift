//
//  WhereNowUITests.swift
//  WhereNowUITests
//
//  Created by Jon on 7/17/24.
//

import XCTest
import Foundation

final class WhereNowUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testApp() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testTabs() throws {
                
        let app = XCUIApplication()
        let tabBar = app.tabBars["Tab Bar"]
        tabBar.buttons["Hear Now!"].tap()
        tabBar.buttons["Weather Now!"].tap()
        tabBar.buttons["Game Now!"].tap()
        
        let purplebirdImage = app/*@START_MENU_TOKEN@*/.images["PurpleBird"]/*[[".otherElements[\"Tab View\"].images[\"PurpleBird\"]",".images[\"PurpleBird\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        purplebirdImage.tap()
        
        /*let whereNowStaticText = app.staticTexts["WHERE NOW!"]
        whereNowStaticText.tap()*/
        
        tabBar/*@START_MENU_TOKEN@*/.buttons["bird"]/*[[".buttons[\"Hear Now!\"]",".buttons[\"bird\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
