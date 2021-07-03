//
//  PlaceSubmission+Review.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor
import MonkiMapModel

extension PlaceModel.Submission {
	
	public final class Review: Model {
		
		public typealias Submission = PlaceModel.Submission
		public typealias Opinion = MonkiMapModel.Place.Submission.Review.Opinion
		
		public static let schema = "place_submission_reviews"
		
		@ID(key: .id)
		public var id: UUID?
		
		@Parent(key: "submission_id")
		public var submission: Submission
		
		@Parent(key: "reviewer_id")
		public var reviewer: UserModel
		
		@Field(key: "opinion")
		public var opinion: Opinion
		
		@Field(key: "comment")
		public var comment: String
		
		@Children(for: \.$review)
		public var issues: [Issue]
		
		@Field(key: "moderated")
		public var moderated: Bool
		
		@Timestamp(key: "created_at", on: .create)
		public var createdAt: Date?
		
		@Timestamp(key: "updated_at", on: .update)
		public var updatedAt: Date?
		
		@Timestamp(key: "deleted_at", on: .delete)
		public var deletedAt: Date?
		
		public init() {}
		
		public init(
			id: PlaceModel.Submission.Review.IDValue? = nil,
			submissionId: Submission.IDValue,
			reviewerId: UserModel.IDValue,
			opinion: Opinion,
			comment: String,
			moderated: Bool = false
		) {
			self.id = id
			self.$submission.id = submissionId
			self.$reviewer.id = reviewerId
			self.opinion = opinion
			self.comment = comment
			self.moderated = moderated
		}
		
	}
	
}
