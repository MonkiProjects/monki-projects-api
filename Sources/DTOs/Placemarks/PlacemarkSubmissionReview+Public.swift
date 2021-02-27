//
//  PlacemarkSubmissionReview+Public.swift
//  DTOs
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import Models
import MonkiMapModel

extension PlacemarkModel.Submission.Review {
	
	public func asPublic(
		on database: Database
	) -> EventLoopFuture<MonkiMapModel.Placemark.Submission.Review.Public> {
		let loadRelationsFuture = self.$submission.load(on: database)
			.flatMap { self.$issues.load(on: database) }
			.map { self.issues }
			.flatMapEach(on: database.eventLoop) { issue in
				issue.$review.load(on: database)
					.transform(to: issue.review)
			}
			.flatMapEach(on: database.eventLoop) { review in
				review.$submission.load(on: database)
					.flatMap { review.$reviewer.load(on: database) }
					.transform(to: review.submission)
			}
			.flatMapEach(on: database.eventLoop) { $0.$placemark.load(on: database) }
			.transform(to: ())
		
		return loadRelationsFuture.flatMapThrowing {
			try .init(
				id: self.requireID(),
				submission: self.$submission.id,
				placemark: self.submission.$placemark.id,
				reviewer: self.$reviewer.id,
				opinion: self.opinion,
				comment: self.comment,
				issues: self.issues.map { try $0.asPublic() },
				moderated: self.moderated,
				createdAt: self.createdAt.require()
			)
		}
	}
	
}

extension Placemark.Submission.Review.Public: Content {}
