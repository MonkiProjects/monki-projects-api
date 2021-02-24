//
//  AppTestCase.swift
//  AppTests
//
//  Created by Rémi Bardon on 12/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

@testable import App
import XCTVapor
import FluentSQLiteDriver

internal class AppTestCase: XCTestCase {
	
	// swiftlint:disable:next test_case_accessibility
	static var app: Application?
	
	/// Starts the app in testing mode and deletes everything in database.
	override class func setUp() {
		super.setUp()
		
		do {
			let app = Application(.testing)
			
			// Register database
			app.databases.use(.sqlite(.memory), as: .sqlite)
			
			// Configure queues
			try app.queues.use(.redis(url: Environment.get("REDIS_URL") ?? "redis://127.0.0.1:6379"))
			
			// Start jobs
//			Jobs.addAll(to: app)
//			try app.queues.startInProcessJobs(on: .default)
//			try app.queues.startInProcessJobs(on: .placemarks)
			
			try configure(app)
			self.app = app
		} catch {
			XCTFail(error.localizedDescription)
		}
	}
	
	/// Deletes everything in database and stops the app.
	override class func tearDown() {
		do {
			let app = try XCTUnwrap(self.app)
			app.databases.reinitialize()
			app.shutdown()
		} catch {
			XCTFail(error.localizedDescription)
		}
		
		super.tearDown()
	}
	
}
