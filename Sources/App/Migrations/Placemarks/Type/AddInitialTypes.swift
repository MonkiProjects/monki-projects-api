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
	
	struct AddTypes: Migration {
		
		var name: String { "AddInitialTypes" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.eventLoop.makeSucceededFuture([
				("training_spot", "spot"),
				("outdoor_parkour_park", "spot"),
				("calisthenics_park", "spot"),
				("descent", "spot"),
				("urban_climbing_spot", "spot"),
				("playground", "spot"),
				("indoor_parkour_park", "facility"),
				("bouldering_facility", "facility"),
				("aom_academy", "facility"),
				("tricking_school", "facility"),
				("trampoline_park", "facility"),
				("gymnastics_gym", "facility"),
				("drinking_fountain", "misc"),
			])
			.flatMapEach(on: database.eventLoop) { humanId, categoryId in
				Placemark.Category.query(on: database)
					.filter(\.$humanId == categoryId)
					.first()
					.unwrap(or: Abort(.notFound, reason: "Category not found"))
					.flatMapThrowing { (humanId, try $0.requireID()) }
			}
			.mapEach { Placemark.PlacemarkType(humanId: $0.0, categoryId: $0.1) }
			.mapEach { $0.save(on: database) }
			.transform(to: ())
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.eventLoop.makeSucceededFuture(["spot", "facility", "misc"])
				.mapEach { humanId in
					Placemark.PlacemarkType.query(on: database)
						.filter(\.$humanId == humanId)
						.first()
						.optionalMap { $0.delete(on: database) }
				}
				.transform(to: ())
		}
		
	}
	
}
