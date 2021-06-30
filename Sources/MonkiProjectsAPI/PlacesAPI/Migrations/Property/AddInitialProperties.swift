//
//  AddInitialProperties.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 12/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import MonkiMapModel

extension PlaceModel.Property.Migrations {
	
	struct AddInitialProperties: Migration {
		
		var name: String { "AddInitialProperties" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.eventLoop.future(Place.Property.all(in: .en))
				.mapEach { Migrated(kind: $0.kind, humanId: $0.id) }
				.mapEach { $0.save(on: database) }
				.transform(to: ())
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.eventLoop.future(Place.Property.all(in: .en))
				.mapEach { property in
					Migrated.query(on: database)
						.filter(\.$humanId == property.id)
						.first()
						.optionalMap { $0.delete(on: database) }
				}
				.transform(to: ())
		}
		
	}
	
}
