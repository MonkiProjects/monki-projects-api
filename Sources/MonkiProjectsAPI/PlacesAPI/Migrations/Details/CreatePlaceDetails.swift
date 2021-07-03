//
//  CreatePlaceDetails.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 20/02/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension PlaceModel.Details.Migrations {
	
	struct CreatePlaceDetails: Migration {
		
		var name: String { "CreatePlaceDetails" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.schema("place_details")
				.id()
				.field("place_id", .string, .references("places", .id, onDelete: .cascade))
				.field("caption", .string, .required)
				.field("satellite_image", .string, .required)
				.field("images", .array(of: .string), .required)
				.field("created_at", .datetime, .required)
				.field("updated_at", .datetime, .required)
				.field("deleted_at", .datetime)
				.unique(on: "place_id", name: "one_details_per_place")
				.create()
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.schema("place_details").delete()
		}
		
	}
	
}
