//
//  AppTests.swift
//  MonkiProjectsAPITests
//
//  Created by Rémi Bardon on 07/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

@testable import App
import XCTVapor
import FluentSQLiteDriver

internal final class AppTests: XCTestCase {
	
	func testRedirectToDoc() throws {
		let app = Application(.testing)
		defer { app.shutdown() }
		app.databases.use(.sqlite(.memory), as: .sqlite)
		try configure(app)
		
		try app.test(.GET, "/") { res in
			XCTAssertEqual(res.status, .seeOther)
		}
	}
	
}
