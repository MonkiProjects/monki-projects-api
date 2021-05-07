//
//  AddInitialKinds.swift
//  PlacemarksAPI
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor
import MonkiMapModel

extension PlacemarkModel.Kind.Migrations {
	
	struct AddInitialKinds: Migration {
		
		var name: String { "AddInitialKinds" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.eventLoop.future(Placemark.Kind.allCases)
				.flatMapEach(on: database.eventLoop) { kind -> EventLoopFuture<(String, UUID)> in
					let category = Placemark.Category(for: kind)
					return Migrated.Category.query(on: database)
						.filter(\.$humanId == category.rawValue)
						.first()
						.unwrap(or: Abort(.notFound, reason: "Category '\(category)' not found."))
						.flatMapThrowing { (kind.rawValue, try $0.requireID()) }
				}
				.mapEach { Migrated(humanId: $0.0, categoryId: $0.1) }
				.mapEach { $0.save(on: database) }
				.transform(to: ())
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.eventLoop.future(Placemark.Kind.allCases)
				.mapEach { kind in
					Migrated.query(on: database)
						.filter(\.$humanId == kind.rawValue)
						.first()
						.optionalMap { $0.delete(on: database) }
				}
				.transform(to: ())
		}
		
	}
	
}
