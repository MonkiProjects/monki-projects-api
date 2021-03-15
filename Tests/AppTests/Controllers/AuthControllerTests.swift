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
import Models

internal final class CurrentUserControllerTests: AppTestCase {
	
	private static let userId = UUID()
	private static let password = "password"
	private static var user: UserModel?
	private static var userToken: UserModel.Token?
	
	override class func setUp() {
		super.setUp()
		
		do {
			let app = try XCTUnwrap(self.app)
			
			// Create user
			let user = UserModel.dummy(id: userId, passwordHash: try Bcrypt.hash(password))
			try user.create(on: app.db).wait()
			self.user = user
			
			// Create user token
			let userToken = try user.generateToken()
			try userToken.create(on: app.db).wait()
			self.userToken = userToken
		} catch {
			XCTFail(error.localizedDescription)
		}
	}
	
	// MARK: - Valid Domain
	
	func testLogin() throws {
		let app = try XCTUnwrap(Self.app)
		let expectedUser = try XCTUnwrap(Self.user)
		
		try app.test(
			.POST, "auth/v1/login",
			beforeRequest: { req in
				let basicAuth = BasicAuthorization(username: expectedUser.username, password: Self.password)
				req.headers.basicAuthorization = basicAuth
			},
			afterResponse: { res in
				try res.assertStatus(.ok) {
					// Test user value in token
					do {
						let token = try res.content.decode(UserModel.Token.self)
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
		
		try app.test(
			.POST, "auth/v1/login",
			beforeRequest: { req in
				let basicAuth = BasicAuthorization(username: user.username, password: "invalid_password")
				req.headers.basicAuthorization = basicAuth
			},
			afterResponse: { res in
				try res.assertError(
					status: .unauthorized,
					reason: "Invalid credentials for '\(user.username)'."
				)
			}
		)
	}
	
	func testLoginInvalidUsername() throws {
		let app = try XCTUnwrap(Self.app)
		
		try app.test(
			.POST, "auth/v1/login",
			beforeRequest: { req in
				let basicAuth = BasicAuthorization(username: "invalid_username", password: Self.password)
				req.headers.basicAuthorization = basicAuth
			},
			afterResponse: { res in
				try res.assertError(
					status: .unauthorized,
					reason: "Invalid credentials for 'invalid_username'."
				)
			}
		)
	}
	
	func testLoginWithToken() throws {
		let app = try XCTUnwrap(Self.app)
		let userToken = try XCTUnwrap(Self.userToken)
		
		try app.test(
			.POST, "auth/v1/login",
			beforeRequest: { req in
				let bearerAuth = BearerAuthorization(token: userToken.value)
				req.headers.bearerAuthorization = bearerAuth
			},
			afterResponse: { res in
				try res.assertError(status: .unauthorized, reason: "Basic authorization required.")
			}
		)
	}
	
}
