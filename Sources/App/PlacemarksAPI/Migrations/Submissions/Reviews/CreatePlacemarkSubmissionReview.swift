//
//  CreatePlacemarkSubmissionReview.swift.swift
//  Migrations
//
//  Created by Rémi Bardon on 11/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension PlacemarkModel.Submission.Review.Migrations {
	
	struct CreatePlacemarkSubmissionReview: Migration {
		
		var name: String { "CreatePlacemarkSubmissionReview" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.schema("placemark_submission_reviews")
				.id()
				.field(
					"submission_id", .uuid, .required,
					.references("placemark_submissions", .id, onDelete: .cascade)
				)
				.field(
					"reviewer_id", .uuid, .required,
					.references("users", .id, onDelete: .cascade)
				)
				.field("opinion", .string, .required)
				.field("comment", .string, .required)
				.field("moderated", .bool, .required)
				.field("created_at", .datetime, .required)
				.field("updated_at", .datetime, .required)
				.field("deleted_at", .datetime)
				.unique(on: "submission_id", "reviewer_id", name: "no_duplicate_placemark_submission_reviews")
				.create()
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.schema("placemark_submission_reviews").delete()
		}
		
	}
	
}
