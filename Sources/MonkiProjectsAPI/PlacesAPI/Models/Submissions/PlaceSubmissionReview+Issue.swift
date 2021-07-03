//
//  PlaceSubmissionReview+Issue.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor
import MonkiMapModel

extension PlaceModel.Submission.Review {
	
	public final class Issue: Model {
		
		public typealias Review = PlaceModel.Submission.Review
		public typealias Reason = Place.Submission.Review.Issue.Reason
		public typealias State = Place.Submission.Review.Issue.State
		
		public static let schema = "place_submission_review_issues"
		
		@ID(key: .id)
		public var id: UUID?
		
		@Parent(key: "review_id")
		public var review: Review
		
		@Field(key: "reason")
		public var reason: Reason
		
		@Field(key: "comment")
		public var comment: String
		
		@Field(key: "state")
		public var state: State
		
		@Timestamp(key: "created_at", on: .create)
		public var createdAt: Date?
		
		@Timestamp(key: "updated_at", on: .update)
		public var updatedAt: Date?
		
		@Timestamp(key: "deleted_at", on: .delete)
		public var deletedAt: Date?
		
		public init() {}
		
		public init(
			id: PlaceModel.Submission.Review.Issue.IDValue? = nil,
			reviewId: Review.IDValue,
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
