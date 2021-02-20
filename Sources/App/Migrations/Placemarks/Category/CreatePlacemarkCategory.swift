//
//  CreatePlacemarkCategory.swift
//  App
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension Models.Placemark.Category.Migrations {
	
	struct CreatePlacemarkCategory: Migration {
		
		var name: String { "CreatePlacemarkCategory" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.schema("placemark_categories")
				.id()
				.field("human_id", .string, .required)
				.unique(on: "human_id", name: "placemark_categories_no_duplicate_human_id")
				.create()
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.schema("placemark_categories").delete()
		}
		
	}
	
}
