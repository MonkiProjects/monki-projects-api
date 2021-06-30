//
//  PlaceSubmissionReview+Public.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiMapModel

extension PlaceModel.Submission.Review {
	
	public func asPublic(
		on req: Request
	) -> EventLoopFuture<MonkiMapModel.Place.Submission.Review.Public> {
		let loadRelationsFuture = EventLoopFuture.andAllSucceed([
			self.$submission.load(on: req.db),
			self.$issues.load(on: req.db),
		], on: req.eventLoop)
		
		let issuesFuture = loadRelationsFuture
			.transform(to: self.issues)
			.flatMapEach(on: req.eventLoop) { $0.asPublic(on: req) }
		
		return issuesFuture.flatMapThrowing { issues in
			try .init(
				id: self.requireID(),
				submission: self.$submission.id,
				place: self.submission.$place.id,
				reviewer: self.$reviewer.id,
				opinion: self.opinion,
				comment: self.comment,
				issues: issues,
				moderated: self.moderated,
				createdAt: self.createdAt.require()
			)
		}
	}
	
}

extension Place.Submission.Review.Public: Content {}
