//
//  PlacemarkSubmission+Public.swift
//  PlacemarksAPI
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiMapModel

extension PlacemarkModel.Submission {
	
	public func asPublic(
		on req: Request
	) -> EventLoopFuture<MonkiMapModel.Placemark.Submission.Public> {
		let loadRelationsFuture = self.$reviews.load(on: req.db)
		
		let reviewsFuture = loadRelationsFuture.transform(to: self.reviews)
			.flatMapEach(on: req.eventLoop) { $0.asPublic(on: req) }
		
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
