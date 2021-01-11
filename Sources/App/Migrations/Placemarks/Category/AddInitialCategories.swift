//
//  AddInitialCategories.swift
//  App
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension Placemark.Category.Migrations {
	
	struct AddCategories: Migration {
		
		var name: String { "AddInitialCategories" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.eventLoop.makeSucceededFuture(["spot", "facility", "misc"])
				.mapEach { Placemark.Category(humanId: $0) }
				.mapEach { $0.save(on: database) }
				.transform(to: ())
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.eventLoop.makeSucceededFuture(["spot", "facility", "misc"])
				.mapEach { humanId in
					Placemark.Category.query(on: database)
						.filter(\.$humanId == humanId)
						.first()
						.optionalMap { $0.delete(on: database) }
				}
				.transform(to: ())
		}
		
	}
	
}
