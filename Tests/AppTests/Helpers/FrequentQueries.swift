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
