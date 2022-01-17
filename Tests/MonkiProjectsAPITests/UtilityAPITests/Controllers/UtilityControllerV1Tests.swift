//
//  UtilityControllerV1Tests.swift
//  UtilityAPITests
//
//  Created by Rémi Bardon on 13/01/2022.
//  Copyright © 2022 Monki Projects. All rights reserved.
//

@testable import MonkiProjectsAPI
import XCTVapor
import Fluent
import MonkiMapModel
import Foundation

internal class UtilityControllerV1Tests: AppTestCase {
	
	// MARK: - Valid Domain
	
	func testValidURLs() throws {
		let app = try XCTUnwrap(Self.app)
		
		// swiftlint:disable number_separator
		let examples = [
			"https://www.google.com/maps/place/Aire+de+jeux/data=!4m2!3m1!1s0x4805eb8482e2d99f:0xc9203dd8e3d45de2": (47.1881032, -1.5604043),
			"https://www.google.com/maps/place/Square+des+Lavandi%C3%A8res/data=!4m2!3m1!1s0x4805ec21eb7cebf5:0x661bb185a6404543": (47.2240983, -1.5649092),
			"https://www.google.com/maps/place/Centre-Ville/data=!4m2!3m1!1s0x4805eea2c2d13eb3:0xd7440dabd03af64c": (47.2214657, -1.551224),
			"https://www.google.com/maps/search/47.1840384,-1.5613742": (47.1840384, -1.5613742),
			"https://www.google.com/maps/search/45.8338724,6.1663486": (45.8338724, 6.1663486),
		]
		// swiftlint:enable number_separator
		for (urlString, expected) in examples {
			try app.test(
				.GET, "utility/v1/coordinates-from-google-maps-url",
				beforeRequest: { req in
					try req.query.encode([
						"url": urlString,
					])
				},
				afterResponse: { res in
					try res.assertStatus(.ok) {
						let content = try res.content.decode(Coordinate?.self)
						let coordinate = try XCTUnwrap(content)
						
						XCTAssertEqual(coordinate, Coordinate(latitude: expected.0, longitude: expected.1), urlString)
					}
				}
			)
		}
	}
	
	func testCoordinatesRegexIsValid() throws {
		let app = try XCTUnwrap(Self.app)
		
		let utilityService = UtilityService(
			db: app.db,
			app: app,
			eventLoop: app.eventLoopGroup.next(),
			logger: app.logger
		)
		XCTAssertNoThrow(try utilityService.coordinatesRegex())
	}
	
	// MARK: - Invalid Domain
	
	func testNonEncodedUrlThrowsError() throws {
		let app = try XCTUnwrap(Self.app)
		
		let urlString = "https://www.google.com/maps/place/Aire+de+jeux/data=!4m2!3m1!1s0x4805eb8482e2d99f:0xc9203dd8e3d45de2"
		try app.test(.GET, "utility/v1/coordinates-from-google-maps-url?url=\(urlString)") { res in
			try res.assertError(
				status: .badRequest,
				reason: "The given URL is invalid. Make sure it's correctly URL-encoded."
			)
		}
	}
	
	func testBadUrlReturnsNoContent() throws {
		let app = try XCTUnwrap(Self.app)
		
		let urlString = "https://github.com/MonkiProjects"
		try app.test(.GET, "utility/v1/coordinates-from-google-maps-url?url=\(urlString)") { res in
			try res.assertStatus(.noContent) {
				XCTAssertNil(res.content.contentType)
			}
		}
	}
	
	func testInvalidUrlReturnsNoContent() throws {
		let app = try XCTUnwrap(Self.app)
		
		let urlString = "https://monkiprojects.com/this-url-does-not-exist"
		try app.test(.GET, "utility/v1/coordinates-from-google-maps-url?url=\(urlString)") { res in
			try res.assertStatus(.noContent) {
				XCTAssertNil(res.content.contentType)
			}
		}
	}
	
}
