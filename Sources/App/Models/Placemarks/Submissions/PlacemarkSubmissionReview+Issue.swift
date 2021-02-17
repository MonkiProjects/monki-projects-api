//
//  PlacemarkSubmissionReview+Issue.swift
//  App
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor
import MonkiMapModel

extension Placemark.Submission.Review.Model {
	
	typealias Issue = Placemark.Submission.Review.Issue.Model
	
}

extension Placemark.Submission.Review.Issue {
	
	final class Model: Fluent.Model {
		
		static let schema = "placemark_submission_review_issues"
		
		@ID(key: .id)
		var id: UUID?
		
		@Parent(key: "review_id")
		var review: Placemark.Submission.Review.Model
		
		@Field(key: "reason")
		var reason: Placemark.Submission.Review.Issue.Reason
		
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
			id: IDValue? = nil,
			reviewId: Placemark.Submission.Review.Model.IDValue,
			reason: Placemark.Submission.Review.Issue.Reason,
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
