//
//  PlaceSubmissionReviewIssue+Public.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import MonkiMapModel

extension PlaceModel.Submission.Review.Issue {
	
	public func asPublic(
		on req: Request
	) -> EventLoopFuture<MonkiMapModel.Place.Submission.Review.Issue.Public> {
		let loadRelationsFuture = self.$review.load(on: req.db)
			.transform(to: self.review)
			.flatMap { review in
				review.$submission.load(on: req.db)
					.flatMap { review.$reviewer.load(on: req.db) }
					.transform(to: review.submission)
			}
			.flatMap { $0.$place.load(on: req.db) }
		
		return loadRelationsFuture.flatMapThrowing {
			try .init(
				id: self.requireID(),
				place: self.review.submission.place.requireID(),
				issuer: self.review.reviewer.requireID(),
				reason: self.reason,
				comment: self.comment,
				state: self.state,
				createdAt: self.createdAt.require()
			)
		}
	}
	
}

extension Place.Submission.Review.Issue.Public: Content {}
