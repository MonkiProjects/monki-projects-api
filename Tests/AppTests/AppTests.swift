//
//  UserController.swift
//  AppTests
//
//  Created by Rémi Bardon on 07/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

@testable import App
import XCTVapor

final class AppTests: XCTestCase {
	func testHelloWorld() throws {
		let app = Application(.testing)
		defer { app.shutdown() }
		try configure(app)
		
		try app.test(.GET, "hello", afterResponse: { res in
			XCTAssertEqual(res.status, .ok)
			XCTAssertEqual(res.body.string, "Hello, world!")
		})
	}
}
