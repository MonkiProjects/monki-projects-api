//
//  PlaceSubmission+Public.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiMapModel

extension PlaceModel.Submission {
	
	public func asPublic(
		on req: Request
	) async throws -> MonkiMapModel.Place.Submission.Public {
		// Load relations
		try await self.$reviews.load(on: req.db)
		
		let reviews = await self.reviews.asPublic(on: req)
		
		return try .init(
			id: self.requireID(),
			place: self.$place.id,
			state: self.state,
			reviews: reviews,
			positiveReviews: self.positiveReviews,
			negativeReviews: self.negativeReviews,
			createdAt: self.createdAt.require(),
			updatedAt: self.updatedAt.require()
		)
	}
	
}

extension Place.Submission.Public: Content {}
