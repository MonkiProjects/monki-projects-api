//
//  PlacemarkSubmissionReview+Public.swift
//  App
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import MonkiMapModel

extension Placemark.Submission.Review.Model {
	
	func asPublic() throws -> Placemark.Submission.Review.Public {
		return try .init(
			id: self.requireID(),
			submission: self.$submission.id,
			placemark: self.submission.$placemark.id,
			reviewer: self.$reviewer.id,
			opinion: opinion,
			comment: self.comment,
			issues: self.issues.map { try $0.asPublic() },
			moderated: self.moderated,
			createdAt: self.createdAt.require()
		)
	}
	
}

extension Placemark.Submission.Review.Public: Content {}
