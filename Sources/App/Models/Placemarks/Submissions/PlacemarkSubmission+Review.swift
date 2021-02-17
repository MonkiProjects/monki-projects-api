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

extension Placemark.Submission.Model {
	
	typealias Review = Placemark.Submission.Review.Model
	
}

extension Placemark.Submission.Review {
	
	final class Model: Fluent.Model {
		
		static let schema = "placemark_submission_reviews"
		
		@ID(key: .id)
		var id: UUID?
		
		@Parent(key: "submission_id")
		var submission: Placemark.Submission.Model
		
		@Parent(key: "reviewer_id")
		var reviewer: UserModel
		
		@Field(key: "opinion")
		var opinion: Placemark.Submission.Review.Opinion
		
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
			submissionId: Placemark.Submission.Model.IDValue,
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
