//
//  PlacemarkRepository.swift
//  App
//
//  Created by Rémi Bardon on 16/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiMapModel

internal struct PlacemarkRepository: PlacemarkRepositoryProtocol {
	
	let database: Database
	
	init(database: Database) {
		self.database = database
	}
	
	func getAll() -> EventLoopFuture<[PlacemarkModel]> {
		PlacemarkModel.query(on: database)
			.all()
	}
	
	func getAllPaged(
		_ pageRequest: PageRequest
	) -> EventLoopFuture<Page<PlacemarkModel>> {
		PlacemarkModel.query(on: database)
			.paginate(pageRequest)
	}
	
	func getAll(
		state: Placemark.State?,
		creator: UUID?
	) -> EventLoopFuture<[PlacemarkModel]> {
		var queryBuilder = PlacemarkModel.query(on: database)
		
		if let creator = creator {
			queryBuilder = queryBuilder.filter(\.$creator.$id == creator)
		}
		if let state = state {
			queryBuilder = queryBuilder.filter(\.$state == state)
		}
		
		return queryBuilder.all()
	}
	
	func getAllPaged(
		state: Placemark.State?,
		creator: UUID?,
		_ pageRequest: PageRequest
	) -> EventLoopFuture<Page<PlacemarkModel>> {
		var queryBuilder = PlacemarkModel.query(on: database)
		
		if let creator = creator {
			queryBuilder = queryBuilder.filter(\.$creator.$id == creator)
		}
		if let state = state {
			queryBuilder = queryBuilder.filter(\.$state == state)
		}
		
		return queryBuilder.paginate(pageRequest)
	}
	
	func get(_ placemarkId: UUID) -> EventLoopFuture<PlacemarkModel> {
		PlacemarkModel.find(placemarkId, on: database)
			.unwrap(or: Abort(.notFound, reason: "Placemark not found"))
	}
	
}
