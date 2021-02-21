//
//  FrequentQueries.swift
//  AppTests
//
//  Created by Rémi Bardon on 12/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

@testable import App
import Vapor
import Fluent

func kindId(
	for humanId: String,
	on database: Database
) -> EventLoopFuture<PlacemarkModel.Kind.IDValue> {
	PlacemarkModel.Kind.query(on: database)
		.filter(\.$humanId == humanId)
		.first()
		.unwrap(or: Abort(.notFound, reason: "Type not found"))
		.flatMapThrowing { try $0.requireID() }
}

func createPlacemark(
	_ model: PlacemarkModel,
	details: PlacemarkModel.Details = .dummy(placemarkId: UUID()),
	location: PlacemarkModel.Location = .dummy(detailsId: UUID()),
	on database: Database
) -> EventLoopFuture<Void> {
	model.create(on: database)
		.flatMapThrowing { details.$placemark.id = try model.requireID() }
		.flatMap { details.create(on: database) }
		.flatMapThrowing { location.$details.id = try details.requireID() }
		.flatMap { location.create(on: database) }
	
//	deletePlacemarkAfterTestFinishes(submittedPlacemark, on: app.db)
//	deletePlacemarkDetailsAfterTestFinishes(submittedPlacemark, on: app.db)
}
