//
//  AddInitialCategories.swift
//  App
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension Placemark.Category.Migrations {
	
	struct AddInitialCategories: Migration {
		
		var name: String { "AddInitialCategories" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.eventLoop.tryFuture(Placemark.Category.Internal.all)
				.mapEach { Placemark.Category(humanId: $0.id) }
				.mapEach { $0.save(on: database) }
				.transform(to: ())
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.eventLoop.tryFuture(Placemark.Category.Internal.all)
				.mapEach { category in
					Placemark.Category.query(on: database)
						.filter(\.$humanId == category.id)
						.first()
						.optionalMap { $0.delete(on: database) }
				}
				.transform(to: ())
		}
		
	}
	
}
