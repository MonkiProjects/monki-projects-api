//
//  PlaceSubmissionReview+Public.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiMapModel

extension PlaceModel.Submission.Review {
	
	public func asPublic(
		on req: Request
	) async throws -> MonkiMapModel.Place.Submission.Review.Public {
		// Load relations
		try await self.$submission.load(on: req.db)
		try await self.$issues.load(on: req.db)
		
		typealias Issue = MonkiMapModel.Place.Submission.Review.Issue.Public
		let issues = try await withThrowingTaskGroup(of: Issue.self, returning: [Issue].self) { group in
			for issue in self.issues {
				group.async {
					return try await issue.asPublic(on: req)
				}
			}
			
			return try await group.reduce(into: [Issue]()) { $0.append($1) }
		}
		
		return try .init(
			id: self.requireID(),
			submission: self.$submission.id,
			place: self.submission.$place.id,
			reviewer: self.$reviewer.id,
			opinion: self.opinion,
			comment: self.comment,
			issues: issues,
			moderated: self.moderated,
			createdAt: self.createdAt.require()
		)
	}
	
}

extension Place.Submission.Review.Public: Content {}
