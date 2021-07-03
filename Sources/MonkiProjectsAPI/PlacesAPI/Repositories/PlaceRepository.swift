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
	
	func getAll() -> EventLoopFuture<[PlaceModel]> {
		PlaceModel.query(on: database)
			.all()
	}
	
	func getAllPaged(
		_ pageRequest: Fluent.PageRequest
	) -> EventLoopFuture<Fluent.Page<PlaceModel>> {
		PlaceModel.query(on: database)
			.paginate(pageRequest)
	}
	
	func getAll(
		state: Place.State?,
		creator: User.ID?
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
		creator: User.ID?,
		_ pageRequest: Fluent.PageRequest
	) -> EventLoopFuture<Fluent.Page<PlaceModel>> {
		var queryBuilder = PlaceModel.query(on: database)
		
		if let creator = creator {
			queryBuilder = queryBuilder.filter(\.$creator.$id == creator)
		}
		if let state = state {
			queryBuilder = queryBuilder.filter(\.$state == state)
		}
		
		return queryBuilder.paginate(pageRequest)
	}
	
	func get(_ placeId: Place.ID) -> EventLoopFuture<PlaceModel> {
		PlaceModel.find(placeId, on: database)
			.unwrap(or: Abort(.notFound, reason: "Place not found"))
	}
	
}
