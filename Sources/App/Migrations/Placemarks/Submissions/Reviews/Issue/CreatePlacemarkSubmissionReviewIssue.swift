//
//  CreatePlacemarkSubmissionReviewIssue.swift
//  App
//
//  Created by Rémi Bardon on 11/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import MonkiMapModel

extension Placemark.Submission.Review.Issue.Model.Migrations {
	
	struct CreatePlacemarkSubmissionReviewIssue: Migration {
		
		var name: String { "CreatePlacemarkSubmissionReviewIssue" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.schema("placemark_submission_review_issues")
				.id()
				.field(
					"review_id", .uuid, .required,
					.references("placemark_submission_reviews", .id, onDelete: .cascade)
				)
				.field("reason", .string, .required)
				.field("comment", .string, .required)
				.field("state", .string, .required)
				.field("created_at", .datetime, .required)
				.field("updated_at", .datetime, .required)
				.field("deleted_at", .datetime)
				.unique(on: "review_id", "reason", "comment", name: "no_duplicate_placemark_submission_review_issues")
				.create()
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.schema("placemark_submission_review_issues").delete()
		}
		
	}
	
}
