//
//  PlaceRepository.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 16/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiMapModel

internal struct PlaceRepository: PlaceRepositoryProtocol {
	
	let database: Database
	
	init(database: Database) {
		self.database = database
	}
	
	func getAll() -> EventLoopFuture<[PlaceModel]> {
		PlaceModel.query(on: database)
			.all()
	}
	
	func getAllPaged(
		_ pageRequest: PageRequest
	) -> EventLoopFuture<Page<PlaceModel>> {
		PlaceModel.query(on: database)
			.paginate(pageRequest)
	}
	
	func getAll(
		state: Place.State?,
		creator: UUID?
	) -> EventLoopFuture<[PlaceModel]> {
		var queryBuilder = PlaceModel.query(on: database)
		
		if let creator = creator {
			queryBuilder = queryBuilder.filter(\.$creator.$id == creator)
		}
		if let state = state {
			queryBuilder = queryBuilder.filter(\.$state == state)
		}
		
		return queryBuilder.all()
	}
	
	func getAllPaged(
		state: Place.State?,
		creator: UUID?,
		_ pageRequest: PageRequest
	) -> EventLoopFuture<Page<PlaceModel>> {
		var queryBuilder = PlaceModel.query(on: database)
		
		if let creator = creator {
			queryBuilder = queryBuilder.filter(\.$creator.$id == creator)
		}
		if let state = state {
			queryBuilder = queryBuilder.filter(\.$state == state)
		}
		
		return queryBuilder.paginate(pageRequest)
	}
	
	func get(_ placeId: UUID) -> EventLoopFuture<PlaceModel> {
		PlaceModel.find(placeId, on: database)
			.unwrap(or: Abort(.notFound, reason: "Place not found"))
	}
	
}
