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

final class PlacemarkControllerTests: AppTestCase {
	
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
			try res.assertStatus(.ok) {
				XCTAssertEqual(res.body.string, "[]")
			}
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
		let submittedPlacemark = try PlacemarkModel.dummy(
			kindId: kindId(for: "training_spot", on: app.db).wait(),
			creatorId: user.requireID()
		)
		try submittedPlacemark.create(on: app.db).wait()
		deletePlacemarkAfterTestFinishes(submittedPlacemark, on: app.db)
		
		// Create published placemark
		let publishedPlacemark = try PlacemarkModel.dummy(
			kindId: kindId(for: "training_spot", on: app.db).wait(),
			state: .published,
			creatorId: user.requireID()
		)
		try publishedPlacemark.create(on: app.db).wait()
		deletePlacemarkAfterTestFinishes(publishedPlacemark, on: app.db)
		
		try app.test(.GET, "v1/placemarks") { res in
			try res.assertStatus(.ok) {
				let placemarks = try res.content.decode([Placemark.Public].self)
				
				XCTAssertEqual(placemarks.count, 1)
				guard let placemarkResponse = placemarks.first else {
					XCTFail("Response does not contain a Placemark")
					return
				}
				
				XCTAssertEqual(placemarkResponse.id, publishedPlacemark.id)
			}
		}
	}
	
	/// Tests `GET /v1/placemarks?state=submitted`.
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
		let submittedPlacemark = try PlacemarkModel.dummy(
			kindId: kindId(for: "training_spot", on: app.db).wait(),
			state: .submitted,
			creatorId: user.requireID()
		)
		try submittedPlacemark.create(on: app.db).wait()
		deletePlacemarkAfterTestFinishes(submittedPlacemark, on: app.db)
		
		// Create published placemark
		let publishedPlacemark = try PlacemarkModel.dummy(
			kindId: kindId(for: "training_spot", on: app.db).wait(),
			state: .published,
			creatorId: user.requireID()
		)
		try publishedPlacemark.create(on: app.db).wait()
		deletePlacemarkAfterTestFinishes(publishedPlacemark, on: app.db)
		
		try app.test(.GET, "v1/placemarks?state=submitted") { res in
			try res.assertStatus(.ok) {
				let placemarks = try res.content.decode([Placemark.Public].self)
				
				XCTAssertEqual(placemarks.count, 1)
				guard let placemarkResponse = placemarks.first else {
					XCTFail("Response does not contain a Placemark")
					return
				}
				
				XCTAssertEqual(placemarkResponse.id, submittedPlacemark.id)
			}
		}
	}
	
	/// Creates a new spot
	/// Checks if status is 200 OK with placemark data
	/// And then checks if spot is actually stored on DB by fetching it
	func testPostSubmitsPlacemark() throws { // swiftlint:disable:this function_body_length
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
			features: nil,
			goodForTraining: nil,
			benefits: nil,
			hazards: nil
		)
		// Delete possibly created placemark
		deletePossiblyCreatedPlacemarkAfterTestFinishes(name: create.name, on: app.db)
		
		try app.test(.POST, "v1/placemarks",
			beforeRequest: { req in
				let bearerAuth = BearerAuthorization(token: userToken.value)
				req.headers.bearerAuthorization = bearerAuth
				
				try req.content.encode(create)
			},
			afterResponse: { res in
				try res.assertStatus(.created) {
					let placemark = try res.content.decode(Placemark.Public.self)
					
					XCTAssertEqual(placemark.name, create.name)
					XCTAssertEqual(placemark.latitude, create.latitude)
					XCTAssertEqual(placemark.longitude, create.longitude)
					XCTAssertEqual(placemark.creator, try user.requireID())
					XCTAssertEqual(placemark.state, .private)
					XCTAssertEqual(placemark.kind, .trainingSpot)
					XCTAssertEqual(placemark.category, .spot)
					XCTAssertNotNil(placemark.createdAt)
					XCTAssertNotNil(placemark.updatedAt)
					
					// Test creation on DB
					let storedPlacemark = try PlacemarkModel.find(placemark.id, on: app.db).wait()
					XCTAssertNotNil(storedPlacemark)
				}
			}
		)
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
		let placemark = try PlacemarkModel.dummy(
			id: placemarkId,
			kindId: kindId(for: "training_spot", on: app.db).wait(),
			creatorId: user.requireID()
		)
		try placemark.create(on: app.db).wait()
		deletePlacemarkAfterTestFinishes(placemark, on: app.db)
		
		try app.test(.GET, "v1/placemarks/\(placemarkId)") { res in
			try res.assertStatus(.ok) {
				let placemarkResponse = try res.content.decode(Placemark.Public.self)
				XCTAssertEqual(placemarkResponse.id, placemark.id)
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
		let placemark = try PlacemarkModel.dummy(
			id: placemarkId,
			kindId: kindId(for: "training_spot", on: app.db).wait(),
			creatorId: user.requireID()
		)
		try placemark.create(on: app.db).wait()
		deletePlacemarkAfterTestFinishes(placemark, on: app.db)
		
		try app.test(.DELETE, "v1/placemarks/\(placemarkId)",
			beforeRequest: { req in
				let bearerAuth = BearerAuthorization(token: userToken.value)
				req.headers.bearerAuthorization = bearerAuth
			},
			afterResponse: { res in
				try res.assertStatus(.ok) {
					XCTAssertEqual(res.body.string, "")
				}
			}
		)
	}
	
	/// Tests `GET /v1/placemarks/features`.
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
		
		try app.test(.GET, "v1/placemarks/features") { res in
			try res.assertStatus(.ok) {
				let features = try res.content.decode([Placemark.Property.Localized].self)
				XCTAssertEqual(features.count, 31)
			}
		}
	}
	
	/// Tests `GET /v1/placemarks/techniques`.
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
		
		try app.test(.GET, "v1/placemarks/techniques") { res in
			try res.assertStatus(.ok) {
				let features = try res.content.decode([Placemark.Property.Localized].self)
				XCTAssertEqual(features.count, 12)
			}
		}
	}
	
	/// Tests `GET /v1/placemarks/benefits`.
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
		
		try app.test(.GET, "v1/placemarks/benefits") { res in
			try res.assertStatus(.ok) {
				let features = try res.content.decode([Placemark.Property.Localized].self)
				XCTAssertEqual(features.count, 8)
			}
		}
	}
	
	/// Tests `GET /v1/placemarks/hazards`.
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
		
		try app.test(.GET, "v1/placemarks/hazards") { res in
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
			features: nil,
			goodForTraining: nil,
			benefits: nil,
			hazards: nil
		)
		// Delete possibly created placemark
		deletePossiblyCreatedPlacemarkAfterTestFinishes(name: create.name, on: app.db)
		
		try app.test(.POST, "v1/placemarks",
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
	///     - `body` should be `"Unauthorized"`
	func testCreatePlacemarkInvalidBearerToken() throws {
		let app = try XCTUnwrap(Self.app)
		
		try app.test(.POST, "v1/placemarks",
			beforeRequest: { req in
				let invalidToken = [UInt8].random(count: 16).base64
				let bearerAuth = BearerAuthorization(token: invalidToken)
				req.headers.bearerAuthorization = bearerAuth
			},
			afterResponse: { res in
				try res.assertError(status: .unauthorized, reason: "Unauthorized")
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
		
		try app.test(.DELETE, "v1/placemarks/\(placemarkId)",
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
