//
//  CreatePlacemarkLocation.swift
//  PlacemarksAPI
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension PlacemarkModel.Location.Migrations {
	
	struct CreatePlacemarkLocation: Migration {
		
		var name: String { "CreatePlacemarkLocation" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.schema("placemark_locations")
				.id()
				.field("details_id", .uuid, .references("placemark_details", .id, onDelete: .cascade))
				.field("city", .string, .required)
				.field("country", .string, .required)
				.unique(on: "details_id", name: "one_location_per_placemark_details")
				.create()
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.schema("placemark_locations").delete()
		}
		
	}
	
}
