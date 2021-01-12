//
//  AddInitialTypes.swift
//  App
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor

extension Placemark.PlacemarkType.Migrations {
	
	struct AddInitialTypes: Migration {
		
		var name: String { "AddInitialTypes" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.eventLoop.tryFuture(Placemark.PlacemarkType.Internal.all)
				.flatMapEach(on: database.eventLoop) { type in
					Placemark.Category.query(on: database)
						.filter(\.$humanId == type.category)
						.first()
						.unwrap(or: Abort(.notFound, reason: "Category not found"))
						.flatMapThrowing { (type.id, try $0.requireID()) }
				}
				.mapEach { Placemark.PlacemarkType(humanId: $0.0, categoryId: $0.1) }
				.mapEach { $0.save(on: database) }
				.transform(to: ())
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.eventLoop.tryFuture(Placemark.PlacemarkType.Internal.all)
				.mapEach { type in
					Placemark.PlacemarkType.query(on: database)
						.filter(\.$humanId == type.id)
						.first()
						.optionalMap { $0.delete(on: database) }
				}
				.transform(to: ())
		}
		
	}
	
}
