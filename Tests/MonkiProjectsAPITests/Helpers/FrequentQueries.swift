//
//  FrequentQueries.swift
//  MonkiProjectsAPITests
//
//  Created by Rémi Bardon on 12/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

@testable import MonkiProjectsAPI
import Vapor
import Fluent

internal func kindId(
	for humanId: String,
	on database: Database
) -> EventLoopFuture<PlaceModel.Kind.IDValue> {
	PlaceModel.Kind.query(on: database)
		.filter(\.$humanId == humanId)
		.first()
		.unwrap(or: Abort(.notFound, reason: "Type not found"))
		.flatMapThrowing { try $0.requireID() }
}

internal func createPlace(
	_ model: PlaceModel,
	details: PlaceModel.Details = .dummy(placeId: .init()),
	location: PlaceModel.Location = .dummy(detailsId: .init()),
	on database: Database
) -> EventLoopFuture<Void> {
	model.create(on: database)
		.flatMapThrowing { details.$place.id = try model.requireID() }
		.flatMap { details.create(on: database) }
		.flatMapThrowing { location.$details.id = try details.requireID() }
		.flatMap { location.create(on: database) }
	
//	deletePlaceAfterTestFinishes(submittedPlace, on: app.db)
//	deletePlaceDetailsAfterTestFinishes(submittedPlace, on: app.db)
}
