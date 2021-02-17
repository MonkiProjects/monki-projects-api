//
//  PlacemarkSubmission+Public.swift
//  App
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import MonkiMapModel

extension Placemark.Submission.Model {
	
	func asPublic() throws -> Placemark.Submission.Public {
		return try .init(
			id: self.requireID(),
			placemark: self.$placemark.id,
			state: self.state,
			reviews: self.reviews.map { try $0.asPublic() },
			positiveReviews: self.positiveReviews,
			negativeReviews: self.negativeReviews,
			createdAt: self.createdAt.require(),
			updatedAt: self.updatedAt.require()
		)
	}
	
}

extension Placemark.Submission.Public: Content {}
