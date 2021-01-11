//
//  Placemark+Submission.swift
//  App
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor

extension Placemark {
	
	final class Submission: Model {
		
		static let schema = "placemark_submissions"
		
		@ID(key: .id)
		var id: UUID?
		
		@Parent(key: "placemark_id")
		var placemark: Placemark
		
		@Field(key: "state")
		var state: State
		
		@Children(for: \.$submission)
		var reviews: [Review]
		
		@Timestamp(key: "created_at", on: .create)
		var createdAt: Date?
		
		@Timestamp(key: "updated_at", on: .update)
		var updatedAt: Date?
		
		@Timestamp(key: "deleted_at", on: .delete)
		var deletedAt: Date?
		
		init() {}
		
		init(
			id: UUID? = nil,
			placemarkId: Placemark.IDValue,
			state: State = .submitted
		) {
			self.id = id
			self.$placemark.id = placemarkId
			self.state = state
		}
		
	}
	
}
