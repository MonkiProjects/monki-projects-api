//
//  PlacemarkSubmission+Public.swift
//  App
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import MonkiMapModel

extension Models.Placemark.Submission {
	
	func asPublic() throws -> MonkiMapModel.Placemark.Submission.Public {
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

extension MonkiMapModel.Placemark.Submission.Public: Content {}
