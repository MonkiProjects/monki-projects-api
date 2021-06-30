//
//  DeleteAfterTests.swift
//  MonkiProjectsAPITests
//
//  Created by Rémi Bardon on 12/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

@testable import MonkiProjectsAPI
import XCTVapor
import Fluent

extension XCTestCase {
	
	/// Adds a `tearDown` block that deletes the given `UserModel` after the current test finishes.
	///
	/// - Parameters:
	///   - user: The `UserModel` to delete
	///
	/// # Notes: #
	/// 1. Forces deletion
	///
	/// # Example #
	/// ```
	/// try user.create(on: app.db).wait()
	/// deleteUserAfterTestFinishes(user, on: app.db)
	/// ```
	func deleteUserAfterTestFinishes(_ user: UserModel?, on database: Database) {
		addTeardownBlock {
			do {
				try user?.delete(force: true, on: database).wait()
			} catch {
				XCTFail(error.localizedDescription)
			}
		}
	}
	
	/// Adds a `tearDown` block that deletes the given `UserModel.Token` after the current test finishes.
	///
	/// - Parameters:
	///   - userToken: The `UserModel.Token` to delete
	///
	/// # Notes: #
	/// 1. Forces deletion
	///
	/// # Example #
	/// ```
	/// try userToken.create(on: app.db).wait()
	/// deleteUserTokenAfterTestFinishes(userToken, on: app.db)
	/// ```
	func deleteUserTokenAfterTestFinishes(_ userToken: UserModel.Token?, on database: Database) {
		addTeardownBlock {
			do {
				try userToken?.delete(force: true, on: database).wait()
			} catch {
				XCTFail(error.localizedDescription)
			}
		}
	}
	
	/// Adds a `tearDown` block that deletes the `UserModel` with the given `username`
	/// after the current test finishes.
	///
	/// Does nothing if no `UserModel` has the given `username`.
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
	/// deletePossiblyCreatedUserAfterTestFinishes(username: user.username, on: app.db)
	/// ```
	func deletePossiblyCreatedUserAfterTestFinishes(username: String, on database: Database) {
		addTeardownBlock {
			do {
				let storedUser = try UserModel.query(on: database)
					.filter(\.$username == username)
					.first()
					.wait()
				try storedUser?.delete(force: true, on: database).wait()
			} catch {
				XCTFail(error.localizedDescription)
			}
		}
	}
	
	/// Adds a `tearDown` block that deletes the given `PlaceModel` after the current test finishes.
	///
	/// - Parameters:
	///   - place: The `PlaceModel` to delete
	///
	/// # Notes: #
	/// 1. Forces deletion
	///
	/// # Example #
	/// ```
	/// // Create place
	/// let place = try PlaceModel(
	/// 	name: "test_title",
	/// 	latitude: Double.random(in: -90...90),
	/// 	longitude: Double.random(in: -180...180),
	/// 	kindId: kindId(for: "training_spot", on: app.db).wait(),
	/// 	creatorId: user.requireID(),
	/// 	caption: "Test caption"
	/// )
	/// try place.create(on: app.db).wait()
	/// deletePlaceAfterTestFinishes(place, on: app.db)
	/// ```
	func deletePlaceAfterTestFinishes(_ place: PlaceModel?, on database: Database) {
		addTeardownBlock {
			do {
				try place?.delete(force: true, on: database).wait()
			} catch {
				XCTFail(error.localizedDescription)
			}
		}
	}
	
	/// Adds a `tearDown` block that deletes the `PlaceModel` with the given `name`
	/// after the current test finishes.
	///
	/// Does nothing if no `PlaceModel` has the given `username`.
	///
	/// - Parameters:
	///   - name: The places's `name`
	///
	/// # Notes: #
	/// 1. Forces deletion
	///
	/// # Example #
	/// ```
	/// // Delete possibly created place
	/// deletePossiblyCreatedPlaceAfterTestFinishes(name: place.name, on: app.db)
	/// ```
	func deletePossiblyCreatedPlaceAfterTestFinishes(name: String, on database: Database) {
		addTeardownBlock {
			do {
				try PlaceModel.query(on: database)
					.filter(\.$name == name)
					.first()
					.optionalMap { $0.delete(force: true, on: database) }
					.transform(to: ())
					.wait()
			} catch {
				XCTFail(error.localizedDescription)
			}
		}
	}
	
}
