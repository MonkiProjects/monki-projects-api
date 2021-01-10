//
//  CreatePlacemarkPropertyPivot.swift
//  App
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension PlacemarkPropertyPivot.Migrations {
	
	struct CreatePlacemarkPropertyPivot: Migration {
		
		var name: String { "CreatePlacemarkPropertyPivot" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.schema("placemark+property")
				.id()
				.field("placemark_id", .uuid, .required, .references("placemarks", .id))
				.field("property_id", .uuid, .required, .references("placemark_properties", .id))
				.create()
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.schema("placemark+property").delete()
		}
		
	}
	
}
