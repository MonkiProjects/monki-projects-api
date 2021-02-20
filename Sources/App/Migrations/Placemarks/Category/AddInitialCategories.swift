//
//  AddInitialCategories.swift
//  App
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import MonkiMapModel

extension Models.Placemark.Category.Migrations {
	
	struct AddInitialCategories: Migration {
		
		var name: String { "AddInitialCategories" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.eventLoop.future(Placemark.Category.allCases)
				.mapEach { Migrated(humanId: $0.rawValue) }
				.mapEach { $0.save(on: database) }
				.transform(to: ())
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.eventLoop.future(Placemark.Category.allCases)
				.mapEach { category in
					Migrated.query(on: database)
						.filter(\.$humanId == category.rawValue)
						.first()
						.optionalMap { $0.delete(on: database) }
				}
				.transform(to: ())
		}
		
	}
	
}
