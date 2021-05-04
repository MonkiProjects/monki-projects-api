//
//  Placemark+Submission.swift
//  Models
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor
import MonkiMapModel

extension PlacemarkModel {
	
	/// When a `Placemark` is submitted, a `Submission` is created.
	/// When a submission needs changes, a new `Submission` is created.
	/// It is stored in the `childSubmission` field of the last `Submission`.
	/// This allows a user to review every submission while not reviewing twice the same.
	/// It also keeps track of reviews while not interfeering with last submission.
	public final class Submission: Model {
		
		public typealias Placemark = PlacemarkModel
		public typealias State = MonkiMapModel.Placemark.Submission.State
		
		public static let schema = "placemark_submissions"
		
		@ID(key: .id)
		public var id: UUID?
		
		@Parent(key: "placemark_id")
		public var placemark: Placemark
		
		@Field(key: "state")
		public var state: State
		
		@Children(for: \.$submission)
		public var reviews: [Review]
		
		@Field(key: "positive_reviews_count")
		public var positiveReviews: UInt8
		
		@Field(key: "negative_reviews_count")
		public var negativeReviews: UInt8
		
		@OptionalParent(key: "child_submission_id")
		public var childSubmission: PlacemarkModel.Submission?
		
		@Timestamp(key: "created_at", on: .create)
		public var createdAt: Date?
		
		@Timestamp(key: "updated_at", on: .update)
		public var updatedAt: Date?
		
		@Timestamp(key: "deleted_at", on: .delete)
		public var deletedAt: Date?
		
		public init() {}
		
		public init(
			id: IDValue? = nil,
			placemarkId: Placemark.IDValue,
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
