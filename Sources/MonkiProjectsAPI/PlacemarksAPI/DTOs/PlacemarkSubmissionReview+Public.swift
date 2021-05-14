//
//  PlacemarkSubmissionReview+Public.swift
//  PlacemarksAPI
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiMapModel

extension PlacemarkModel.Submission.Review {
	
	public func asPublic(
		on req: Request
	) -> EventLoopFuture<MonkiMapModel.Placemark.Submission.Review.Public> {
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
				placemark: self.submission.$placemark.id,
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

extension Placemark.Submission.Review.Public: Content {}
