//
//  PlaceControllerV1Tests.swift
//  PlacesAPITests
//
//  Created by BARDON Rémi on 24/06/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

@testable import MonkiProjectsAPI
import XCTVapor
import Fluent

// swiftlint:disable closure_body_length
internal final class PlaceControllerV1Tests: AppTestCase {
	
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
	
	/// Tests that the `"places"` schema exists.
	///
	/// - GIVEN:
	///     - The empty database
	/// - WHEN:
	///     - Fetching all places (paginated)
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be an empty paginated array
	///
	/// # Notes: #
	/// 1. Route will trigger a fatalError if the `"places"` schema doesn't exist
	/// 2. If it works properly, then it means that the schema is ready
	func testSchemaExists() throws {
		let app = try XCTUnwrap(Self.app)
		
		try app.test(.GET, "places/v1") { res in
			try res.assertStatus(.ok) {
				let page = try res.content.decode(Page<Place.Public>.self)
				let places = page.items
				
				XCTAssertEqual(places.count, 0)
				XCTAssertEqual(page.metadata.total, 0)
			}
		}
	}
	
	/// Tests `GET /places/v1`.
	///
	/// - GIVEN:
	///     - A submitted place
	///     - A published place
	/// - WHEN:
	///     - Fetching all published places (paginated)
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be a paginated array containing only the published place
	func testIndexReturnsTheListOfPublishedPlaces() throws {
		let app = try XCTUnwrap(Self.app)
		let user = try XCTUnwrap(Self.user)
		
		// Create submitted place
		let submittedPlace = try PlaceModel.dummy(
			kindId: kindId(for: "training_spot", on: app.db).wait(),
			creatorId: user.requireID()
		)
		try createPlace(submittedPlace, on: app.db).wait()
		deletePlaceAfterTestFinishes(submittedPlace, on: app.db)
		
		// Create published place
		let publishedPlace = try PlaceModel.dummy(
			kindId: kindId(for: "training_spot", on: app.db).wait(),
			state: .published,
			creatorId: user.requireID()
		)
		try createPlace(publishedPlace, on: app.db).wait()
		deletePlaceAfterTestFinishes(publishedPlace, on: app.db)
		
		try app.test(
			.GET, "places/v1") { res in
			try res.assertStatus(.ok) {
				let page = try res.content.decode(Page<Place.Public>.self)
				let places = page.items
				
				XCTAssertEqual(places.count, 1)
				guard let placeResponse = places.first else {
					XCTFail("Response does not contain a Place")
					return
				}
				
				try XCTAssertEqual(placeResponse.id, publishedPlace.requireID())
			}
		}
	}
	
	/// Tests `GET /places/v1?state=submitted`.
	///
	/// - GIVEN:
	///     - A submitted place
	///     - A published place
	/// - WHEN:
	///     - Fetching all submitted places (paginated)
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be a paginated array containing only the submitted place
	func testListSubmittedReturnsTheListOfSubmittedPlaces() throws {
		let app = try XCTUnwrap(Self.app)
		let user = try XCTUnwrap(Self.user)
		
		// Create submitted place
		let submittedPlace = try PlaceModel.dummy(
			kindId: kindId(for: "training_spot", on: app.db).wait(),
			state: .submitted,
			creatorId: user.requireID()
		)
		try createPlace(submittedPlace, on: app.db).wait()
		deletePlaceAfterTestFinishes(submittedPlace, on: app.db)
		
		// Create published place
		let publishedPlace = try PlaceModel.dummy(
			kindId: kindId(for: "training_spot", on: app.db).wait(),
			state: .published,
			creatorId: user.requireID()
		)
		try createPlace(publishedPlace, on: app.db).wait()
		deletePlaceAfterTestFinishes(publishedPlace, on: app.db)
		
		try app.test(
			.GET, "places/v1?state=submitted") { res in
			try res.assertStatus(.ok) {
				let page = try res.content.decode(Page<Place.Public>.self)
				let places = page.items
				
				XCTAssertEqual(places.count, 1)
				guard let placeResponse = places.first else {
					XCTFail("Response does not contain a Place")
					return
				}
				
				try XCTAssertEqual(placeResponse.id, submittedPlace.requireID())
			}
		}
	}
	
	/// Tests `GET /places/v1?state=submitted` when unauthorized.
	///
	/// - GIVEN:
	///     - Nothing
	/// - WHEN:
	///     - Fetching all submitted places
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	func testListSubmittedPlaces_Unauthorized() throws {
		let app = try XCTUnwrap(Self.app)
		
		try app.test(.GET, "places/v1?state=submitted") { res in
			try res.assertStatus(.ok) {}
		}
	}
	
	/// Tests `GET /places/v1?state=submitted` when authorized.
	///
	/// - GIVEN:
	///     - A user
	/// - WHEN:
	///     - Fetching all submitted places
	///     - Logged in as the user
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	func testListSubmittedPlaces_Authorized() throws {
		let app = try XCTUnwrap(Self.app)
		let userToken = try XCTUnwrap(Self.userToken)
		
		try app.test(
			.GET, "places/v1?state=submitted",
			beforeRequest: { req in
				let bearerAuth = BearerAuthorization(token: userToken.value)
				req.headers.bearerAuthorization = bearerAuth
			},
			afterResponse: { res in
				try res.assertStatus(.ok) {}
			}
		)
	}
	
	/// Tests `GET /places/v1?state=private` when authorized.
	///
	/// - GIVEN:
	///     - A user
	/// - WHEN:
	///     - Fetching all private places
	///     - Logged in as the user
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	func testListPrivatePlaces_Authorized() throws {
		let app = try XCTUnwrap(Self.app)
		let userToken = try XCTUnwrap(Self.userToken)
		
		try app.test(
			.GET, "places/v1?state=private",
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
	/// Checks if status is 200 OK with place data
	/// And then checks if spot is actually stored on DB by fetching it
	func testPostCreatesPlace() throws { // swiftlint:disable:this function_body_length
		let app = try XCTUnwrap(Self.app)
		let user = try XCTUnwrap(Self.user)
		let userToken = try XCTUnwrap(Self.userToken)
		
		// Create place
		let create = Place.Create(
			name: "Test name",
			latitude: Double.random(in: -90...90),
			longitude: Double.random(in: -180...180),
			kind: .trainingSpot,
			caption: "Test caption",
			images: [],
			properties: [
				.feature("small_wall"),
				.feature("medium_wall"),
				.technique("double_kong"),
				.benefit("covered_area"),
				.hazard("high_drop"),
			]
		)
		// Delete possibly created place
		deletePossiblyCreatedPlaceAfterTestFinishes(name: create.name, on: app.db)
		
		try app.test(
			.POST, "places/v1",
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
					let place = try res.content.decode(Place.Public.self)
					
					XCTAssertEqual(place.name, create.name)
					XCTAssertTrue(place.latitude.distance(to: create.latitude) < 0.001)
					XCTAssertTrue(place.longitude.distance(to: create.longitude) < 0.001)
					XCTAssertEqual(place.creator, try user.requireID())
					XCTAssertEqual(place.state, .private)
					XCTAssertEqual(place.kind, .trainingSpot)
					XCTAssertEqual(place.category, .spot)
					XCTAssertEqual(place.details.caption, create.caption)
					XCTAssertEqual(place.details.images, [])
					XCTAssertEqual(place.details.properties.count, 5)
					XCTAssertNotNil(place.details.satelliteImage)
					XCTAssertNil(place.details.location)
					XCTAssertNotNil(place.createdAt)
					XCTAssertNotNil(place.updatedAt)
					
					// Test creation on DB
					let storedPlace = try PlaceModel.find(place.id, on: app.db).wait()
					XCTAssertNotNil(storedPlace)
				}
			}
		)
	}
	
	/// Tests `GET /places/v1/{placeId}`.
	///
	/// - GIVEN:
	///     - A place
	/// - WHEN:
	///     - Getting details of the place
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be the placemrk's details
	func testGetPlaceDetails() throws {
		let app = try XCTUnwrap(Self.app)
		let user = try XCTUnwrap(Self.user)
		
		// Create submitted place
		let placeId = Place.ID()
		let place = try PlaceModel.dummy(
			id: placeId,
			kindId: kindId(for: "training_spot", on: app.db).wait(),
			creatorId: user.requireID()
		)
		try createPlace(place, on: app.db).wait()
		deletePlaceAfterTestFinishes(place, on: app.db)
		
		try app.test(
			.GET, "places/v1/\(placeId)") { res in
			try res.assertStatus(.ok) {
				let placeResponse = try res.content.decode(Place.Public.self)
				try XCTAssertEqual(placeResponse.id, place.id.require())
			}
		}
	}
	
	/// Tests `DELETE /places/v1/{placeId}`.
	///
	/// - GIVEN:
	///     - A place
	/// - WHEN:
	///     - Deleting the place
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be empty
	func testDeletePlace() throws {
		let app = try XCTUnwrap(Self.app)
		let user = try XCTUnwrap(Self.user)
		let userToken = try XCTUnwrap(Self.userToken)
		
		// Create submitted place
		let placeId = Place.ID()
		let place = try PlaceModel.dummy(
			id: placeId,
			kindId: kindId(for: "training_spot", on: app.db).wait(),
			creatorId: user.requireID()
		)
		try place.create(on: app.db).wait()
		deletePlaceAfterTestFinishes(place, on: app.db)
		
		try app.test(
			.DELETE, "places/v1/\(placeId)",
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
	
	/// Tests `GET /places/v1/features`.
	///
	/// - GIVEN:
	///     - Nothing
	/// - WHEN:
	///     - Listing all place features
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be an array containing all possible place features
	func testGetFeatures() throws {
		let app = try XCTUnwrap(Self.app)
		
		try app.test(.GET, "places/v1/properties?kind=feature") { res in
			try res.assertStatus(.ok) {
				let features = try res.content.decode([Place.Property.Localized].self)
				XCTAssertEqual(features.count, 31)
			}
		}
	}
	
	/// Tests `GET /places/v1/techniques`.
	///
	/// - GIVEN:
	///     - Nothing
	/// - WHEN:
	///     - Listing all place techniques
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be an array containing all possible place techniques
	func testGetTechniques() throws {
		let app = try XCTUnwrap(Self.app)
		
		try app.test(.GET, "places/v1/properties?kind=technique") { res in
			try res.assertStatus(.ok) {
				let features = try res.content.decode([Place.Property.Localized].self)
				XCTAssertEqual(features.count, 12)
			}
		}
	}
	
	/// Tests `GET /places/v1/benefits`.
	///
	/// - GIVEN:
	///     - Nothing
	/// - WHEN:
	///     - Listing all place benefits
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be an array containing all possible place benefits
	func testGetBenefits() throws {
		let app = try XCTUnwrap(Self.app)
		
		try app.test(.GET, "places/v1/properties?kind=benefit") { res in
			try res.assertStatus(.ok) {
				let features = try res.content.decode([Place.Property.Localized].self)
				XCTAssertEqual(features.count, 8)
			}
		}
	}
	
	/// Tests `GET /places/v1/hazards`.
	///
	/// - GIVEN:
	///     - Nothing
	/// - WHEN:
	///     - Listing all place hazards
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be an array containing all possible place hazards
	func testGetHazards() throws {
		let app = try XCTUnwrap(Self.app)
		
		try app.test(.GET, "places/v1/properties?kind=hazard") { res in
			try res.assertStatus(.ok) {
				let features = try res.content.decode([Place.Property.Localized].self)
				XCTAssertEqual(features.count, 8)
			}
		}
	}
	
	// MARK: - Invalid Domain
	
	/// Tries to create a place with a name of less than 3 characters.
	///
	/// - GIVEN:
	///     - Nothing
	/// - WHEN:
	///     - Creating a place with a name of less than 3 characters
	/// - THEN:
	///     - `HTTP` status should be `400 Bad Request`
	///     - `body` should be `"name is less than minimum of 3 character(s)"`
	func testCreateSpotWithTitleTooSmall() throws {
		let app = try XCTUnwrap(Self.app)
		let userToken = try XCTUnwrap(Self.userToken)
		
		// Create place
		let create = Place.Create(
			name: "12",
			latitude: Double.random(in: -90...90),
			longitude: Double.random(in: -180...180),
			kind: .trainingSpot,
			caption: "Test caption"
		)
		// Delete possibly created place
		deletePossiblyCreatedPlaceAfterTestFinishes(name: create.name, on: app.db)
		
		try app.test(
			.POST, "places/v1",
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
	
	/// Tries to create a place with an invalid property ID.
	///
	/// - GIVEN:
	///     - A user
	/// - WHEN:
	///     - Creating a place with an invalid property ID
	/// - THEN:
	///     - `HTTP` status should be `400 Bad Request`
	///     - `body` should be `"Invalid property: { "kind": "feature", "id": "123" }"`
	func testCreateSpotWithInvalidProperty() throws {
		let app = try XCTUnwrap(Self.app)
		let userToken = try XCTUnwrap(Self.userToken)
		
		// Create place
		let create = Place.Create(
			name: "Test name",
			latitude: Double.random(in: -90...90),
			longitude: Double.random(in: -180...180),
			kind: .trainingSpot,
			caption: "Test caption",
			properties: [.feature("123")]
		)
		// Delete possibly created place
		deletePossiblyCreatedPlaceAfterTestFinishes(name: create.name, on: app.db)
		
		try app.test(
			.POST, "places/v1",
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
	
	/// Tests `GET /places/v1?state=private` when unauthorized.
	///
	/// - GIVEN:
	///     - Nothing
	/// - WHEN:
	///     - Fetching all private places
	/// - THEN:
	///     - `HTTP` status should be `401 Unauthorized`
	///     - `body` should be `"Unauthorized"`
	func testListPrivatePlaces_Unauthorized() throws {
		let app = try XCTUnwrap(Self.app)
		
		try app.test(.GET, "places/v1?state=private") { res in
			try res.assertError(status: .unauthorized, reason: "Unauthorized")
			XCTAssertTrue(res.headers.contains(name: .wwwAuthenticate))
		}
	}
	
	/// Tries to get details for an inexistent place.
	///
	/// - GIVEN:
	///     - Nothing
	/// - WHEN:
	///     - Getting details for an inexistent place
	/// - THEN:
	///     - `HTTP` status should be `404 Not Found`
	///     - `body` should be `"Not Found"`
	func testGetPlaceWithInexistentId() throws {
		let app = try XCTUnwrap(Self.app)
		
		try app.test(
			.GET, "places/v1/\(Place.ID())") { res in
			try res.assertError(status: .notFound, reason: "Place not found")
		}
	}
	
	/// Tries to create a place with an invalid `Bearer` token.
	///
	/// - GIVEN:
	///     - A user
	/// - WHEN:
	///     - Creating a place with an invalid `Bearer` token
	/// - THEN:
	///     - `HTTP` status should be `401 Unauthorized`
	///     - `body` should be `"Invalid authorization token."`
	func testCreatePlaceInvalidBearerToken() throws {
		let app = try XCTUnwrap(Self.app)
		
		try app.test(
			.POST, "places/v1",
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
	
	/// Tries to delete someone else's place.
	///
	/// - GIVEN:
	///     - Two users
	///     - A place from user 1
	/// - WHEN:
	///     - User 2 tries to delete the place
	/// - THEN:
	///     - `HTTP` status should be `403 Forbidden`
	///     - `body` should be `"You cannot delete someone else's place!"`
	func testDeleteSomeoneElsesPlace() throws {
		let app = try XCTUnwrap(Self.app)
		let userToken = try XCTUnwrap(Self.userToken)
		
		// Create other user
		let otherUser = UserModel.dummy()
		try otherUser.create(on: app.db).wait()
		deleteUserAfterTestFinishes(otherUser, on: app.db)
		
		// Create place
		let placeId = Place.ID()
		let place = try PlaceModel.dummy(
			id: placeId,
			kindId: kindId(for: "training_spot", on: app.db).wait(),
			creatorId: otherUser.requireID()
		)
		try place.create(on: app.db).wait()
		deletePlaceAfterTestFinishes(place, on: app.db)
		
		try app.test(
			.DELETE, "places/v1/\(placeId)",
			beforeRequest: { req in
				let bearerAuth = BearerAuthorization(token: userToken.value)
				req.headers.bearerAuthorization = bearerAuth
			},
			afterResponse: { res in
				try res.assertError(
					status: .forbidden,
					reason: "You cannot delete someone else's place!"
				)
			}
		)
	}
	
}
// swiftlint:enable closure_body_length
