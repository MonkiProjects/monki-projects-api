//
//  PlacemarkPropertyRepository.swift
//  App
//
//  Created by Rémi Bardon on 17/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiMapModel

internal struct PlacemarkPropertyRepository: PlacemarkPropertyRepositoryProtocol {
	
	let database: Database
	
	init(database: Database) {
		self.database = database
	}
	
	func unsafeGet(
		kind: Placemark.Property.Kind,
		humanId: String
	) -> EventLoopFuture<PlacemarkModel.Property?> {
		PlacemarkModel.Details.Property.query(on: database)
			.filter(\.$kind == kind)
			.filter(\.$humanId == humanId)
			.first()
	}
	
	func get(
		kind: Placemark.Property.Kind,
		humanId: String
	) -> EventLoopFuture<PlacemarkModel.Property> {
		self.unsafeGet(kind: kind, humanId: humanId)
			.unwrap(or: Abort(
				.badRequest,
				reason: "Invalid property: { \"kind\": \"\(kind)\", \"id\": \"\(humanId)\" }"
			))
	}
	
	func getAll(kind: Placemark.Property.Kind) -> EventLoopFuture<[PlacemarkModel.Property]> {
		PlacemarkModel.Property.query(on: database)
			.filter(\.$kind == kind)
			.all()
	}
	
	func getAll(dict: [Placemark.Property.Kind: [String]]) -> EventLoopFuture<[PlacemarkModel.Property]> {
		var pairs = [(Placemark.Property.Kind, String)]()
		for (key, values) in dict {
			for value in values {
				pairs.append((key, value))
			}
		}
		
		return database.eventLoop.makeSucceededFuture(pairs)
			.flatMapEach(on: database.eventLoop, get(kind:humanId:))
	}
	
}
