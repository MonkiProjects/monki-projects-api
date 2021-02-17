//
//  Placemark+Submission.swift
//  App
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor
import MonkiMapModel

extension Placemark.Model {
	
	typealias Submission = Placemark.Submission.Model
	
}

extension Placemark.Submission {
	
	/// When a `Placemark` is submitted, a `Submission` is created.
	/// When a submission needs changes, a new `Submission` is created.
	/// It is stored in the `childSubmission` field of the last `Submission`.
	/// This allows a user to review every submission while not reviewing twice the same.
	/// It also keeps track of reviews while not interfeering with last submission.
	final class Model: Fluent.Model {
		
		static let schema = "placemark_submissions"
		
		@ID(key: .id)
		var id: UUID?
		
		@Parent(key: "placemark_id")
		var placemark: Placemark.Model
		
		@Field(key: "state")
		var state: State
		
		@Children(for: \.$submission)
		var reviews: [Review]
		
		@Field(key: "positive_reviews_count")
		var positiveReviews: UInt8
		
		@Field(key: "negative_reviews_count")
		var negativeReviews: UInt8
		
		@OptionalParent(key: "child_submission_id")
		var childSubmission: Placemark.Submission.Model?
		
		@Timestamp(key: "created_at", on: .create)
		var createdAt: Date?
		
		@Timestamp(key: "updated_at", on: .update)
		var updatedAt: Date?
		
		@Timestamp(key: "deleted_at", on: .delete)
		var deletedAt: Date?
		
		init() {}
		
		init(
			id: IDValue? = nil,
			placemarkId: Placemark.Model.IDValue,
			state: State = .waitingForReviews
		) {
			self.id = id
			self.$placemark.id = placemarkId
			self.state = state
			self.positiveReviews = 0
			self.negativeReviews = 0
		}
		
	}
	
}
