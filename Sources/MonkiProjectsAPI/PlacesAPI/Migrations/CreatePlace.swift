//
//  CreatePlace.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension PlaceModel.Migrations {
	
	struct CreatePlace: Migration {
		
		var name: String { "CreatePlace" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.schema("places")
				.field(.id, .string, .identifier(auto: false))
				.field("name", .string, .required)
				.field("latitude", .double, .required)
				.field("longitude", .double, .required)
				.field("kind_id", .uuid, .required, .references("place_kinds", .id))
				.field("visibility", .string, .required)
				.field("is_draft", .bool, .required)
				.field("creator_id", .string, .required, .references("users", .id))
				.field("created_at", .datetime, .required)
				.field("updated_at", .datetime, .required)
				.field("deleted_at", .datetime)
				// Cannot .unique(on: "latitude", "longitude") because of soft-delete (and not very useful anyway)
				.create()
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.schema("places").delete()
		}
		
	}
	
}
