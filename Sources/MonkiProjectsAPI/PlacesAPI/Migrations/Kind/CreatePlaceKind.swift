//
//  CreatePlaceKind.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension PlaceModel.Kind.Migrations {
	
	struct CreatePlaceKind: Migration {
		
		var name: String { "CreatePlaceKind" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.schema("place_kinds")
				.id()
				.field("human_id", .string, .required)
				.field("category_id", .uuid, .references("place_categories", .id))
				.unique(on: "human_id", name: "place_kinds_no_duplicate_human_id")
				.create()
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.schema("place_kinds").delete()
		}
		
	}
	
}
