//
//  DeleteAfterTests.swift
//  AppTests
//
//  Created by Rémi Bardon on 12/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

@testable import App
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
	
	/// Adds a `tearDown` block that deletes the given `PlacemarkModel` after the current test finishes.
	///
	/// - Parameters:
	///   - placemark: The `PlacemarkModel` to delete
	///
	/// # Notes: #
	/// 1. Forces deletion
	///
	/// # Example #
	/// ```
	/// // Create placemark
	/// let placemark = try PlacemarkModel(
	/// 	name: "test_title",
	/// 	latitude: Double.random(in: -90...90),
	/// 	longitude: Double.random(in: -180...180),
	/// 	kindId: kindId(for: "training_spot", on: app.db).wait(),
	/// 	creatorId: user.requireID(),
	/// 	caption: "Test caption"
	/// )
	/// try placemark.create(on: app.db).wait()
	/// deletePlacemarkAfterTestFinishes(placemark, on: app.db)
	/// ```
	func deletePlacemarkAfterTestFinishes(_ placemark: PlacemarkModel?, on database: Database) {
		addTeardownBlock {
			do {
				try placemark?.delete(force: true, on: database).wait()
			} catch {
				XCTFail(error.localizedDescription)
			}
		}
	}
	
	/// Adds a `tearDown` block that deletes the `PlacemarkModel` with the given `name`
	/// after the current test finishes.
	///
	/// Does nothing if no `PlacemarkModel` has the given `username`.
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
	/// deletePossiblyCreatedPlacemarkAfterTestFinishes(name: placemark.name, on: app.db)
	/// ```
	func deletePossiblyCreatedPlacemarkAfterTestFinishes(name: String, on database: Database) {
		addTeardownBlock {
			do {
				try PlacemarkModel.query(on: database)
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
