//
//  PlacemarkControllerTests.swift
//  AppTests
//
//  Created by BARDON Rémi on 24/06/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

@testable import App
import XCTVapor
import Fluent

final class PlacemarkControllerTests: XCTestCase {
	
	private static var app: Application?
	private static var user: User?
	private static var userToken: User.Token?
	
	override class func setUp() {
		super.setUp()
		
		do {
			let app = Application(.testing)
			try configure(app)
			self.app = app
			
			// Create user
			let user = User(
				id: UUID(),
				username: "test_username",
				email: "test@email.com",
				passwordHash: "password" // Do not hash for speed purposes
			)
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
	
	/// Tests that the `"placemarks"` schema exists.
	///
	/// - GIVEN:
	///     - The empty database
	/// - WHEN:
	///     - Fetching all placemarks
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be an empty array
	///
	/// # Notes: #
	/// 1. Route will trigger a fatalError if the `"placemarks"` schema doesn't exist
	/// 2. If it works properly, then it means that the schema is ready
	func testSchemaExists() throws {
		let app = try XCTUnwrap(Self.app)
		
		try app.test(.GET, "v1/placemarks") { res in
			XCTAssertEqual(res.status, .ok)
			XCTAssertEqual(res.body.string, "[]")
		}
	}
	
	/// Tests `GET /v1/placemarks`.
	///
	/// - GIVEN:
	///     - A submitted placemark
	///     - A published placemark
	/// - WHEN:
	///     - Fetching all published placemarks
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be an array containing only the published placemark
	func testIndexReturnsTheListOfPublishedPlacemarks() throws {
		let app = try XCTUnwrap(Self.app)
		let user = try XCTUnwrap(Self.user)
		
		// Create submitted placemark
		let submittedPlacemark = try Placemark(
			id: UUID(),
			name: "Test name 1",
			latitude: Double.random(in: -90...90),
			longitude: Double.random(in: -180...180),
			typeId: typeId(for: "training_spot", on: app.db).wait(),
			state: .submitted,
			creatorId: user.requireID(),
			caption: "Test caption"
		)
		try submittedPlacemark.create(on: app.db).wait()
		deletePlacemarkAfterTestFinishes(submittedPlacemark)
		
		// Create published placemark
		let publishedPlacemark = try Placemark(
			id: UUID(),
			name: "Test name 2",
			latitude: Double.random(in: -90...90),
			longitude: Double.random(in: -180...180),
			typeId: typeId(for: "training_spot", on: app.db).wait(),
			state: .published,
			creatorId: user.requireID(),
			caption: "Test caption"
		)
		try publishedPlacemark.create(on: app.db).wait()
		deletePlacemarkAfterTestFinishes(publishedPlacemark)
		
		// Test route
		try app.test(.GET, "v1/placemarks") { res in
			// Test HTTP status
			XCTAssertEqual(res.status, .ok)
			
			if res.status == .ok {
				// Test data
				let placemarks = try res.content.decode([Placemark.Public].self)
				
				XCTAssertEqual(placemarks.count, 1)
				guard let placemarkResponse = placemarks.first else {
					XCTFail("Response does not contain a Placemark")
					return
				}
				
				XCTAssertEqual(placemarkResponse.id, publishedPlacemark.id)
			} else {
				// Log error
				let error = try res.content.decode(ResponseError.self)
				XCTFail(error.reason)
			}
		}
	}
	
	/// Tests `GET /v1/placemarks/submitted`.
	///
	/// - GIVEN:
	///     - A submitted placemark
	///     - A published placemark
	/// - WHEN:
	///     - Fetching all submitted placemarks
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be an array containing only the submitted placemark
	func testListSubmittedReturnsTheListOfSubmittedPlacemarks() throws {
		let app = try XCTUnwrap(Self.app)
		let user = try XCTUnwrap(Self.user)
		
		// Create submitted placemark
		let submittedPlacemark = try Placemark(
			id: UUID(),
			name: "Test name 1",
			latitude: Double.random(in: -90...90),
			longitude: Double.random(in: -180...180),
			typeId: typeId(for: "training_spot", on: app.db).wait(),
			state: .submitted,
			creatorId: user.requireID(),
			caption: "Test caption"
		)
		try submittedPlacemark.create(on: app.db).wait()
		deletePlacemarkAfterTestFinishes(submittedPlacemark)
		
		// Create published placemark
		let publishedPlacemark = try Placemark(
			id: UUID(),
			name: "Test name 2",
			latitude: Double.random(in: -90...90),
			longitude: Double.random(in: -180...180),
			typeId: typeId(for: "training_spot", on: app.db).wait(),
			state: .published,
			creatorId: user.requireID(),
			caption: "Test caption"
		)
		try publishedPlacemark.create(on: app.db).wait()
		deletePlacemarkAfterTestFinishes(publishedPlacemark)
		
		// Test route
		try app.test(.GET, "v1/placemarks/submitted") { res in
			// Test HTTP status
			XCTAssertEqual(res.status, .ok)
			
			if res.status == .ok {
				// Test data
				let placemarks = try res.content.decode([Placemark.Public].self)
				
				XCTAssertEqual(placemarks.count, 1)
				guard let placemarkResponse = placemarks.first else {
					XCTFail("Response does not contain a Placemark")
					return
				}
				
				XCTAssertEqual(placemarkResponse.id, submittedPlacemark.id)
			} else {
				// Log error
				let error = try res.content.decode(ResponseError.self)
				XCTFail(error.reason)
			}
		}
	}
	
	/// Creates a new spot
	/// Checks if status is 200 OK with placemark data
	/// And then checks if spot is actually stored on DB by fetching it
	func testPostSubmitsPlacemark() throws {
		let app = try XCTUnwrap(Self.app)
		let user = try XCTUnwrap(Self.user)
		let userToken = try XCTUnwrap(Self.userToken)
		
		// Create placemark
		let create = Placemark.Create(
			name: "Test name",
			latitude: Double.random(in: -90...90),
			longitude: Double.random(in: -180...180),
			type: "training_spot",
			caption: "Test caption",
			images: nil,
			features: nil,
			goodForTraining: nil,
			benefits: nil,
			hazards: nil
		)
		// Delete possibly created placemark
		deletePossiblyCreatedPlacemarkAfterTestFinishes(name: create.name)
		
		// Test response
		try app.test(.POST, "v1/placemarks", beforeRequest: { req in
			let bearerAuth = BearerAuthorization(token: userToken.value)
			req.headers.bearerAuthorization = bearerAuth
			
			try req.content.encode(create)
		}) { res in
			// Test HTTP status
			XCTAssertEqual(res.status, .ok)
			
			if res.status == .ok {
				// Test data
				let placemark = try res.content.decode(Placemark.Public.self)
				
				XCTAssertEqual(placemark.name, create.name)
				XCTAssertEqual(placemark.caption, create.caption)
				XCTAssertEqual(placemark.latitude, create.latitude)
				XCTAssertEqual(placemark.longitude, create.longitude)
				XCTAssertEqual(placemark.creator, try user.requireID())
				XCTAssertEqual(placemark.state, .submitted)
				XCTAssertEqual(placemark.satelliteImage.absoluteString, "https://monkiprojects.com/images/satellite-view-placeholder.jpg")
				XCTAssertEqual(placemark.type, "training_spot")
				XCTAssertEqual(placemark.category, "spot")
				XCTAssertEqual(placemark.images, [])
				XCTAssertEqual(placemark.features, [])
				XCTAssertEqual(placemark.goodForTraining, [])
				XCTAssertEqual(placemark.benefits, [])
				XCTAssertEqual(placemark.hazards, [])
				XCTAssertNotNil(placemark.createdAt)
				XCTAssertNotNil(placemark.updatedAt)
				
				// Test creation on DB
				let storedPlacemark = try Placemark.find(placemark.id, on: app.db).wait()
				XCTAssertNotNil(storedPlacemark)
			} else {
				// Log error
				let error = try res.content.decode(ResponseError.self)
				XCTFail(error.reason)
			}
		}
	}
	
	/// Tests `GET /v1/placemarks/{placemarkId}`.
	///
	/// - GIVEN:
	///     - A placemark
	/// - WHEN:
	///     - Getting details of the placemark
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be the placemrk's details
	func testGetPlacemarkDetails() throws {
		let app = try XCTUnwrap(Self.app)
		let user = try XCTUnwrap(Self.user)
		
		// Create submitted placemark
		let placemarkId = UUID()
		let placemark = try Placemark(
			id: placemarkId,
			name: "Test name",
			latitude: Double.random(in: -90...90),
			longitude: Double.random(in: -180...180),
			typeId: typeId(for: "training_spot", on: app.db).wait(),
			state: .submitted,
			creatorId: user.requireID(),
			caption: "Test caption"
		)
		try placemark.create(on: app.db).wait()
		deletePlacemarkAfterTestFinishes(placemark)
		
		// Test route
		try app.test(.GET, "v1/placemarks/\(placemarkId)") { res in
			// Test HTTP status
			XCTAssertEqual(res.status, .ok)
			
			if res.status == .ok {
				// Test data
				let placemarkResponse = try res.content.decode(Placemark.Public.self)
				
				XCTAssertEqual(placemarkResponse.id, placemark.id)
			} else {
				// Log error
				let error = try res.content.decode(ResponseError.self)
				XCTFail(error.reason)
			}
		}
	}
	
	/// Tests `DELETE /v1/placemarks/{placemarkId}`.
	///
	/// - GIVEN:
	///     - A placemark
	/// - WHEN:
	///     - Deleting the placemark
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be empty
	func testDeletePlacemark() throws {
		let app = try XCTUnwrap(Self.app)
		let user = try XCTUnwrap(Self.user)
		let userToken = try XCTUnwrap(Self.userToken)
		
		// Create submitted placemark
		let placemarkId = UUID()
		let placemark = try Placemark(
			id: placemarkId,
			name: "Test name",
			latitude: Double.random(in: -90...90),
			longitude: Double.random(in: -180...180),
			typeId: typeId(for: "training_spot", on: app.db).wait(),
			state: .submitted,
			creatorId: user.requireID(),
			caption: "Test caption"
		)
		try placemark.create(on: app.db).wait()
		deletePlacemarkAfterTestFinishes(placemark)
		
		// Test route
		try app.test(.DELETE, "v1/placemarks/\(placemarkId)",
			beforeRequest: { req in
				let bearerAuth = BearerAuthorization(token: userToken.value)
				req.headers.bearerAuthorization = bearerAuth
			},
			afterResponse: { res in
				// Test HTTP status
				XCTAssertEqual(res.status, .ok)
				XCTAssertEqual(res.body.string, "")
			}
		)
	}
	
	// MARK: - Invalid Domain
	
	/// Tries to create a placemark with a name of less than 3 characters.
	///
	/// - GIVEN:
	///     - Nothing
	/// - WHEN:
	///     - Creating a placemark with a name of less than 3 characters
	/// - THEN:
	///     - `HTTP` status should be `400 Bad Request`
	///     - `body` should be `"name is less than minimum of 3 character(s)"`
	func testCreateSpotWithTitleTooSmall() throws {
		let app = try XCTUnwrap(Self.app)
		let userToken = try XCTUnwrap(Self.userToken)
		
		// Create placemark
		let create = Placemark.Create(
			name: "12",
			latitude: Double.random(in: -90...90),
			longitude: Double.random(in: -180...180),
			type: "training_spot",
			caption: "Test caption",
			images: nil,
			features: nil,
			goodForTraining: nil,
			benefits: nil,
			hazards: nil
		)
		// Delete possibly created placemark
		deletePossiblyCreatedPlacemarkAfterTestFinishes(name: create.name)
		
		// Test response
		try app.test(.POST, "v1/placemarks", beforeRequest: { req in
			let bearerAuth = BearerAuthorization(token: userToken.value)
			req.headers.bearerAuthorization = bearerAuth
			
			try req.content.encode(create)
		}) { res in
			// Test HTTP status
			XCTAssertEqual(res.status, .badRequest)
			
			if res.status == .badRequest {
				// Test error message
				let error = try res.content.decode(ResponseError.self)
				XCTAssertEqual(error.reason, "name is less than minimum of 3 character(s)")
			} else if res.status != .ok {
				// Log error
				let error = try res.content.decode(ResponseError.self)
				XCTFail(error.reason)
			}
		}
	}
	
	/// Tries to get details for an inexistent placemark.
	///
	/// - GIVEN:
	///     - Nothing
	/// - WHEN:
	///     - Getting details for an inexistent placemark
	/// - THEN:
	///     - `HTTP` status should be `404 Not Found`
	///     - `body` should be `"Not Found"`
	func testGetPlacemarkWithInexistentId() throws {
		let app = try XCTUnwrap(Self.app)
		
		try app.test(.GET, "v1/placemarks/\(UUID())") { res in
			// Test HTTP status
			XCTAssertEqual(res.status, .notFound)
			
			if res.status == .notFound {
				// Test error message
				let error = try res.content.decode(ResponseError.self)
				XCTAssertEqual(error.reason, "Not Found")
			} else if res.status != .ok {
				// Log error
				let error = try res.content.decode(ResponseError.self)
				XCTFail(error.reason)
			}
		}
	}
	
	/// Tries to create a placemark with an invalid `Bearer` token.
	///
	/// - GIVEN:
	///     - A user
	/// - WHEN:
	///     - Creating a placemark with an invalid `Bearer` token
	/// - THEN:
	///     - `HTTP` status should be `401 Unauthorized`
	///     - `body` should be `"Unauthorized"`
	func testCreatePlacemarkInvalidBearerToken() throws {
		let app = try XCTUnwrap(Self.app)
		
		try app.test(.POST, "v1/placemarks", beforeRequest: { req in
			let invalidToken = [UInt8].random(count: 16).base64
			let bearerAuth = BearerAuthorization(token: invalidToken)
			req.headers.bearerAuthorization = bearerAuth
		}) { res in
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
	}
	
	/// Tries to delete someone else's placemark.
	///
	/// - GIVEN:
	///     - Two users
	///     - A placemark from user 1
	/// - WHEN:
	///     - User 2 tries to delete the placemark
	/// - THEN:
	///     - `HTTP` status should be `401 Unauthorized`
	///     - `body` should be `"You cannot delete someone else's placemark"`
	func testDeleteSomeoneElsesPlacemark() throws {
		let app = try XCTUnwrap(Self.app)
		let userToken = try XCTUnwrap(Self.userToken)
		
		// Create other user
		let otherUser = User(
			id: UUID(),
			username: "other_user",
			email: "other@email.com",
			passwordHash: "password" // Do not hash for speed purposes
		)
		try otherUser.create(on: app.db).wait()
		// Delete other user after test finishes
		addTeardownBlock {
			do {
				try otherUser.delete(force: true, on: app.db).wait()
			} catch {
				XCTFail(error.localizedDescription)
			}
		}
		
		// Create placemark
		let placemarkId = UUID()
		let placemark = try Placemark(
			id: placemarkId,
			name: "Test name",
			latitude: Double.random(in: -90...90),
			longitude: Double.random(in: -180...180),
			typeId: typeId(for: "training_spot", on: app.db).wait(),
			state: .submitted,
			creatorId: otherUser.requireID(),
			caption: "Test caption"
		)
		try placemark.create(on: app.db).wait()
		deletePlacemarkAfterTestFinishes(placemark)
		
		// Test route
		try app.test(.DELETE, "v1/placemarks/\(placemarkId)",
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
					XCTAssertEqual(error.reason, "You cannot delete someone else's placemark")
				} else if res.status != .ok {
					// Log error
					let error = try res.content.decode(ResponseError.self)
					XCTFail(error.reason)
				}
			}
		)
	}
	
	// MARK: - Helpers
	
	/// Adds a `tearDown` block that deletes the given `Placemark` after the current test finishes.
	///
	/// - Parameters:
	///   - placemark: The `Placemark` to delete
	///
	/// # Notes: #
	/// 1. Forces deletion
	///
	/// # Example #
	/// ```
	/// // Create placemark
	/// let placemark = try Placemark(
	/// name: "test_title",
	/// 	latitude: Double.random(in: -90...90),
	/// 	longitude: Double.random(in: -180...180),
	/// 	typeId: typeId(for: "training_spot", on: app.db).wait(),
	/// 	creatorId: user.requireID(),
	/// 	caption: "Test caption"
	/// )
	/// try placemark.create(on: app.db).wait()
	/// deletePlacemarkAfterTestFinishes(placemark)
	/// ```
	private func deletePlacemarkAfterTestFinishes(_ placemark: Placemark?) {
		addTeardownBlock {
			do {
				let app = try XCTUnwrap(Self.app)
				try placemark?.delete(force: true, on: app.db).wait()
			} catch {
				XCTFail(error.localizedDescription)
			}
		}
	}
	
	/// Adds a `tearDown` block that deletes the `Placemark` with the given `name`
	/// after the current test finishes.
	///
	/// Does nothing if no `Placemark` has the given `username`.
	///
	/// - Parameters:
	///   - name: The placemarks's `name`
	///
	/// # Notes: #
	/// 1. Forces deletion
	///
	/// # Example #
	/// ```
	/// // Delete possibly created placemark
	/// deletePossiblyCreatedPlacemarkAfterTestFinishes(name: placemark.name)
	/// ```
	private func deletePossiblyCreatedPlacemarkAfterTestFinishes(name: String) {
		addTeardownBlock {
			do {
				let app = try XCTUnwrap(Self.app)
				
				try Placemark.query(on: app.db)
					.filter(\.$name == name)
					.first()
					.optionalMap { $0.delete(force: true, on: app.db) }
					.transform(to: ())
					.wait()
			} catch {
				XCTFail(error.localizedDescription)
			}
		}
	}
	
	private func typeId(for humanId: String, on db: Database) -> EventLoopFuture<Placemark.PlacemarkType.IDValue> {
		Placemark.PlacemarkType.query(on: db)
			.filter(\.$humanId == humanId)
			.first()
			.unwrap(or: Abort(.notFound, reason: "Type not found"))
			.flatMapThrowing { try $0.requireID() }
	}
	
}
