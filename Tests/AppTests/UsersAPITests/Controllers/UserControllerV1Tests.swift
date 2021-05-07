//
//  UserControllerV1Tests.swift
//  UsersAPITests
//
//  Created by Rémi Bardon on 23/06/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

@testable import App
import XCTVapor
import Fluent
import MonkiProjectsModel

internal class UserControllerV1Tests: AppTestCase {
	
	// MARK: - Valid Domain
	
	/// Tests that the `"users"` schema exists.
	///
	/// - GIVEN:
	///     - The empty database
	/// - WHEN:
	///     - Fetching all users (paginated)
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be an empty paginated array
	///
	/// # Notes: #
	/// 1. Route will trigger a fatalError if the `"users"` schema doesn't exist
	/// 2. If it works properly, then it means that the schema is ready
	func testSchemaExists() throws {
		let app = try XCTUnwrap(Self.app)
		
		try app.test(.GET, "users/v1") { res in
			try res.assertStatus(.ok) {
				let page = try res.content.decode(Fluent.Page<User.Public.Small>.self)
				let users = page.items
				
				XCTAssertEqual(users.count, 0)
				XCTAssertEqual(page.metadata.total, 0)
			}
		}
	}
	
	/// Tests `GET /users`.
	///
	/// - GIVEN:
	///     - A user
	/// - WHEN:
	///     - Fetching all users (paginated)
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be a paginated array containing only the user
	func testIndexReturnsListOfUsers() throws {
		let app = try XCTUnwrap(Self.app)
		
		// Create user
		let user = UserModel.dummy()
		try user.create(on: app.db).wait()
		deleteUserAfterTestFinishes(user, on: app.db)
		
		try app.test(.GET, "users/v1") { res in
			try res.assertStatus(.ok) {
				let page = try res.content.decode(Fluent.Page<User.Public.Small>.self)
				let users = page.items
				
				XCTAssertEqual(users.count, 1)
				XCTAssertEqual(page.metadata.total, 1)
				let userResponse = try XCTUnwrap(users.first)
				
				XCTAssertEqual(userResponse.id, user.id)
			}
		}
	}
	
	/// Tests `POST /users`.
	///
	/// - GIVEN:
	///     - Nothing
	/// - WHEN:
	///     - Creating a user
	/// - THEN:
	///     - `HTTP` status should be `201 Created`
	///     - `body` should be the user's data
	///     - user should be stored on database
	func testPostCreatesUser() throws {
		let app = try XCTUnwrap(Self.app)
		
		// Create user
		let username = "test_username"
		let user = User.Create(
			email: "test@email.com",
			username: username,
			displayName: "Test Name",
			password: "password",
			confirmPassword: "password"
		)
		deletePossiblyCreatedUserAfterTestFinishes(username: username, on: app.db)
		try app.test(
			.POST, "users/v1",
			beforeRequest: { req in
				try req.content.encode(user)
			},
			afterResponse: { res in
				try res.assertStatus(.created) {
					let createdUser = try res.content.decode(User.Private.self)
					
					XCTAssertEqual(createdUser.username, user.username)
					XCTAssertEqual(createdUser.email, user.email)
					
					// Test creation on DB
					let storedUser = try UserModel.find(createdUser.id, on: app.db).wait()
					XCTAssertNotNil(storedUser)
				}
			}
		)
	}
	
	/// Test if `DELETE` actually deletes the user and its tokens.
	///
	/// - GIVEN:
	///     - A user
	/// - WHEN:
	///     - Deleting a user
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be empty
	///     - user tokens should all be deleted from database
	///     - user should be deleted from database
	func testDeleteUser() throws {
		let app = try XCTUnwrap(Self.app)
		
		// Create user
		let userId = UUID()
		let user = UserModel.dummy(id: userId)
		try user.create(on: app.db).wait()
		deleteUserAfterTestFinishes(user, on: app.db)
		
		// Create new token
		let token = try user.generateToken()
		try token.create(on: app.db).wait()
		deleteUserTokenAfterTestFinishes(token, on: app.db)
		
		try app.test(
			.DELETE, "users/v1/\(userId)",
			beforeRequest: { req in
				let bearerAuth = BearerAuthorization(token: token.value)
				req.headers.bearerAuthorization = bearerAuth
			},
			afterResponse: { res in
				try res.assertStatus(.ok) {
					XCTAssertEqual(res.body.string, "")
					
					// Test if user is really deleted
					let userId = try user.requireID()
					let storedUser = try UserModel.find(userId, on: app.db).wait()
					XCTAssertNil(storedUser)
					
					// Test if user tokens are deleted
					let tokens = try UserModel.Token.query(on: app.db)
						.with(\.$user)					// Load user to filter on its `id` field
						.filter(\.$user.$id == userId)	// Filter only the user's tokens
						.all() 							// Get all results
						.wait()
					XCTAssertTrue(tokens.isEmpty)
				}
			}
		)
	}
	
	// MARK: - Invalid Domain
	
	/// Tries to create a user with two different passwords.
	///
	/// - GIVEN:
	///     - Nothing
	/// - WHEN:
	///     - Trying to create a user with two different passwords
	/// - THEN:
	///     - `HTTP` status should be `400 Bad Request`
	///     - `body` should be `"Passwords do not match"`
	func testCreateUserWithMismatchingPassword() throws {
		let app = try XCTUnwrap(Self.app)
		
		let user = User.Create(
			email: "test@email.com",
			username: "test_username",
			displayName: "Test Name",
			password: "password1",
			confirmPassword: "password2"
		)
		deletePossiblyCreatedUserAfterTestFinishes(username: user.username, on: app.db)
		
		try app.test(
			.POST, "users/v1",
			beforeRequest: { req in
				try req.content.encode(user)
			},
			afterResponse: { res in
				try res.assertError(status: .badRequest, reason: "Passwords do not match")
			}
		)
	}
	
	/// Tries to fetch an unexisting user.
	///
	/// - GIVEN:
	///     - Nothing
	/// - WHEN:
	///     - Trying to fetch a user with a random `id`
	/// - THEN:
	///     - `HTTP` status should be `404 Not Found`
	///     - `body` should be `"Not Found"`
	func testGetUserWithInexistentId() throws {
		let app = try XCTUnwrap(Self.app)
		
		try app.test(
			.GET, "users/v1/\(UUID())") { res in
			try res.assertError(status: .notFound, reason: "Not Found")
		}
	}
	
	/// Tries to create two users with same email address.
	///
	/// - GIVEN:
	///     - A user
	/// - WHEN:
	///     - Creating another user with the same email address
	/// - THEN:
	///     - `HTTP` status should be `403 Forbidden`
	///     - `body` should be `"Email or username already taken"`
	func testCreateUserWithExistingEmail() throws {
		let app = try XCTUnwrap(Self.app)
		
		let sameEmail = "test@email.com"
		
		// Create user
		let user1 = UserModel.dummy(email: sameEmail)
		try user1.create(on: app.db).wait()
		deleteUserAfterTestFinishes(user1, on: app.db)
		
		// Try to create other user
		let user2 = User.Create(
			email: sameEmail,
			username: "test_username2",
			displayName: "Test Name",
			password: "password2",
			confirmPassword: "password2"
		)
		deletePossiblyCreatedUserAfterTestFinishes(username: user2.username, on: app.db)
		try app.test(
			.POST, "users/v1",
			beforeRequest: { req in
				try req.content.encode(user2)
			},
			afterResponse: { res in
				try res.assertError(status: .forbidden, reason: "Email or username already taken")
			}
		)
	}
	
	/// Tries to create two users with same username.
	///
	/// - GIVEN:
	///     - A user
	/// - WHEN:
	///     - Creating another user with the same username
	/// - THEN:
	///     - `HTTP` status should be `403 Forbidden`
	///     - `body` should be `"Email or username already taken"`
	func testCreateUserWithExistingUsername() throws {
		let app = try XCTUnwrap(Self.app)
		
		let sameUsername = "test_username"
		
		// Create user
		let user1 = UserModel.dummy(username: sameUsername)
		try user1.create(on: app.db).wait()
		deleteUserAfterTestFinishes(user1, on: app.db)
		
		// Try to create other user
		let user2 = User.Create(
			email: "test2@email.com",
			username: sameUsername,
			displayName: "Test Name",
			password: "password2",
			confirmPassword: "password2"
		)
		deletePossiblyCreatedUserAfterTestFinishes(username: user2.username, on: app.db)
		try app.test(
			.POST, "users/v1",
			beforeRequest: { req in
				try req.content.encode(user2)
			},
			afterResponse: { res in
				try res.assertError(status: .forbidden, reason: "Email or username already taken")
			}
		)
	}
	
	/// Tries to create a user with a password of less than 8 characters.
	///
	/// - GIVEN:
	///     - Nothing
	/// - WHEN:
	///     - Trying to create a user with a password of less than 8 characters
	/// - THEN:
	///     -`HTTP` status should be `400 Bad Request`
	///     - `body` should be `"password is less than minimum of 8 character(s)"`
	func testCreateUserWithTooShortPassword() throws {
		let app = try XCTUnwrap(Self.app)
		
		let user = User.Create(
			email: "test@email.com",
			username: "test_username",
			displayName: "Test Name",
			password: "1234567",
			confirmPassword: "1234567"
		)
		deletePossiblyCreatedUserAfterTestFinishes(username: user.username, on: app.db)
		try app.test(
			.POST, "users/v1",
			beforeRequest: { req in
				try req.content.encode(user)
			},
			afterResponse: { res in
				try res.assertError(
					status: .badRequest,
					reason: "password is less than minimum of 8 character(s)"
				)
			}
		)
	}
	
	/// Tries to create a user with an invalid email.
	///
	/// - GIVEN:
	///     - Nothing
	/// - WHEN:
	///     - Trying to create a user with an invalid email
	/// - THEN:
	///     - `HTTP` status should be `400 Bad Request`
	///     - `body` should be `"email is not a valid email address"`
	func testCreateUserWithInvalidEmail() throws {
		let app = try XCTUnwrap(Self.app)
		
		let user = User.Create(
			email: "test@email",
			username: "test_username",
			displayName: "Test Name",
			password: "password",
			confirmPassword: "password"
		)
		deletePossiblyCreatedUserAfterTestFinishes(username: user.username, on: app.db)
		try app.test(
			.POST, "users/v1",
			beforeRequest: { req in
				try req.content.encode(user)
			},
			afterResponse: { res in
				try res.assertError(status: .badRequest, reason: "email is not a valid email address")
			}
		)
	}
	
	/// Tries to create a user with a username with a capital letter.
	///
	/// - GIVEN:
	///      - Nothing
	/// - WHEN:
	///      - Trying to create a user with a username with a capital letter
	/// - THEN:
	///     - `HTTP` status should be `400 Bad Request`
	///     - `body` should be `"Username contains invalid characters (allowed: a-z, 0-9, '.', '_')"`
	func testCreateUserWithInvalidUsername() throws {
		let app = try XCTUnwrap(Self.app)
		
		let user = User.Create(
			email: "test@email.com",
			username: "Test_username",
			displayName: "Test Name",
			password: "password",
			confirmPassword: "password"
		)
		deletePossiblyCreatedUserAfterTestFinishes(username: user.username, on: app.db)
		try app.test(
			.POST, "users/v1",
			beforeRequest: { req in
				try req.content.encode(user)
			},
			afterResponse: { res in
				try res.assertError(
					status: .badRequest,
					reason: "username contains 'T' (allowed: a-z, 0-9, '.', '_')"
				)
			}
		)
	}
	
	/// Test if `DELETE` aborts if invalid `Basic` token.
	///
	/// - GIVEN:
	///     - A user
	/// - WHEN:
	///     - Deleting a user with invalid `Bearer` token
	/// - THEN:
	///     - `HTTP` status should be `401 Unauthorized`
	///     - `body` should be `"Invalid authorization token."`
	func testDeleteUserWithInvalidBearerToken() throws {
		let app = try XCTUnwrap(Self.app)
		
		// Create user
		let userId = UUID()
		let user = UserModel.dummy()
		try user.create(on: app.db).wait()
		deleteUserAfterTestFinishes(user, on: app.db)
		
		try app.test(
			.DELETE, "users/v1/\(userId)",
			beforeRequest: { req in
				let invalidToken = [UInt8].random(count: 16).base64
				let bearerAuth = BearerAuthorization(token: invalidToken)
				req.headers.bearerAuthorization = bearerAuth
			},
			afterResponse: { res in
				try res.assertError(status: .unauthorized, reason: "Invalid authorization token.")
			}
		)
	}
	
	/// Test if `DELETE` aborts if `Basic` auth.
	///
	/// - GIVEN:
	///     - A user
	/// - WHEN:
	///     - Deleting a user with `Basic` auth
	/// - THEN:
	///     - `HTTP` status should be `401 Unauthorized`
	///     - `body` should be `"Invalid authorization token."`
	func testDeleteUserWithBasicAuth() throws {
		let app = try XCTUnwrap(Self.app)
		
		// Create user
		let userId = UUID()
		let password = "password"
		let user = UserModel.dummy(
			passwordHash: password // Do not hash for speed purposes
		)
		try user.create(on: app.db).wait()
		deleteUserAfterTestFinishes(user, on: app.db)
		
		try app.test(
			.DELETE, "users/v1/\(userId)",
			beforeRequest: { req in
				let basicAuth = BasicAuthorization(username: user.username, password: password)
				req.headers.basicAuthorization = basicAuth
			},
			afterResponse: { res in
				try res.assertError(status: .unauthorized, reason: "Invalid authorization token.")
			}
		)
	}
	
}
