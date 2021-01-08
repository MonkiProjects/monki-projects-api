//
//  UserControllerTests.swift
//  AppTests
//
//  Created by Rémi Bardon on 23/06/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

@testable import App
import XCTVapor
import Fluent

class UserControllerTests: XCTestCase {
	
	private static var app: Application?
	
	/// Starts the app in testing mode and deletes everything in database.
	override class func setUp() {
		super.setUp()
		
		do {
			let app = Application(.testing)
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
	
	// MARK: - Valid Domain
	
	/// Tests that the `"users"` schema exists.
	///
	/// - GIVEN:
	///     - The empty database
	/// - WHEN:
	///     - Fetching all users
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be an empty array
	///
	/// # Notes: #
	/// 1. Route will trigger a fatalError if the `"users"` schema doesn't exist
	/// 2. If it works properly, then it means that the schema is ready
	func testSchemaExists() throws {
		let app = try XCTUnwrap(Self.app)
		
		try app.test(.GET, "v1/users") { res in
			XCTAssertEqual(res.status, .ok)
			XCTAssertEqual(res.body.string, "[]")
		}
	}
	
	/// Tests `GET /users`.
	///
	/// - GIVEN:
	///     - A user
	/// - WHEN:
	///     - Fetching all users
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be an array containing only the user
	func testIndexReturnsListOfUsers() throws {
		let app = try XCTUnwrap(Self.app)
		
		// Create user
		let user = User(
			id: UUID(),
			username: "test_username",
			email: "test@email.com",
			passwordHash: "password" // Do not hash for speed purposes
		)
		try user.create(on: app.db).wait()
		deleteUserAfterTestFinishes(user)
		
		// Test route
		try app.test(.GET, "v1/users") { res in
			// Test HTTP status
			XCTAssertEqual(res.status, .ok)
			
			if res.status == .ok {
				// Test data
				let users = try res.content.decode([User].self)
				
				XCTAssertEqual(users.count, 1)
				let userResponse = try XCTUnwrap(users.first)
				
				XCTAssertEqual(userResponse.id, user.id)
			} else {
				// Log error
				XCTFail(res.body.string)
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
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be the user's data
	///     - user should be stored on database
	func testPostCreatesUser() throws {
		let app = try XCTUnwrap(Self.app)
		
		// Create user
		let user = User.Create(
			username: "test_username",
			email: "test@email.com",
			password: "password",
			confirmPassword: "password"
		)
		
		// Test response
		try app.test(.POST, "v1/users",
			beforeRequest: { req in
				try req.content.encode(user)
			},
			afterResponse: { res in
				// Test HTTP status
				XCTAssertEqual(res.status, .ok)
				
				if res.status == .ok {
					// Test data
					let createdUser = try res.content.decode(User.self)
					
					XCTAssertEqual(createdUser.username, user.username)
					XCTAssertEqual(createdUser.email, user.email)
					
					// Test creation on DB
					let storedUser = try User.find(createdUser.id, on: app.db).wait()
					XCTAssertNotNil(storedUser)
					
					// Delete user
					deleteUserAfterTestFinishes(storedUser)
				} else {
					// Log error
					XCTFail(res.body.string)
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
		let user = User(
			id: userId,
			username: "temp_username",
			email: "temp@email.com",
			passwordHash: try Bcrypt.hash("password")
		)
		try user.create(on: app.db).wait()
		addTeardownBlock {
			do {
				try user.delete(force: true, on: app.db).wait()
			} catch {
				XCTFail(error.localizedDescription)
			}
		}
		
		// Create new token
		let token = try user.generateToken()
		try token.create(on: app.db).wait()
		addTeardownBlock {
			do {
				try token.delete(force: true, on: app.db).wait()
			} catch {
				XCTFail(error.localizedDescription)
			}
		}
		
		// Test deletion
		try app.test(.DELETE, "v1/users/\(userId)",
			beforeRequest: { req in
				let bearerAuth = BearerAuthorization(token: token.value)
				req.headers.bearerAuthorization = bearerAuth
			},
			afterResponse: { res in
				// Test HTTP status
				XCTAssertEqual(res.status, .ok)
				
				if res.status == .ok {
					// Test data
					XCTAssertEqual(res.body.string, "")
					
					// Test if user is really deleted
					let userId = try user.requireID()
					let storedUser = try User.find(userId, on: app.db).wait()
					XCTAssertNil(storedUser)
					
					// Test if user tokens are deleted
					let tokens = try User.Token.query(on: app.db)
						.with(\.$user)					// Load user to filter on its `id` field
						.filter(\.$user.$id == userId)	// Filter only the user's tokens
						.all() 							// Get all results
						.wait()
					XCTAssertTrue(tokens.isEmpty)
				} else {
					// Log error
					let error = try res.content.decode(ResponseError.self)
					XCTFail(error.reason)
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
		
		// Test response
		let user = User.Create(
			username: "test_username",
			email: "test@email.com",
			password: "password1",
			confirmPassword: "password2"
		)
		deletePossiblyCreatedUserAfterTestFinishes(username: user.username)
		try app.test(.POST, "v1/users",
			beforeRequest: { req in
				try req.content.encode(user)
			},
			afterResponse: { res in
				// Test HTTP status
				XCTAssertEqual(res.status, .badRequest)
				
				let error = try res.content.decode(ResponseError.self)
				if res.status == .badRequest {
					// Test error message
					XCTAssertEqual(error.reason, "Passwords do not match")
				} else if res.status != .ok {
					// Log error
					XCTFail(error.reason)
				}
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
		
		// Test response
		try app.test(.GET, "v1/users/\(UUID())") { res in
			// Test HTTP status
			XCTAssertEqual(res.status, .notFound)
			
			let error = try res.content.decode(ResponseError.self)
			if res.status == .notFound {
				// Test error message
				XCTAssertEqual(error.reason, "Not Found")
			} else if res.status != .ok {
				// Log error
				XCTFail(error.reason)
			}
		}
	}
	
	/// Tries to create two users with same email address.
	///
	/// - GIVEN:
	///     - A user
	/// - WHEN:
	///     - Creating another user with the same email address
	/// - THEN:
	///     - `HTTP` status should be `400 Bad Request`
	///     - `body` should be `"Email or username already taken"`
	func testCreateUserWithExistingEmail() throws {
		let app = try XCTUnwrap(Self.app)
		
		// Create user
		let user1 = User(
			id: UUID(),
			username: "test_username1",
			email: "test@email.com",
			passwordHash: "password1" // Do not hash for speed purposes
		)
		try user1.create(on: app.db).wait()
		deleteUserAfterTestFinishes(user1)
		
		// Test response
		let user2 = User.Create(
			username: "test_username2",
			email: "test@email.com",
			password: "password2",
			confirmPassword: "password2"
		)
		deletePossiblyCreatedUserAfterTestFinishes(username: user2.username)
		try app.test(.POST, "v1/users",
			beforeRequest: { req in
				try req.content.encode(user2)
			},
			afterResponse: { res in
				// Test HTTP status
				XCTAssertEqual(res.status, .badRequest)
				
				let error = try res.content.decode(ResponseError.self)
				if res.status == .badRequest {
					// Test error message
					XCTAssertEqual(error.reason, "Email or username already taken")
				} else if res.status != .ok {
					// Log error
					XCTFail(error.reason)
				}
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
	///     - `HTTP` status should be `400 Bad Request`
	///     - `body` should be `"Email or username already taken"`
	func testCreateUserWithExistingUsername() throws {
		let app = try XCTUnwrap(Self.app)
		
		// Create user
		let user1 = User(
			id: UUID(),
			username: "test_username",
			email: "test1@email.com",
			passwordHash: "password1" // Do not hash for speed purposes
		)
		try user1.create(on: app.db).wait()
		deleteUserAfterTestFinishes(user1)
		
		// Test response
		let user2 = User.Create(
			username: "test_username",
			email: "test2@email.com",
			password: "password2",
			confirmPassword: "password2"
		)
		deletePossiblyCreatedUserAfterTestFinishes(username: user2.username)
		try app.test(.POST, "v1/users",
			beforeRequest: { req in
				try req.content.encode(user2)
			},
			afterResponse: { res in
				// Test HTTP status
				XCTAssertEqual(res.status, .badRequest)
				
				let error = try res.content.decode(ResponseError.self)
				if res.status == .badRequest {
					// Test error message
					XCTAssertEqual(error.reason, "Email or username already taken")
				} else if res.status != .ok {
					// Log error
					XCTFail(error.reason)
				}
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
		
		// Test response
		let user = User.Create(
			username: "test_username",
			email: "test@email.com",
			password: "1234567",
			confirmPassword: "1234567"
		)
		deletePossiblyCreatedUserAfterTestFinishes(username: user.username)
		try app.test(.POST, "v1/users",
			beforeRequest: { req in
				try req.content.encode(user)
			},
			afterResponse: { res in
				// Test HTTP status
				XCTAssertEqual(res.status, .badRequest)
				
				let error = try res.content.decode(ResponseError.self)
				if res.status == .badRequest {
					// Test error message
					XCTAssertEqual(error.reason, "password is less than minimum of 8 character(s)")
				} else if res.status != .ok {
					// Log error
					XCTFail(error.reason)
				}
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
		
		// Test response
		let user = User.Create(
			username: "test_username",
			email: "test@email",
			password: "password",
			confirmPassword: "password"
		)
		deletePossiblyCreatedUserAfterTestFinishes(username: user.username)
		try app.test(.POST, "v1/users",
			beforeRequest: { req in
				try req.content.encode(user)
			},
			afterResponse: { res in
				// Test HTTP status
				XCTAssertEqual(res.status, .badRequest)
				
				let error = try res.content.decode(ResponseError.self)
				if res.status == .badRequest {
					// Test error message
					XCTAssertEqual(error.reason, "email is not a valid email address")
				} else if res.status != .ok {
					// Log error
					XCTFail(error.reason)
				}
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
		
		// Test response
		let user = User.Create(
			username: "Test_username",
			email: "test@email.com",
			password: "password",
			confirmPassword: "password"
		)
		deletePossiblyCreatedUserAfterTestFinishes(username: user.username)
		try app.test(.POST, "v1/users",
			beforeRequest: { req in
				try req.content.encode(user)
			},
			afterResponse: { res in
				// Test HTTP status
				XCTAssertEqual(res.status, .badRequest)
				
				let error = try res.content.decode(ResponseError.self)
				if res.status == .badRequest {
					// Test error message
					XCTAssertEqual(error.reason, "username contains 'T' (allowed: a-z, 0-9, '.', '_')")
				} else if res.status != .ok {
					// Log error
					XCTFail(error.reason)
				}
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
	///     - `body` should be `"Unauthorized"`
	func testDeleteUserWithInvalidBearerToken() throws {
		let app = try XCTUnwrap(Self.app)
		
		// Create user
		let userId = UUID()
		let user = User(
			id: UUID(),
			username: "test_username",
			email: "test@email.com",
			passwordHash: "password" // Do not hash for speed purposes
		)
		try user.create(on: app.db).wait()
		deleteUserAfterTestFinishes(user)
		
		try app.test(.DELETE, "v1/users/\(userId)",
			beforeRequest: { req in
				let invalidToken = [UInt8].random(count: 16).base64
				let bearerAuth = BearerAuthorization(token: invalidToken)
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
	
	/// Test if `DELETE` aborts if `Basic` auth.
	///
	/// - GIVEN:
	///     - A user
	/// - WHEN:
	///     - Deleting a user with `Basic` auth
	/// - THEN:
	///     - `HTTP` status should be `401 Unauthorized`
	///     - `body` should be `"Unauthorized"`
	func testDeleteUserWithBasicAuth() throws {
		let app = try XCTUnwrap(Self.app)
		
		// Create user
		let userId = UUID()
		let password = "password"
		let user = User(
			id: UUID(),
			username: "test_username",
			email: "test@email.com",
			passwordHash: password // Do not hash for speed purposes
		)
		try user.create(on: app.db).wait()
		deleteUserAfterTestFinishes(user)
		
		try app.test(.DELETE, "v1/users/\(userId)",
			beforeRequest: { req in
				let basicAuth = BasicAuthorization(username: user.username, password: password)
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
	
	/// Adds a `tearDown` block that deletes the given `User` after the current test finishes.
	///
	/// - Parameters:
	///   - user: The `User` to delete
	///
	/// # Notes: #
	/// 1. Forces deletion
	///
	/// # Example #
	/// ```
	/// // Create user
	/// let user = User(
	/// 	id: UUID(),
	/// 	email: "test@email.com",
	/// 	username: "test_username",
	/// 	displayName: "Test User",
	/// 	passwordHash: try BCrypt.hash("password")
	/// )
	/// try user.create(on: Self.app.db).wait()
	/// deleteUserAfterTestFinishes(user)
	/// ```
	private func deleteUserAfterTestFinishes(_ user: User?) {
		addTeardownBlock {
			do {
				let app = try XCTUnwrap(Self.app)
				
				try user?.delete(force: true, on: app.db).wait()
			} catch {
				XCTFail(error.localizedDescription)
			}
		}
	}
	
	/// Adds a `tearDown` block that deletes the `User` with the given `username`
	/// after the current test finishes.
	///
	/// Does nothing if no `User` has the given `username`.
	///
	/// - Parameters:
	///   - username: The user's `username`
	///
	/// # Notes: #
	/// 1. Forces deletion
	///
	/// # Example #
	/// ```
	/// // Delete possibly created user
	/// deletePossiblyCreatedUserAfterTestFinishes(username: user.username)
	/// ```
	private func deletePossiblyCreatedUserAfterTestFinishes(username: String) {
		addTeardownBlock {
			do {
				let app = try XCTUnwrap(Self.app)
				
				let storedUser = try User.query(on: app.db)
					.filter(\.$username == username).first()
					.wait()
				try storedUser?.delete(force: true, on: app.db).wait()
			} catch {
				XCTFail(error.localizedDescription)
			}
		}
	}
	
}
// swiftlint:disable:this file_length
