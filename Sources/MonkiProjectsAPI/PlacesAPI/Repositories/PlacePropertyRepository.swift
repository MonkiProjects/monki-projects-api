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
	) -> EventLoopFuture<PlaceModel.Property?> {
		PlaceModel.Details.Property.query(on: database)
			.filter(\.$kind == kind)
			.filter(\.$humanId == humanId)
			.first()
	}
	
	func get(
		kind: Place.Property.Kind.ID,
		humanId: Place.Property.ID
	) -> EventLoopFuture<PlaceModel.Property> {
		self.unsafeGet(kind: kind, humanId: humanId)
			.unwrap(or: Abort(
				.badRequest,
				reason: "Invalid property: { \"kind\": \"\(kind)\", \"id\": \"\(humanId)\" }"
			))
	}
	
	func getAll(kind: Place.Property.Kind.ID) -> EventLoopFuture<[PlaceModel.Property]> {
		PlaceModel.Property.query(on: database)
			.filter(\.$kind == kind)
			.all()
	}
	
	func getAll(
		dict: [Place.Property.Kind.ID: [Place.Property.ID]]
	) -> EventLoopFuture<[PlaceModel.Property]> {
		var pairs = [(Place.Property.Kind.ID, Place.Property.ID)]()
		for (key, values) in dict {
			for value in values {
				pairs.append((key, value))
			}
		}
		
		return database.eventLoop.makeSucceededFuture(pairs)
			.flatMapEach(on: database.eventLoop, get(kind:humanId:))
	}
	
}
