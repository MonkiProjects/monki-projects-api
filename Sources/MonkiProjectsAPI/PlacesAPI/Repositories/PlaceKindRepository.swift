//
//  PlaceKindRepository.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 17/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiMapModel

internal struct PlaceKindRepository: PlaceKindRepositoryProtocol {
	
	let database: Database
	
	init(database: Database) {
		self.database = database
	}
	
	func get(humanId: String) async throws -> PlaceModel.Kind {
		try await PlaceModel.Kind.query(on: database)
			.filter(\.$humanId == humanId)
			.first()
			.unwrap(or: Abort(.internalServerError, reason: "Could not find the '\(humanId)' place kind"))
	}
	
	func getAll() async throws -> [PlaceModel.Kind] {
		try await PlaceModel.Kind.query(on: database)
			.all()
	}
	
}
