//
//  Assertions.swift
//  AppTests
//
//  Created by Rémi Bardon on 12/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import XCTVapor

extension XCTHTTPResponse {
	
	func assertStatus(
		_ status: HTTPResponseStatus,
		handler: () throws -> Void
	) throws {
		// Test HTTP status
		XCTAssertEqual(self.status, status)
		
		if self.status == status {
			// Test data
			try handler()
		} else if self.status != .ok {
			// Log error
			let error = try self.content.decode(ResponseError.self)
			XCTFail("\(self.status.code) \(self.status.reasonPhrase): '\(error.reason)'")
		}
	}
	
	func assertError(status: HTTPResponseStatus, reason: String) throws {
		try assertStatus(status) {
			let error = try self.content.decode(ResponseError.self)
			XCTAssertEqual(error.reason, reason)
		}
	}
	
}
