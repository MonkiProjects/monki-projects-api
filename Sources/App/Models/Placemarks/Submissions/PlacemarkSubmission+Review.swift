//
//  PlacemarkSubmission+Review.swift
//  App
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor
import MonkiMapModel

extension Models.Placemark.Submission {
	
	final class Review: Model {
		
		typealias Submission = Models.Placemark.Submission
		typealias Opinion = MonkiMapModel.Placemark.Submission.Review.Opinion
		
		static let schema = "placemark_submission_reviews"
		
		@ID(key: .id)
		var id: UUID?
		
		@Parent(key: "submission_id")
		var submission: Submission
		
		@Parent(key: "reviewer_id")
		var reviewer: UserModel
		
		@Field(key: "opinion")
		var opinion: Opinion
		
		@Field(key: "comment")
		var comment: String
		
		@Children(for: \.$review)
		var issues: [Issue]
		
		@Field(key: "moderated")
		var moderated: Bool
		
		@Timestamp(key: "created_at", on: .create)
		var createdAt: Date?
		
		@Timestamp(key: "updated_at", on: .update)
		var updatedAt: Date?
		
		@Timestamp(key: "deleted_at", on: .delete)
		var deletedAt: Date?
		
		init() {}
		
		init(
			id: IDValue? = nil,
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
