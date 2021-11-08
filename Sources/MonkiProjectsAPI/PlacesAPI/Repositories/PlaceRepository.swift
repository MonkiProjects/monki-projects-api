//
//  PlaceRepository.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 16/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiProjectsModel
import MonkiMapModel

internal struct PlaceRepository: PlaceRepositoryProtocol {
	
	let database: Database
	
	init(database: Database) {
		self.database = database
	}
	
	func getAll() async throws -> [PlaceModel] {
		try await PlaceModel.query(on: database)
			.all()
	}
	
	func getAllPaged(
		_ pageRequest: Fluent.PageRequest
	) async throws -> Fluent.Page<PlaceModel> {
		try await PlaceModel.query(on: database)
			.paginate(pageRequest)
	}
	
	func getAll(
		state: Place.State?,
		creator: User.ID?
	) async throws -> [PlaceModel] {
		var queryBuilder = PlaceModel.query(on: database)
		
		if let creator = creator {
			queryBuilder = queryBuilder.filter(\.$creator.$id == creator)
		}
		if let state = state {
			queryBuilder = queryBuilder.filter(\.$state == state)
		}
		
		return try await queryBuilder.all()
	}
	
	func getAllPaged(
		state: Place.State?,
		creator: User.ID?,
		_ pageRequest: Fluent.PageRequest
	) async throws -> Fluent.Page<PlaceModel> {
		var queryBuilder = PlaceModel.query(on: database)
		
		if let creator = creator {
			queryBuilder = queryBuilder.filter(\.$creator.$id == creator)
		}
		if let state = state {
			queryBuilder = queryBuilder.filter(\.$state == state)
		}
		
		return try await queryBuilder.paginate(pageRequest)
	}
	
	func get(_ placeId: Place.ID) async throws -> PlaceModel {
		try await PlaceModel.find(placeId, on: database)
			.unwrap(or: Abort(.notFound, reason: "Place not found"))
	}
	
}
