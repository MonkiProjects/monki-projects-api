//
//  PlacemarkSubmission+Public.swift
//  DTOs
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiMapModel

extension PlacemarkModel.Submission {
	
	public func asPublic(
		on database: Database
	) -> EventLoopFuture<MonkiMapModel.Placemark.Submission.Public> {
		let loadRelationsFuture = self.$reviews.load(on: database)
		
		let reviewsFuture = loadRelationsFuture.transform(to: self.reviews)
			.flatMapEach(on: database.eventLoop) { $0.asPublic(on: database) }
		
		return reviewsFuture.flatMapThrowing { reviews in
			try .init(
				id: self.requireID(),
				placemark: self.$placemark.id,
				state: self.state,
				reviews: reviews,
				positiveReviews: self.positiveReviews,
				negativeReviews: self.negativeReviews,
				createdAt: self.createdAt.require(),
				updatedAt: self.updatedAt.require()
			)
		}
	}
	
}

extension Placemark.Submission.Public: Content {}
