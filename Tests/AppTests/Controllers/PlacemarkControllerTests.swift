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
import Models
import GEOSwift

// swiftlint:disable closure_body_length
// swiftlint:disable:next type_body_length
internal final class PlacemarkControllerTests: AppTestCase {
	
	private static var user: UserModel?
	private static var userToken: UserModel.Token?
	
	override class func setUp() {
		super.setUp()
		
		do {
			let app = try XCTUnwrap(self.app)
			
			// Create user
			let user = UserModel.dummy()
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
	
	/// Tests that the `"placemarks"` schema exists.
	///
	/// - GIVEN:
	///     - The empty database
	/// - WHEN:
	///     - Fetching all placemarks (paginated)
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be an empty paginated array
	///
	/// # Notes: #
	/// 1. Route will trigger a fatalError if the `"placemarks"` schema doesn't exist
	/// 2. If it works properly, then it means that the schema is ready
	func testSchemaExists() throws {
		let app = try XCTUnwrap(Self.app)
		
		try app.test(.GET, "placemarks/v1") { res in
			try res.assertStatus(.ok) {
				let page = try res.content.decode(Page<Placemark.Public>.self)
				let placemarks = page.items
				
				XCTAssertEqual(placemarks.count, 0)
				XCTAssertEqual(page.metadata.total, 0)
			}
		}
	}
	
	/// Tests `GET /placemarks/v1`.
	///
	/// - GIVEN:
	///     - A submitted placemark
	///     - A published placemark
	/// - WHEN:
	///     - Fetching all published placemarks (paginated)
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be a paginated array containing only the published placemark
	func testIndexReturnsTheListOfPublishedPlacemarks() throws {
		let app = try XCTUnwrap(Self.app)
		let user = try XCTUnwrap(Self.user)
		
		// Create submitted placemark
		let submittedPlacemark = try PlacemarkModel.dummy(
			kindId: kindId(for: "training_spot", on: app.db).wait(),
			creatorId: user.requireID()
		)
		try createPlacemark(submittedPlacemark, on: app.db).wait()
		deletePlacemarkAfterTestFinishes(submittedPlacemark, on: app.db)
		
		// Create published placemark
		let publishedPlacemark = try PlacemarkModel.dummy(
			kindId: kindId(for: "training_spot", on: app.db).wait(),
			state: .published,
			creatorId: user.requireID()
		)
		try createPlacemark(publishedPlacemark, on: app.db).wait()
		deletePlacemarkAfterTestFinishes(publishedPlacemark, on: app.db)
		
		try app.test(
			.GET, "placemarks/v1") { res in
			try res.assertStatus(.ok) {
				let page = try res.content.decode(Page<GEOSwift.Feature>.self)
				let placemarks = page.items
				
				XCTAssertEqual(placemarks.count, 1)
				guard let placemarkResponse = placemarks.first else {
					XCTFail("Response does not contain a Placemark")
					return
				}
				
				try XCTAssertEqual(placemarkResponse.id, .string(publishedPlacemark.requireID().uuidString))
			}
		}
	}
	
	/// Tests `GET /placemarks/v1?state=submitted`.
	///
	/// - GIVEN:
	///     - A submitted placemark
	///     - A published placemark
	/// - WHEN:
	///     - Fetching all submitted placemarks (paginated)
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be a paginated array containing only the submitted placemark
	func testListSubmittedReturnsTheListOfSubmittedPlacemarks() throws {
		let app = try XCTUnwrap(Self.app)
		let user = try XCTUnwrap(Self.user)
		
		// Create submitted placemark
		let submittedPlacemark = try PlacemarkModel.dummy(
			kindId: kindId(for: "training_spot", on: app.db).wait(),
			state: .submitted,
			creatorId: user.requireID()
		)
		try createPlacemark(submittedPlacemark, on: app.db).wait()
		deletePlacemarkAfterTestFinishes(submittedPlacemark, on: app.db)
		
		// Create published placemark
		let publishedPlacemark = try PlacemarkModel.dummy(
			kindId: kindId(for: "training_spot", on: app.db).wait(),
			state: .published,
			creatorId: user.requireID()
		)
		try createPlacemark(publishedPlacemark, on: app.db).wait()
		deletePlacemarkAfterTestFinishes(publishedPlacemark, on: app.db)
		
		try app.test(
			.GET, "placemarks/v1?state=submitted") { res in
			try res.assertStatus(.ok) {
				let page = try res.content.decode(Page<GEOSwift.Feature>.self)
				let placemarks = page.items
				
				XCTAssertEqual(placemarks.count, 1)
				guard let placemarkResponse = placemarks.first else {
					XCTFail("Response does not contain a Placemark")
					return
				}
				
				try XCTAssertEqual(placemarkResponse.id, .string(submittedPlacemark.requireID().uuidString))
			}
		}
	}
	
	/// Tests `GET /placemarks/v1?state=submitted` when unauthorized.
	///
	/// - GIVEN:
	///     - Nothing
	/// - WHEN:
	///     - Fetching all submitted placemarks
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	func testListSubmittedPlacemarks_Unauthorized() throws {
		let app = try XCTUnwrap(Self.app)
		
		try app.test(.GET, "placemarks/v1?state=submitted") { res in
			try res.assertStatus(.ok) {}
		}
	}
	
	/// Tests `GET /placemarks/v1?state=submitted` when authorized.
	///
	/// - GIVEN:
	///     - A user
	/// - WHEN:
	///     - Fetching all submitted placemarks
	///     - Logged in as the user
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	func testListSubmittedPlacemarks_Authorized() throws {
		let app = try XCTUnwrap(Self.app)
		let userToken = try XCTUnwrap(Self.userToken)
		
		try app.test(
			.GET, "placemarks/v1?state=submitted",
			beforeRequest: { req in
				let bearerAuth = BearerAuthorization(token: userToken.value)
				req.headers.bearerAuthorization = bearerAuth
			},
			afterResponse: { res in
				try res.assertStatus(.ok) {}
			}
		)
	}
	
	/// Tests `GET /placemarks/v1?state=private` when authorized.
	///
	/// - GIVEN:
	///     - A user
	/// - WHEN:
	///     - Fetching all private placemarks
	///     - Logged in as the user
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	func testListPrivatePlacemarks_Authorized() throws {
		let app = try XCTUnwrap(Self.app)
		let userToken = try XCTUnwrap(Self.userToken)
		
		try app.test(
			.GET, "placemarks/v1?state=private",
			beforeRequest: { req in
				let bearerAuth = BearerAuthorization(token: userToken.value)
				req.headers.bearerAuthorization = bearerAuth
			},
			afterResponse: { res in
				try res.assertStatus(.ok) {}
			}
		)
	}
	
	/// Creates a new spot
	/// Checks if status is 200 OK with placemark data
	/// And then checks if spot is actually stored on DB by fetching it
	func testPostCreatesPlacemark() throws { // swiftlint:disable:this function_body_length
		let app = try XCTUnwrap(Self.app)
		let user = try XCTUnwrap(Self.user)
		let userToken = try XCTUnwrap(Self.userToken)
		
		// Create placemark
		let create = Placemark.Create(
			name: "Test name",
			latitude: Double.random(in: -90...90),
			longitude: Double.random(in: -180...180),
			kind: .trainingSpot,
			caption: "Test caption",
			images: nil,
			properties: [
				.feature: ["small_wall", "medium_wall"],
				.technique: ["double_kong"],
				.benefit: ["covered_area"],
				.hazard: ["high_drop"],
			]
		)
		// Delete possibly created placemark
		deletePossiblyCreatedPlacemarkAfterTestFinishes(name: create.name, on: app.db)
		
		try app.test(
			.POST, "placemarks/v1",
			beforeRequest: { req in
				let bearerAuth = BearerAuthorization(token: userToken.value)
				req.headers.bearerAuthorization = bearerAuth
				
				try req.content.encode(create)
			},
			afterResponse: { res in
				XCTAssertFalse(
					res.status == .internalServerError
						&& res.body.string.contains("RedisConnectionPoolError"),
					"Redis not started"
				)
				try res.assertStatus(.created) {
					let placemark = try res.content.decode(GEOSwift.Feature.self)
					
					let data = try placemark.properties.require()
					XCTAssertEqual(data["name"], .string(create.name))
					let geometry = try placemark.geometry.require()
					guard case let .point(point) = geometry else {
						return XCTFail("Invalid type for '\(geometry)'")
					}
					XCTAssertTrue(point.x.distance(to: create.latitude) < 0.001)
					XCTAssertTrue(point.y.distance(to: create.longitude) < 0.001)
					XCTAssertEqual(data["creator"], try .string(user.requireID().uuidString))
					XCTAssertEqual(data["state"], .string(Placemark.State.private.rawValue))
					XCTAssertEqual(data["kind"], .string(Placemark.Kind.trainingSpot.rawValue))
					XCTAssertEqual(data["category"], .string(Placemark.Category.spot.rawValue))
					guard case let .object(details) = data["details"] else {
						return XCTFail("Invalid type for '\(data["details"] ?? "nil")'")
					}
					XCTAssertEqual(details["caption"], .string(create.caption))
					XCTAssertEqual(details["images"], .array([]))
					guard case let .object(properties) = details["properties"] else {
						return XCTFail("Invalid type for '\(details["properties"] ?? "nil")'")
					}
					let expectedPropertiesCount = [
						"feature": 2,
						"technique": 1,
						"benefit": 1,
						"hazard": 1,
					]
					for (key, count) in expectedPropertiesCount {
						guard case let .array(array) = properties[key] else {
							return XCTFail("Invalid type for '\(properties[key] ?? "nil")'")
						}
						XCTAssertEqual(array.count, count)
					}
					XCTAssertNotNil(details["satelliteImage"])
					XCTAssertEqual(details["location"], .null)
					XCTAssertNotNil(data["createdAt"])
					XCTAssertNotNil(data["updatedAt"])
					
					// Test creation on DB
					guard case let .string(id) = placemark.id else {
						return XCTFail("Invalid type for '\(placemark.id ?? "nil")'")
					}
					let uuid = try UUID(uuidString: id).require()
					let storedPlacemark = try PlacemarkModel.find(uuid, on: app.db).wait()
					XCTAssertNotNil(storedPlacemark)
				}
			}
		)
	}
	
	/// Tests `GET /placemarks/v1/{placemarkId}`.
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
		let placemark = try PlacemarkModel.dummy(
			id: placemarkId,
			kindId: kindId(for: "training_spot", on: app.db).wait(),
			creatorId: user.requireID()
		)
		try createPlacemark(placemark, on: app.db).wait()
		deletePlacemarkAfterTestFinishes(placemark, on: app.db)
		
		try app.test(
			.GET, "placemarks/v1/\(placemarkId)") { res in
			try res.assertStatus(.ok) {
				let placemarkResponse = try res.content.decode(GEOSwift.Feature.self)
				try XCTAssertEqual(placemarkResponse.id, .string(placemark.id.require().uuidString))
			}
		}
	}
	
	/// Tests `DELETE /placemarks/v1/{placemarkId}`.
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
		let placemark = try PlacemarkModel.dummy(
			id: placemarkId,
			kindId: kindId(for: "training_spot", on: app.db).wait(),
			creatorId: user.requireID()
		)
		try placemark.create(on: app.db).wait()
		deletePlacemarkAfterTestFinishes(placemark, on: app.db)
		
		try app.test(
			.DELETE, "placemarks/v1/\(placemarkId)",
			beforeRequest: { req in
				let bearerAuth = BearerAuthorization(token: userToken.value)
				req.headers.bearerAuthorization = bearerAuth
			},
			afterResponse: { res in
				try res.assertStatus(.noContent) {
					XCTAssertEqual(res.body.string, "")
				}
			}
		)
	}
	
	/// Tests `GET /placemarks/v1/features`.
	///
	/// - GIVEN:
	///     - Nothing
	/// - WHEN:
	///     - Listing all placemark features
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be an array containing all possible placemark features
	func testGetFeatures() throws {
		let app = try XCTUnwrap(Self.app)
		
		try app.test(
			.GET, "placemarks/v1/features") { res in
			try res.assertStatus(.ok) {
				let features = try res.content.decode([Placemark.Property.Localized].self)
				XCTAssertEqual(features.count, 31)
			}
		}
	}
	
	/// Tests `GET /placemarks/v1/techniques`.
	///
	/// - GIVEN:
	///     - Nothing
	/// - WHEN:
	///     - Listing all placemark techniques
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be an array containing all possible placemark techniques
	func testGetTechniques() throws {
		let app = try XCTUnwrap(Self.app)
		
		try app.test(
			.GET, "placemarks/v1/techniques") { res in
			try res.assertStatus(.ok) {
				let features = try res.content.decode([Placemark.Property.Localized].self)
				XCTAssertEqual(features.count, 12)
			}
		}
	}
	
	/// Tests `GET /placemarks/v1/benefits`.
	///
	/// - GIVEN:
	///     - Nothing
	/// - WHEN:
	///     - Listing all placemark benefits
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be an array containing all possible placemark benefits
	func testGetBenefits() throws {
		let app = try XCTUnwrap(Self.app)
		
		try app.test(
			.GET, "placemarks/v1/benefits") { res in
			try res.assertStatus(.ok) {
				let features = try res.content.decode([Placemark.Property.Localized].self)
				XCTAssertEqual(features.count, 8)
			}
		}
	}
	
	/// Tests `GET /placemarks/v1/hazards`.
	///
	/// - GIVEN:
	///     - Nothing
	/// - WHEN:
	///     - Listing all placemark hazards
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be an array containing all possible placemark hazards
	func testGetHazards() throws {
		let app = try XCTUnwrap(Self.app)
		
		try app.test(
			.GET, "placemarks/v1/hazards") { res in
			try res.assertStatus(.ok) {
				let features = try res.content.decode([Placemark.Property.Localized].self)
				XCTAssertEqual(features.count, 8)
			}
		}
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
			kind: .trainingSpot,
			caption: "Test caption",
			images: nil,
			properties: [:]
		)
		// Delete possibly created placemark
		deletePossiblyCreatedPlacemarkAfterTestFinishes(name: create.name, on: app.db)
		
		try app.test(
			.POST, "placemarks/v1",
			beforeRequest: { req in
				let bearerAuth = BearerAuthorization(token: userToken.value)
				req.headers.bearerAuthorization = bearerAuth
				
				try req.content.encode(create)
			},
			afterResponse: { res in
				try res.assertError(
					status: .badRequest,
					reason: "name is less than minimum of 3 character(s)"
				)
			}
		)
	}
	
	/// Tries to create a placemark with an invalid property ID.
	///
	/// - GIVEN:
	///     - A user
	/// - WHEN:
	///     - Creating a placemark with an invalid property ID
	/// - THEN:
	///     - `HTTP` status should be `400 Bad Request`
	///     - `body` should be `"Invalid property: { "kind": "feature", "id": "123" }"`
	func testCreateSpotWithInvalidProperty() throws {
		let app = try XCTUnwrap(Self.app)
		let userToken = try XCTUnwrap(Self.userToken)
		
		// Create placemark
		let create = Placemark.Create(
			name: "Test name",
			latitude: Double.random(in: -90...90),
			longitude: Double.random(in: -180...180),
			kind: .trainingSpot,
			caption: "Test caption",
			images: nil,
			properties: [
				.feature: ["123"],
			]
		)
		// Delete possibly created placemark
		deletePossiblyCreatedPlacemarkAfterTestFinishes(name: create.name, on: app.db)
		
		try app.test(
			.POST, "placemarks/v1",
			beforeRequest: { req in
				let bearerAuth = BearerAuthorization(token: userToken.value)
				req.headers.bearerAuthorization = bearerAuth
				
				try req.content.encode(create)
			},
			afterResponse: { res in
				try res.assertError(
					status: .badRequest,
					reason: "Invalid property: { \"kind\": \"feature\", \"id\": \"123\" }"
				)
			}
		)
	}
	
	/// Tests `GET /placemarks/v1?state=private` when unauthorized.
	///
	/// - GIVEN:
	///     - Nothing
	/// - WHEN:
	///     - Fetching all private placemarks
	/// - THEN:
	///     - `HTTP` status should be `401 Unauthorized`
	///     - `body` should be `"Unauthorized"`
	func testListPrivatePlacemarks_Unauthorized() throws {
		let app = try XCTUnwrap(Self.app)
		
		try app.test(.GET, "placemarks/v1?state=private") { res in
			try res.assertError(status: .unauthorized, reason: "Unauthorized")
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
		
		try app.test(
			.GET, "placemarks/v1/\(UUID())") { res in
			try res.assertError(status: .notFound, reason: "Placemark not found")
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
	///     - `body` should be `"Invalid authorization token."`
	func testCreatePlacemarkInvalidBearerToken() throws {
		let app = try XCTUnwrap(Self.app)
		
		try app.test(
			.POST, "placemarks/v1",
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
	
	/// Tries to delete someone else's placemark.
	///
	/// - GIVEN:
	///     - Two users
	///     - A placemark from user 1
	/// - WHEN:
	///     - User 2 tries to delete the placemark
	/// - THEN:
	///     - `HTTP` status should be `403 Forbidden`
	///     - `body` should be `"You cannot delete someone else's placemark!"`
	func testDeleteSomeoneElsesPlacemark() throws {
		let app = try XCTUnwrap(Self.app)
		let userToken = try XCTUnwrap(Self.userToken)
		
		// Create other user
		let otherUser = UserModel.dummy()
		try otherUser.create(on: app.db).wait()
		deleteUserAfterTestFinishes(otherUser, on: app.db)
		
		// Create placemark
		let placemarkId = UUID()
		let placemark = try PlacemarkModel.dummy(
			id: placemarkId,
			kindId: kindId(for: "training_spot", on: app.db).wait(),
			creatorId: otherUser.requireID()
		)
		try placemark.create(on: app.db).wait()
		deletePlacemarkAfterTestFinishes(placemark, on: app.db)
		
		try app.test(
			.DELETE, "placemarks/v1/\(placemarkId)",
			beforeRequest: { req in
				let bearerAuth = BearerAuthorization(token: userToken.value)
				req.headers.bearerAuthorization = bearerAuth
			},
			afterResponse: { res in
				try res.assertError(
					status: .forbidden,
					reason: "You cannot delete someone else's placemark!"
				)
			}
		)
	}
	
}
// swiftlint:enable closure_body_length
