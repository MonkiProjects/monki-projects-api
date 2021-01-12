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
	/// deleteUserAfterTestFinishes(user, on: app.db)
	/// ```
	func deleteUserAfterTestFinishes(_ user: User?, on database: Database) {
		addTeardownBlock {
			do {
				try user?.delete(force: true, on: database).wait()
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
	/// deletePossiblyCreatedUserAfterTestFinishes(username: user.username, on: app.db)
	/// ```
	func deletePossiblyCreatedUserAfterTestFinishes(username: String, on database: Database) {
		addTeardownBlock {
			do {
				let storedUser = try User.query(on: database)
					.filter(\.$username == username).first()
					.wait()
				try storedUser?.delete(force: true, on: database).wait()
			} catch {
				XCTFail(error.localizedDescription)
			}
		}
	}
	
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
	/// deletePlacemarkAfterTestFinishes(placemark, on: app.db)
	/// ```
	func deletePlacemarkAfterTestFinishes(_ placemark: Placemark?, on database: Database) {
		addTeardownBlock {
			do {
				try placemark?.delete(force: true, on: database).wait()
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
	/// deletePossiblyCreatedPlacemarkAfterTestFinishes(name: placemark.name, on: app.db)
	/// ```
	func deletePossiblyCreatedPlacemarkAfterTestFinishes(name: String, on database: Database) {
		addTeardownBlock {
			do {
				try Placemark.query(on: database)
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