//
//  AuthControllerTests.swift
//  AppTests
//
//  Created by Rémi Bardon on 23/06/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

@testable import App
import XCTVapor
import Fluent

final class CurrentUserControllerTests: AppTestCase {
	
	private static let userId = UUID()
	private static let password = "password"
	private static var user: User?
	private static var userToken: User.Token?
	
	override class func setUp() {
		super.setUp()
		
		do {
			let app = try XCTUnwrap(self.app)
			
			// Create user
			let user = User(
				id: userId,
				username: "test_username",
				email: "test@email.com",
				passwordHash: try Bcrypt.hash(password)
			)
			try user.create(on: app.db).wait()
			self.user = user
			
			// Create user token
			let userToken = try user.generateToken()
			try userToken.save(on: app.db).wait()
			self.userToken = userToken
		} catch {
			XCTFail(error.localizedDescription)
		}
	}
	
	// MARK: - Valid Domain
	
	func testLogin() throws {
		let app = try XCTUnwrap(Self.app)
		let expectedUser = try XCTUnwrap(Self.user)
		
		try app.test(.POST, "v1/auth/login",
			beforeRequest: { req in
				let basicAuth = BasicAuthorization(username: expectedUser.username, password: Self.password)
				req.headers.basicAuthorization = basicAuth
			},
			afterResponse: { res in
				try res.assertStatus(.ok) {
					// Test user value in token
					do {
						let token = try res.content.decode(User.Token.self)
						XCTAssertEqual(token.$user.id, Self.userId)
					} catch {
						XCTFail(error.localizedDescription)
					}
				}
			}
		)
	}
	
	// MARK: - Invalid Domain
	
	func testLoginInvalidPassword() throws {
		let app = try XCTUnwrap(Self.app)
		let user = try XCTUnwrap(Self.user)
		
		try app.test(.POST, "v1/auth/login",
			beforeRequest: { req in
				let basicAuth = BasicAuthorization(username: user.username, password: "invalid_password")
				req.headers.basicAuthorization = basicAuth
			},
			afterResponse: { res in
				try res.assertError(status: .unauthorized, reason: "Unauthorized")
			}
		)
	}
	
	func testLoginInvalidUsername() throws {
		let app = try XCTUnwrap(Self.app)
		
		try app.test(.POST, "v1/auth/login",
			beforeRequest: { req in
				let basicAuth = BasicAuthorization(username: "invalid_username", password: Self.password)
				req.headers.basicAuthorization = basicAuth
			},
			afterResponse: { res in
				try res.assertError(status: .unauthorized, reason: "Unauthorized")
			}
		)
	}
	
	func testLoginWithToken() throws {
		let app = try XCTUnwrap(Self.app)
		let userToken = try XCTUnwrap(Self.userToken)
		
		try app.test(.POST, "v1/auth/login",
			beforeRequest: { req in
				let bearerAuth = BearerAuthorization(token: userToken.value)
				req.headers.bearerAuthorization = bearerAuth
			},
			afterResponse: { res in
				try res.assertError(status: .unauthorized, reason: "Unauthorized")
			}
		)
	}
	
}
