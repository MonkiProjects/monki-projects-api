//
//  PlacemarkPropertyRepository.swift
//  App
//
//  Created by Rémi Bardon on 17/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Repositories
import Vapor
import Fluent
import MonkiMapModel
import Models

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
	
	func getAll(kind: Placemark.Property.Kind) -> EventLoopFuture<[PlacemarkModel.Property]> {
		PlacemarkModel.Property.query(on: database)
			.filter(\.$kind == kind)
			.all()
	}
	
}
