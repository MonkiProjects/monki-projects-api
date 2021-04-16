//
//  PlacemarkRepository.swift
//  App
//
//  Created by Rémi Bardon on 16/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Repositories
import Vapor
import Fluent
import MonkiMapModel
import Models

public struct PlacemarkRepository: PlacemarkRepositoryProtocol {
	
	let database: Database
	
	init(database: Database) {
		self.database = database
	}
	
	public func all() -> EventLoopFuture<[Placemark.Public]> {
		PlacemarkModel.query(on: database)
			.all()
			.asPublic(on: database)
	}
	
	public func paged(
		_ pageRequest: PageRequest
	) -> EventLoopFuture<Page<Placemark.Public>> {
		PlacemarkModel.query(on: database)
			.paginate(pageRequest)
			.asPublic(on: database)
	}
	
	public func all(
		state: Placemark.State?,
		creator: UUID?
	) -> EventLoopFuture<[Placemark.Public]> {
		var queryBuilder = PlacemarkModel.query(on: database)
		
		if let creator = creator {
			queryBuilder = queryBuilder.filter(\.$creator.$id == creator)
		}
		if let state = state {
			queryBuilder = queryBuilder.filter(\.$state == state)
		}
		
		return queryBuilder.all()
			.asPublic(on: database)
	}
	
	public func paged(
		state: Placemark.State?,
		creator: UUID?,
		_ pageRequest: PageRequest
	) -> EventLoopFuture<Page<Placemark.Public>> {
		var queryBuilder = PlacemarkModel.query(on: database)
		
		if let creator = creator {
			queryBuilder = queryBuilder.filter(\.$creator.$id == creator)
		}
		if let state = state {
			queryBuilder = queryBuilder.filter(\.$state == state)
		}
		
		return queryBuilder.paginate(pageRequest)
			.asPublic(on: database)
	}
	
}
