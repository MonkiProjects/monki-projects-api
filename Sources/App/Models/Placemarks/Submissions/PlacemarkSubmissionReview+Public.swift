//
//  PlacemarkSubmissionReview+Public.swift
//  App
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor

extension Placemark.Submission.Review {
	
	struct Public: Content {
		
		let id: UUID
		let placemark: UUID
		let reviewer: UUID
		let opinion: Opinion
		let comment: String
		let issues: [Issue.Public]
		let moderated: Bool
		let createdAt: Date
		
	}
	
	func asPublic() throws -> Public {
		try Public(
			id: self.requireID(),
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
