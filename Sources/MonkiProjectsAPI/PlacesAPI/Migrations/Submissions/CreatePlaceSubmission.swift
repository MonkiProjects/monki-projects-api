//
//  CreatePlaceSubmission.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 11/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension PlaceModel.Submission.Migrations {
	
	struct CreatePlaceSubmission: Migration {
		
		var name: String { "CreatePlaceSubmission" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.schema("place_submissions")
				.id()
				.field(
					"place_id", .string, .required,
					.references("places", .id, onDelete: .cascade)
				)
				.field("state", .string, .required)
				.field("positive_reviews_count", .uint8, .required)
				.field("negative_reviews_count", .uint8, .required)
				.field(
					"child_submission_id", .uuid,
					.references("place_submissions", .id, onDelete: .cascade)
				)
				.field("created_at", .datetime, .required)
				.field("updated_at", .datetime, .required)
				.field("deleted_at", .datetime)
				.create()
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.schema("place_submissions").delete()
		}
		
	}
	
}
