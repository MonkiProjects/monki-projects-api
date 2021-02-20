//
//  CreatePlacemarkDetails.swift
//  App
//
//  Created by Rémi Bardon on 20/02/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension Models.Placemark.Details.Migrations {
	
	struct CreatePlacemarkDetails: Migration {
		
		var name: String { "CreatePlacemarkDetails" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.schema("placemark_details")
				.id()
				.field("placemark_id", .uuid, .references("placemarks", .id, onDelete: .cascade))
				.field("caption", .string, .required)
				.field("satellite_image", .string, .required)
				.field("images", .array(of: .string), .required)
				.field("location_id", .uuid, .references("placemark_locations", .id))
				.field("created_at", .datetime, .required)
				.field("updated_at", .datetime, .required)
				.field("deleted_at", .datetime)
				.create()
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.schema("placemark_details").delete()
		}
		
	}
	
}

