//
//  PlacemarkSubmissionReviewIssue+Public.swift
//  PlacemarksAPI
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import MonkiMapModel

extension PlacemarkModel.Submission.Review.Issue {
	
	public func asPublic() throws -> MonkiMapModel.Placemark.Submission.Review.Issue.Public {
		try .init(
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

extension Placemark.Submission.Review.Issue.Public: Content {}
