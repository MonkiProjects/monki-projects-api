//
//  AddInitialProperties.swift
//  App
//
//  Created by Rémi Bardon on 12/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension Placemark.Property.Migrations {
	
	struct AddInitialProperties: Migration {
		
		var name: String { "AddInitialProperties" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.eventLoop.tryFuture(Placemark.Property.Internal.all)
				.mapEach { Placemark.Property(type: $0.type, humanId: $0.id) }
				.mapEach { $0.save(on: database) }
				.transform(to: ())
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.eventLoop.tryFuture(Placemark.Property.Internal.all)
				.mapEach { property in
					Placemark.Property.query(on: database)
						.filter(\.$humanId == property.id)
						.first()
						.optionalMap { $0.delete(on: database) }
				}
				.transform(to: ())
		}
		
	}
	
}
