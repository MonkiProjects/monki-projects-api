//
//  PlacemarkSubmissionReview+Issue.swift
//  App
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor

extension Placemark.Submission.Review {
	
	final class Issue: Model {
		
		static let schema = "placemark_submission_review_issues"
		
		@ID(key: .id)
		var id: UUID?
		
		@Parent(key: "review_id")
		var review: Placemark.Submission.Review
		
		@Field(key: "reason")
		var reason: Reason
		
		@Field(key: "comment")
		var comment: String
		
		@Field(key: "state")
		var state: State
		
		@Timestamp(key: "created_at", on: .create)
		var createdAt: Date?
		
		@Timestamp(key: "updated_at", on: .update)
		var updatedAt: Date?
		
		@Timestamp(key: "deleted_at", on: .delete)
		var deletedAt: Date?
		
		init() {}
		
		init(
			id: UUID? = nil,
			reviewId: Placemark.Submission.Review.IDValue,
			reason: Reason,
			comment: String,
			state: State = .submitted
		) {
			self.id = id
			self.$review.id = reviewId
			self.reason = reason
			self.comment = comment
			self.state = state
		}
		
	}
	
}