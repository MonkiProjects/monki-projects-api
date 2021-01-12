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

class AppTestCase: XCTestCase {
	
	static var app: Application?
	
	/// Starts the app in testing mode and deletes everything in database.
	override class func setUp() {
		super.setUp()
		
		do {
			let app = Application(.testing)
			app.databases.use(.sqlite(.memory), as: .sqlite)
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
