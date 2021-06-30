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
	) -> EventLoopFuture<PlaceModel.Submission> {
		do {
			if isModerator {
				return reviewAsModerator(opinion: opinion, on: database)
			}
			return try reviewAsRegularUser(opinion: opinion, on: database)
		} catch {
			return database.eventLoop.makeFailedFuture(error)
		}
	}
	
	private func reviewAsModerator(
		opinion: Review.Opinion,
		on database: Database
	) -> EventLoopFuture<PlaceModel.Submission> {
		switch opinion {
		case .positive:
			self.positiveReviews += 1
			self.state = .accepted
		case .negative:
			self.negativeReviews += 1
			self.state = .moderated
		case .needsChanges:
			return setNeedsChanges(on: database)
		}
		
		return self.update(on: database)
			.transform(to: self)
	}
	
	private func reviewAsRegularUser(
		opinion: Review.Opinion,
		on database: Database
	) throws -> EventLoopFuture<PlaceModel.Submission> {
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
				return setNeedsChanges(on: database)
			}
		case .waitingForChanges:
			let allChangesAddressed = !self.reviews
				.filter { $0.opinion == .needsChanges }
				.map { $0.issues }
				// True if contains no `.submitted`
				.map { !$0.contains(where: { $0.state == .submitted }) }
				.contains(false)
			if allChangesAddressed {
				return setNeedsChanges(on: database)
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
		
		return self.update(on: database)
			.transform(to: self)
	}
	
	private func setNeedsChanges(on database: Database) -> EventLoopFuture<PlaceModel.Submission> {
		self.state = .needsChanges
		
		let newSubmission = Self(placeId: self.$place.id, state: .waitingForChanges)
		
		return self.update(on: database)
			.flatMap { newSubmission.create(on: database) }
			.transform(to: newSubmission)
	}
	
}
