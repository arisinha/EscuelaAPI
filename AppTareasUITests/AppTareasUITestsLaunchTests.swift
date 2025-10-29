//
//  AppTareasUITestsLaunchTests.swift
//  AppTareasUITests
//
//  Created by Nelson Ivan Reyes Segoviano on 02/10/25.
//

import Testing
import XCTest // Still needed for XCUIApplication and XCTAttachment

@Suite(.serialized)
struct AppTareasUITestsLaunchTests {

    @MainActor
    @Test func launch() async throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        // Note: Swift Testing doesn't have direct attachment support like XCTest
        // Screenshots can still be captured but won't automatically appear in test results
        let screenshot = app.screenshot()
        #expect(app.state == .runningForeground, "App should be running in foreground after launch")
    }
}
