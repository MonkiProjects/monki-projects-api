//
//  CreatePlaceCategory.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension PlaceModel.Category.Migrations {
	
	struct CreatePlaceCategory: Migration {
		
		var name: String { "CreatePlaceCategory" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.schema("place_categories")
				.id()
				.field("human_id", .string, .required)
				.unique(on: "human_id", name: "place_categories_no_duplicate_human_id")
				.create()
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.schema("place_categories").delete()
		}
		
	}
	
}
