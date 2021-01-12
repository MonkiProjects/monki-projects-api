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

func typeId(
	for humanId: String,
	on database: Database
) -> EventLoopFuture<Placemark.PlacemarkType.IDValue> {
	Placemark.PlacemarkType.query(on: database)
		.filter(\.$humanId == humanId)
		.first()
		.unwrap(or: Abort(.notFound, reason: "Type not found"))
		.flatMapThrowing { try $0.requireID() }
}
