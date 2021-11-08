//
//  PlaceSubmission+State.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent

extension PlaceModel.Submission {
	
	public static let positiveReviewCountToValidate: UInt8 = 5
	public static let negativeReviewCountToReject: UInt8 = 2
	
	public func review(
		opinion: Review.Opinion,
		isModerator: Bool,
		on database: Database
	) async throws -> PlaceModel.Submission {
		if isModerator {
			return try await reviewAsModerator(opinion: opinion, on: database)
		}
		return try await reviewAsRegularUser(opinion: opinion, on: database)
	}
	
	private func reviewAsModerator(
		opinion: Review.Opinion,
		on database: Database
	) async throws -> PlaceModel.Submission {
		switch opinion {
		case .positive:
			self.positiveReviews += 1
			self.state = .accepted
		case .negative:
			self.negativeReviews += 1
			self.state = .moderated
		case .needsChanges:
			return try await setNeedsChanges(on: database)
		}
		
		try await self.update(on: database)
		
		return self
	}
	
	private func reviewAsRegularUser(
		opinion: Review.Opinion,
		on database: Database
	) async throws -> PlaceModel.Submission {
		switch self.state {
		case .waitingForReviews:
			switch opinion {
			case .positive:
				self.positiveReviews += 1
				if self.positiveReviews >= Self.positiveReviewCountToValidate {
					self.state = .accepted
				}
			case .negative:
				self.negativeReviews += 1
				if self.negativeReviews >= Self.negativeReviewCountToReject {
					self.state = .rejected
				}
			case .needsChanges:
				return try await setNeedsChanges(on: database)
			}
		case .waitingForChanges:
			let allChangesAddressed = !self.reviews
				.filter { $0.opinion == .needsChanges }
				.map { $0.issues }
				// True if contains no `.submitted`
				.map { !$0.contains(where: { $0.state == .submitted }) }
				.contains(false)
			if allChangesAddressed {
				return try await setNeedsChanges(on: database)
			} else {
				throw Abort(.forbidden, reason: "This place still needs changes to be reviewed")
			}
		case .needsChanges:
			throw Abort(.forbidden, reason: "This submission has been closed because it needed changes")
		case .accepted:
			throw Abort(.forbidden, reason: "This place has already been accepted")
		case .rejected:
			throw Abort(.forbidden, reason: "This place has been rejected")
		case .moderated:
			throw Abort(.forbidden, reason: "This place has been moderated")
		}
		
		try await self.update(on: database)
		
		return self
	}
	
	private func setNeedsChanges(on database: Database) async throws -> PlaceModel.Submission {
		self.state = .needsChanges
		
		let newSubmission = Self(placeId: self.$place.id, state: .waitingForChanges)
		
		try await self.update(on: database)
		try await newSubmission.create(on: database)
		
		return newSubmission
	}
	
}
