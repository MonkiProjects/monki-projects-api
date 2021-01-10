//
//  CreatePlacemarkType.swift
//  App
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension Placemark.PlacemarkType.Migrations {
	
	struct CreatePlacemarkType: Migration {
		
		var name: String { "CreatePlacemarkType" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.schema("placemark_types")
				.id()
				.field("human_id", .string, .required)
				.field("category_id", .uuid, .references("placemark_categories", .id))
				.unique(on: "human_id")
				.create()
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.schema("placemark_types").delete()
		}
		
	}
	
}