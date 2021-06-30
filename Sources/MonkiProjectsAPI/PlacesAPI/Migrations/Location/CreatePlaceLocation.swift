//
//  CreatePlaceLocation.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension PlaceModel.Location.Migrations {
	
	struct CreatePlaceLocation: Migration {
		
		var name: String { "CreatePlaceLocation" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.schema("place_locations")
				.id()
				.field("details_id", .uuid, .references("place_details", .id, onDelete: .cascade))
				.field("city", .string, .required)
				.field("country", .string, .required)
				.unique(on: "details_id", name: "one_location_per_place_details")
				.create()
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.schema("place_locations").delete()
		}
		
	}
	
}
