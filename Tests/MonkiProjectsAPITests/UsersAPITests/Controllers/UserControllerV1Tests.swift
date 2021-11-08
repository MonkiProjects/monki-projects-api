//
//  UserControllerV1Tests.swift
//  UsersAPITests
//
//  Created by Rémi Bardon on 23/06/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

@testable import MonkiProjectsAPI
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
	
	/// Tests username filtering on `GET /users/v1/`.
	///
	/// - GIVEN:
	///     - Multiple users
	/// - WHEN:
	///     - Searching for a user with matching username
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be a paginated array containing matching users
	///     - Matching users should be the ones where username starts with,
	///       contains or ends with the given part, case insensitive.
	func testFindingUsersByUsername() async throws {
		let app = try XCTUnwrap(Self.app)
		
		let existing: Set<String> = ["def", "defghi", "abcdef", "bcdefgh", "abc", "ghi", "de"]
		let cases: [(filter: String, matches: Set<String>)] = [
			(filter: "def", matches: ["def", "defghi", "abcdef", "bcdefgh"]),
		]
		
		// Create users
		for username in existing {
			let user = UserModel.dummy(username: username)
			deleteUserAfterTestFinishes(user, on: app.db)
			try await user.create(on: app.db)
		}
		
		for (filter, matches) in cases {
			try app.test(.GET, "users/v1?username=\(filter)") { res in
				try res.assertStatus(.ok) {
					let page = try res.content.decode(Fluent.Page<User.Public.Small>.self)
					let users = page.items
					
					XCTAssertEqual(users.count, matches.count)
					XCTAssertEqual(page.metadata.total, matches.count)
					
					XCTAssertEqual(Set(users.map(\.username)), matches)
				}
			}
		}
	}
	
	/// Tests display name filtering on `GET /users/v1/`.
	///
	/// - GIVEN:
	///     - Multiple users
	/// - WHEN:
	///     - Searching for a user with matching display name
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be a paginated array containing matching users
	///     - Matching users should be the ones where display name starts with,
	///       contains or ends with the given part, case insensitive.
	func testFindingUsersByDisplayName() async throws {
		let app = try XCTUnwrap(Self.app)
		
		let existing: Set<String> = ["def", "defghi", "abcdef", "bcdefgh", "abc", "ghi", "de"]
		let cases: [(filter: String, matches: Set<String>)] = [
			(filter: "def", matches: ["def", "defghi", "abcdef", "bcdefgh"]),
		]
		
		// Create users
		for displayName in existing {
			let user = UserModel.dummy(displayName: displayName)
			deleteUserAfterTestFinishes(user, on: app.db)
			try await user.create(on: app.db)
		}
		
		for (filter, matches) in cases {
			try app.test(.GET, "users/v1?display_name=\(filter)") { res in
				try res.assertStatus(.ok) {
					let page = try res.content.decode(Fluent.Page<User.Public.Small>.self)
					let users = page.items
					
					XCTAssertEqual(users.count, matches.count)
					XCTAssertEqual(page.metadata.total, matches.count)
					
					XCTAssertEqual(Set(users.map(\.displayName)), matches)
				}
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
			username: username,
			displayName: "Test Name",
			email: "test@email.com",
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
					XCTAssertEqual(createdUser.displayName, user.displayName)
					XCTAssertEqual(createdUser.email, user.email)
					XCTAssertEqual(createdUser.kind, .user)
					XCTAssertNil(createdUser.details.bio)
					XCTAssertNil(createdUser.details.location)
					XCTAssertEqual(createdUser.details.experience, [:])
					XCTAssertEqual(createdUser.details.socialUsernames, [:])
					
					// Test creation on DB
					let storedUser = try UserModel.find(createdUser.id, on: app.db).wait()
					XCTAssertNotNil(storedUser)
				}
			}
		)
	}
	
	/// Test if `PATCH` actually updates the user details.
	///
	/// - GIVEN:
	///     - A user
	/// - WHEN:
	///     - Updating the user's username
	///     - Updating the user's display name
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be the updated user's data
	///     - user details should be updated in database
	func testUpdateUser() throws {
		let app = try XCTUnwrap(Self.app)
		
		// Create user
		let userId = User.ID()
		let user = UserModel.dummy(id: userId)
		try user.create(on: app.db).wait()
		deleteUserAfterTestFinishes(user, on: app.db)
		
		// Create new token
		let token = try user.generateToken()
		try token.create(on: app.db).wait()
		deleteUserTokenAfterTestFinishes(token, on: app.db)
		
		let updateBody = User.Update(
			username: UUID().uuidString,
			displayName: UUID().uuidString
		)
		try app.test(
			.PATCH, "users/v1/\(userId)",
			beforeRequest: { req in
				let bearerAuth = BearerAuthorization(token: token.value)
				req.headers.bearerAuthorization = bearerAuth
				
				try req.content.encode(updateBody)
			},
			afterResponse: { res in
				try res.assertStatus(.ok) {
					let details = try res.content.decode(User.Public.Full.self)
					
					// Test response content
					XCTAssertEqual(details.username, updateBody.username)
					XCTAssertEqual(details.displayName, updateBody.displayName)
					
					// Test stored user
					let userId = try user.requireID()
					let storedUser = try XCTUnwrap(UserModel.find(userId, on: app.db).wait())
					XCTAssertEqual(storedUser.username, updateBody.username)
					XCTAssertEqual(storedUser.displayName, updateBody.displayName)
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
	///     - `HTTP` status should be `204 No Content`
	///     - `body` should be empty
	///     - user tokens should all be deleted from database
	///     - user should be deleted from database
	func testDeleteUser() throws {
		let app = try XCTUnwrap(Self.app)
		
		// Create user
		let userId = User.ID()
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
				try res.assertStatus(.noContent) {
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
			username: "test_username",
			displayName: "Test Name",
			email: "test@email.com",
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
	///     - `body` should be `"User not found"`
	func testGetUserWithInexistentId() throws {
		let app = try XCTUnwrap(Self.app)
		
		try app.test(
			.GET, "users/v1/\(User.ID())") { res in
			try res.assertError(status: .notFound, reason: "User not found")
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
	///     - `body` should be `"Email already taken"`
	func testCreateUserWithExistingEmail() throws {
		let app = try XCTUnwrap(Self.app)
		
		let sameEmail = "test@email.com"
		
		// Create user
		let user1 = UserModel.dummy(email: sameEmail)
		try user1.create(on: app.db).wait()
		deleteUserAfterTestFinishes(user1, on: app.db)
		
		// Try to create other user
		let user2 = User.Create(
			username: "test_username2",
			displayName: "Test Name",
			email: sameEmail,
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
				try res.assertError(status: .forbidden, reason: "Email already taken")
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
	///     - `body` should be `"Username already taken"`
	func testCreateUserWithExistingUsername() throws {
		let app = try XCTUnwrap(Self.app)
		
		let sameUsername = "test_username"
		
		// Create user
		let user1 = UserModel.dummy(username: sameUsername)
		try user1.create(on: app.db).wait()
		deleteUserAfterTestFinishes(user1, on: app.db)
		
		// Try to create other user
		let user2 = User.Create(
			username: sameUsername,
			displayName: "Test Name",
			email: "test2@email.com",
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
				try res.assertError(status: .forbidden, reason: "Username already taken")
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
			username: "test_username",
			displayName: "Test Name",
			email: "test@email.com",
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
			username: "test_username",
			displayName: "Test Name",
			email: "test@email",
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
	///     - `body` should be `"username contains 'T' (allowed: a-z, 0-9, '.', '_', '-')"`
	func testCreateUserWithInvalidUsername() throws {
		let app = try XCTUnwrap(Self.app)
		
		let user = User.Create(
			username: "Test_username",
			displayName: "Test Name",
			email: "test@email.com",
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
					reason: "username contains 'T' (allowed: a-z, 0-9, '.', '_', '-')"
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
		let userId = User.ID()
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
				XCTAssertTrue(res.headers.contains(name: .wwwAuthenticate))
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
		let userId = User.ID()
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
				XCTAssertTrue(res.headers.contains(name: .wwwAuthenticate))
			}
		)
	}
	
}
