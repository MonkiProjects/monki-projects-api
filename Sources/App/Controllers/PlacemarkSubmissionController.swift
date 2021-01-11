//
//  PlacemarkController.swift
//  App
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor

struct PlacemarkSubmissionController: RouteCollection {
	
	typealias Submission = Placemark.Submission
	typealias Review = Submission.Review
	
	// MARK: - Routes
	
	func boot(routes: RoutesBuilder) throws {
		let submission = routes.grouped("submission")
		
		// GET /placemarks/{placemarkId}/submission
		submission.get(use: getPlacemarkSubmissionReport)
		
		let reviews = submission.grouped("reviews")
		
		// GET /placemarks/{placemarkId}/submission/reviews
		reviews.get(use: listPlacemarkSubmissionReviews)
		
		let tokenProtected = reviews.grouped(User.Token.authenticator())
		// POST /placemarks/{placemarkId}/submission/reviews
		tokenProtected.post(use: addPlacemarkSubmissionReview)
	}
	
	// MARK: - Route functions
	
	func getPlacemarkSubmissionReport(req: Request) throws -> EventLoopFuture<Submission.Public> {
		let placemarkId = try req.parameters.require("placemarkId", as: Placemark.IDValue.self)
		
		return submission(for: placemarkId, in: req.db)
			.flatMapThrowing { try $0.asPublic() }
	}
	
	func listPlacemarkSubmissionReviews(req: Request) throws -> EventLoopFuture<[Review.Public]> {
		let placemarkId = try req.parameters.require("placemarkId", as: Placemark.IDValue.self)
		
		return submission(for: placemarkId, in: req.db)
			.map { $0.reviews }
			.flatMapEachThrowing { try $0.asPublic() }
	}
	
	func addPlacemarkSubmissionReview(req: Request) throws -> EventLoopFuture<Review.Public> {
		let userId = try req.auth.require(User.self).requireID()
		let placemarkId = try req.parameters.require("placemarkId", as: Placemark.IDValue.self)
		
		// Validate and decode data
		try Review.Create.validate(content: req)
		let create = try req.content.decode(Review.Create.self)
		
		let createReview = { (submission: Submission) in
			(
				submission,
				try Review(
					submissionId: submission.requireID(),
					reviewerId: userId,
					opinion: create.opinion,
					comment: create.comment ?? ""
				)
			)
		}
		let addReview = { (submission: Submission, review: Review) in
			submission.$reviews.create(review, on: req.db)
				.transform(to: review)
		}
		let issues = create.issues ?? []
		let createIssues = { (review: Review) in
			(review, issues.map { Review.Issue(reviewId: userId, reason: $0.reason, comment: $0.comment) })
		}
		let addIssues = { (review: Review, issues: [Review.Issue]) in
			review.$issues.create(issues, on: req.db)
				.transform(to: review)
		}
		
		return guardReviewerIsNotCreator(userId: userId, placemarkId: placemarkId, in: req.db)
			.flatMap { guardNoDoubleReview(by: userId, for: placemarkId, in: req.db) }
			.flatMap { submission(for: placemarkId, in: req.db) }
			.flatMapThrowing(createReview)
			.flatMap(addReview)
			.map(createIssues)
			.flatMap(addIssues)
			.flatMap { loadRelations(of: $0, on: req.db) }
			.flatMapThrowing { try $0.asPublic() }
	}
	
	// MARK: - Helper functions
	
	private func submission(
		for placemarkId: Placemark.IDValue,
		in database: Database
	) -> EventLoopFuture<Submission> {
		Submission.query(on: database)
			.with(\.$placemark)
			.with(\.$reviews) { review in
				review.with(\.$submission) { submission in
					submission.with(\.$placemark)
				}
				review.with(\.$reviewer)
				review.with(\.$issues) { issue in
					issue.with(\.$review) { review in
						review.with(\.$submission) { submission in
							submission.with(\.$placemark)
						}
						review.with(\.$reviewer)
					}
				}
			}
			.filter(\.$placemark.$id == placemarkId)
			.first()
			.unwrap(or: Abort(.notFound, reason: "Placemark not found"))
	}
	
	/// Prevent user from reviewing his own submission
	private func guardReviewerIsNotCreator(
		userId: User.IDValue,
		placemarkId: Placemark.IDValue,
		in database: Database
	) -> EventLoopFuture<Void> {
		Placemark.find(placemarkId, on: database)
			.unwrap(or: Abort(.notFound, reason: "Placemark not found"))
			.guard({ $0.$creator.id != userId },
				   else: Abort(.forbidden, reason: "You cannot review your own submission!")
			)
			.transform(to: ())
	}
	
	/// Prevent user from reviewing twice the same submission
	private func guardNoDoubleReview(
		by userId: User.IDValue,
		for placemarkId: Placemark.IDValue,
		in database: Database
	) -> EventLoopFuture<Void> {
		// Fetch all reviews
		Review.query(on: database)
			// From user `userId`
			.filter(\.$reviewer.$id == userId)
			// With a submission for placemark `placemarkId`
			.join(Submission.self, on: \Review.$submission.$id == \Submission.$id)
			.filter(Submission.self, \.$placemark.$id == placemarkId)
			.first()
			.guard({ $0 == nil },
				   else: Abort(.forbidden, reason: "You cannot review a placemark twice!")
			)
			.transform(to: ())
	}
	
	private func loadRelations(of review: Review, on database: Database) -> EventLoopFuture<Review> {
		review.$submission.load(on: database)
			.flatMap { review.$issues.load(on: database) }
			.map { review.issues }
			.flatMapEach(on: database.eventLoop) { issue in
				issue.$review.load(on: database)
					.transform(to: issue.review)
			}
			.flatMapEach(on: database.eventLoop) { review in
				review.$submission.load(on: database)
					.flatMap { review.$reviewer.load(on: database) }
					.transform(to: review.submission)
			}
			.flatMapEach(on: database.eventLoop) { $0.$placemark.load(on: database) }
			.transform(to: review)
	}
	
}
