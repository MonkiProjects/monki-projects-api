//
//  PlacemarkSubmission+Public.swift
//  App
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor

extension Placemark.Submission {
	
	struct Public: Content {
		
		let id: UUID
		let placemark: UUID
		let state: State
		let reviews: [Review.Public]
		let createdAt: Date
		let updatedAt: Date
		
	}
	
	func asPublic() throws -> Public {
		try Public(
			id: self.requireID(),
			placemark: self.$placemark.id,
			state: self.state,
			reviews: self.reviews.map { try $0.asPublic() },
			createdAt: self.createdAt.require(),
			updatedAt: self.updatedAt.require()
		)
	}
	
}
