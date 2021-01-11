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
import FluentSQLiteDriver

final class CurrentUserControllerTests: XCTestCase {
	
	private static var app: Application?
	private static let userId = UUID()
	private static let password = "password"
	private static var user: User?
	private static var userToken: User.Token?
	
	override class func setUp() {
		super.setUp()
		
		do {
			let app = Application(.testing)
			app.databases.use(.sqlite(.memory), as: .sqlite)
			try configure(app)
			self.app = app
			
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
				// Test HTTP status
				XCTAssertEqual(res.status, .ok)
				
				if res.status == .ok {
					// Test user value in token
					do {
						let token = try res.content.decode(User.Token.self)
						XCTAssertEqual(token.$user.id, Self.userId)
					} catch {
						XCTFail(error.localizedDescription)
					}
				} else {
					// Log error
					let error = try res.content.decode(ResponseError.self)
					XCTFail(error.reason)
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
				// Test HTTP status
				XCTAssertEqual(res.status, .unauthorized)
				
				if res.status == .unauthorized {
					// Test data
					let error = try res.content.decode(ResponseError.self)
					XCTAssertEqual(error.reason, "Unauthorized")
				} else if res.status != .ok {
					// Log error
					let error = try res.content.decode(ResponseError.self)
					XCTFail(error.reason)
				}
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
				// Test HTTP status
				XCTAssertEqual(res.status, .unauthorized)
				
				if res.status == .unauthorized {
					// Test data
					let error = try res.content.decode(ResponseError.self)
					XCTAssertEqual(error.reason, "Unauthorized")
				} else if res.status != .ok {
					// Log error
					let error = try res.content.decode(ResponseError.self)
					XCTFail(error.reason)
				}
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
				// Test HTTP status
				XCTAssertEqual(res.status, .unauthorized)
				
				if res.status == .unauthorized {
					// Test data
					let error = try res.content.decode(ResponseError.self)
					XCTAssertEqual(error.reason, "Unauthorized")
				} else if res.status != .ok {
					// Log error
					let error = try res.content.decode(ResponseError.self)
					XCTFail(error.reason)
				}
			}
		)
	}
	
}
