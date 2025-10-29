//
//  AppTareasUITests.swift
//  AppTareasUITests
//
//  Created by Nelson Ivan Reyes Segoviano on 02/10/25.
//

import XCTest

final class AppTareasUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

//
//  AppTareasUITests.swift
//  AppTareasUITests
//
//  Created by Nelson Ivan Reyes Segoviano on 02/10/25.
//

import Testing
import XCTest // Still needed for XCUIApplication

@Suite(.serialized)
struct AppTareasUITests {

    @MainActor
    @Test func example() async throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use #expect(...) to verify your tests produce the correct results.
    }

    @MainActor
    @Test func launchPerformance() async throws {
        // This measures how long it takes to launch your application.
        // Note: Swift Testing doesn't have built-in performance measurement like XCTest's measure()
        // For now, we'll just verify the app launches successfully
        let app = XCUIApplication()
        app.launch()
        #expect(app.state == .runningForeground)
    }
}
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
