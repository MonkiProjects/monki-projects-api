//
//  PlaceDetailsRepository.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 17/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiMapModel

internal struct PlaceDetailsRepository: PlaceDetailsRepositoryProtocol {
	
	let database: Database
	
	init(database: Database) {
		self.database = database
	}
	
	func get(for placeId: Place.ID) async throws -> PlaceModel.Details {
		try await PlaceModel.Details.query(on: database)
			.with(\.$place)
			.filter(\.$place.$id == placeId)
			.first()
			.unwrap(or: Abort(.internalServerError, reason: "Could not find place details"))
	}
	
	func unsafeGetAll(for placeId: Place.ID) async throws -> [PlaceModel.Details] {
		try await PlaceModel.Details.query(on: database)
			.with(\.$place)
			.filter(\.$place.$id == placeId)
			.all()
	}
	
	func delete(for placeId: Place.ID, force: Bool) async throws {
		try await PlaceModel.Details.query(on: database)
			.with(\.$place)
			.filter(\.$place.$id == placeId)
			.delete(force: force)
	}
	
}
