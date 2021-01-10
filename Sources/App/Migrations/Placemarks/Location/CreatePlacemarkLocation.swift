//
//  CreatePlacemarkLocation.swift
//  App
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension Placemark.Location.Migrations {
	
	struct CreatePlacemarkLocation: Migration {
		
		var name: String { "CreatePlacemarkLocation" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.schema("placemark_locations")
				.id()
				.field("city", .string, .required)
				.field("country", .string, .required)
				.create()
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.schema("placemark_locations").delete()
		}
		
	}
	
}
