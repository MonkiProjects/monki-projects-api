//
//  CreatePlacePropertyPivot.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension PlacePropertyPivot.Migrations {
	
	struct CreatePlacePropertyPivot: Migration {
		
		var name: String { "CreatePlacePropertyPivot" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.schema("place+property")
				.id()
				.field(
					"details_id", .uuid, .required,
					.references("place_details", .id, onDelete: .cascade)
				)
				.field(
					"property_id", .uuid, .required,
					.references("place_properties", .id, onDelete: .cascade)
				)
				.create()
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.schema("place+property").delete()
		}
		
	}
	
}
