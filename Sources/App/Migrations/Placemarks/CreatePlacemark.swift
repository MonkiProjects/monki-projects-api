//
//  CreatePlacemark.swift
//  Migrations
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension PlacemarkModel.Migrations {
	
	struct CreatePlacemark: Migration {
		
		var name: String { "CreatePlacemark" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.schema("placemarks")
				.id()
				.field("name", .string, .required)
				.field("latitude", .double, .required)
				.field("longitude", .double, .required)
				.field("kind_id", .uuid, .required, .references("placemark_kinds", .id))
				.field("state", .string, .required)
				.field("creator_id", .uuid, .required, .references("users", .id))
				.field("created_at", .datetime, .required)
				.field("updated_at", .datetime, .required)
				.field("deleted_at", .datetime)
				// Cannot .unique(on: "latitude", "longitude") because of soft-delete (and not very useful anyway)
				.create()
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.schema("placemarks").delete()
		}
		
	}
	
}
