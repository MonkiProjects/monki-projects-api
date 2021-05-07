//
//  PlacemarkDetailsRepository.swift
//  PlacemarksAPI
//
//  Created by Rémi Bardon on 17/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent

internal struct PlacemarkDetailsRepository: PlacemarkDetailsRepositoryProtocol {
	
	let database: Database
	
	init(database: Database) {
		self.database = database
	}
	
	func get(for placemarkId: UUID) -> EventLoopFuture<PlacemarkModel.Details> {
		PlacemarkModel.Details.query(on: database)
			.with(\.$placemark)
			.filter(\.$placemark.$id == placemarkId)
			.first()
			.unwrap(or: Abort(.internalServerError, reason: "Could not find placemark details"))
	}
	
	func unsafeGetAll(for placemarkId: UUID) -> EventLoopFuture<[PlacemarkModel.Details]> {
		PlacemarkModel.Details.query(on: database)
			.with(\.$placemark)
			.filter(\.$placemark.$id == placemarkId)
			.all()
	}
	
	func delete(for placemarkId: UUID, force: Bool) -> EventLoopFuture<Void> {
		self.unsafeGetAll(for: placemarkId)
			.flatMap { $0.delete(force: force, on: database) }
	}
	
}
