//
//  CreatePlacemarkSubmission.swift
//  App
//
//  Created by Rémi Bardon on 11/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension Placemark.Submission.Migrations {
	
	struct CreatePlacemarkSubmission: Migration {
		
		var name: String { "CreatePlacemarkSubmission" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.schema("placemark_submissions")
				.id()
				.field(
					"placemark_id", .uuid, .required,
					.references("placemarks", .id, onDelete: .cascade)
				)
				.field("state", .string, .required)
				.field("created_at", .datetime, .required)
				.field("updated_at", .datetime, .required)
				.field("deleted_at", .datetime)
				.unique(on: "placemark_id", name: "no_duplicate_placemark_submissions")
				.create()
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.schema("placemark_submissions").delete()
		}
		
	}
	
}
