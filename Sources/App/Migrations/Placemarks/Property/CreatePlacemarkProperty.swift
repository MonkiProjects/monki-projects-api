//
//  CreatePlacemarkProperty.swift
//  App
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension Placemark.Property.Migrations {
	
	struct CreatePlacemarkProperty: Migration {
		
		var name: String { "CreatePlacemarkProperty" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.schema("placemark_properties")
				.id()
				.field("type", .string, .required)
				.field("human_id", .string, .required)
				.unique(on: "human_id")
				.create()
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.schema("placemark_properties").delete()
		}
		
	}
	
}