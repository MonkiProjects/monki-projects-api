//
//  PlacePropertyRepository.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 17/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiMapModel

internal struct PlacePropertyRepository: PlacePropertyRepositoryProtocol {
	
	let database: Database
	
	init(database: Database) {
		self.database = database
	}
	
	func unsafeGet(
		kind: Place.Property.Kind.ID,
		humanId: Place.Property.ID
	) async throws -> PlaceModel.Property? {
		try await PlaceModel.Details.Property.query(on: database)
			.filter(\.$kind == kind)
			.filter(\.$humanId == humanId)
			.first()
	}
	
	func get(
		kind: Place.Property.Kind.ID,
		humanId: Place.Property.ID
	) async throws -> PlaceModel.Property {
		try await self.unsafeGet(kind: kind, humanId: humanId)
			.unwrap(or: Abort(
				.badRequest,
				reason: "Invalid property: { \"kind\": \"\(kind)\", \"id\": \"\(humanId)\" }"
			))
	}
	
	func getAll(kind: Place.Property.Kind.ID) async throws -> [PlaceModel.Property] {
		try await PlaceModel.Property.query(on: database)
			.filter(\.$kind == kind)
			.all()
	}
	
	func getAll(
		dict: [Place.Property.Kind.ID: [Place.Property.ID]]
	) async throws -> [PlaceModel.Property] {
		try await withThrowingTaskGroup(
			of: PlaceModel.Property.self,
			returning: [PlaceModel.Property].self
		) { group in
			for (key, values) in dict {
				for value in values {
					group.async {
						return try await self.get(kind: key, humanId: value)
					}
				}
			}
			
			return try await group.reduce(into: [PlaceModel.Property]()) { $0.append($1) }
		}
	}
	
}
