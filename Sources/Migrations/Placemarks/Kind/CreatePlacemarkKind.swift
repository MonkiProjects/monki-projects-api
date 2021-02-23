//
//  CreatePlacemarkKind.swift
//  Migrations
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Models

extension PlacemarkModel.Kind.Migrations {
	
	struct CreatePlacemarkKind: Migration {
		
		var name: String { "CreatePlacemarkKind" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.schema("placemark_kinds")
				.id()
				.field("human_id", .string, .required)
				.field("category_id", .uuid, .references("placemark_categories", .id))
				.unique(on: "human_id", name: "placemark_kinds_no_duplicate_human_id")
				.create()
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.schema("placemark_kinds").delete()
		}
		
	}
	
}
