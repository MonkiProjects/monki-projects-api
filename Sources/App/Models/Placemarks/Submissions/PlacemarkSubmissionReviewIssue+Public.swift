//
//  PlacemarkSubmissionReviewIssue+Public.swift
//  App
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor

extension Placemark.Submission.Review.Issue {
	
	struct Public: Content {
		
		let id: UUID
		let placemark: UUID
		let issuer: UUID
		let reason: Reason
		let comment: String
		let state: State
		let createdAt: Date
		
	}
	
	func asPublic() throws -> Public {
		try Public(
			id: self.requireID(),
			placemark: self.review.submission.placemark.requireID(),
			issuer: self.review.reviewer.requireID(),
			reason: reason,
			comment: self.comment,
			state: self.state,
			createdAt: self.createdAt.require()
		)
	}
	
}
