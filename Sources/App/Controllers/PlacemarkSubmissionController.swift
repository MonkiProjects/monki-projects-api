//
//  PlacemarkController.swift
//  App
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor
import Models
import MonkiMapModel

internal struct PlacemarkSubmissionController: RouteCollection {
	
	typealias Submission = Placemark.Submission
	typealias Review = Submission.Review
	
	typealias SubmissionModel = PlacemarkModel.Submission
	typealias ReviewModel = SubmissionModel.Review
	typealias IssueModel = ReviewModel.Issue
	
	// MARK: - Routes
	
	/// Routes start at `/placemarks/{placemarkId}`
	func boot(routes: RoutesBuilder) throws {
		let tokenProtected = routes.grouped(UserModel.Token.authenticator())
		
		// POST /placemarks/{placemarkId}/submit
		tokenProtected.post("submit", use: submitPlacemark)
		
		let submission = routes.grouped("submission")
		
		// GET /placemarks/{placemarkId}/submission
		submission.get(use: getPlacemarkSubmissionReport)
		
		let reviews = submission.grouped("reviews")
		
		// GET /placemarks/{placemarkId}/submission/reviews
		reviews.get(use: listPlacemarkSubmissionReviews)
		
		let tokenProtectedReviews = reviews.grouped(UserModel.Token.authenticator())
		// POST /placemarks/{placemarkId}/submission/reviews
		tokenProtectedReviews.post(use: addPlacemarkSubmissionReview)
	}
	
	// MARK: - Route functions
	
	func submitPlacemark(req: Request) throws -> EventLoopFuture<Response> {
		let userId = try req.auth.require(UserModel.self, with: .bearer, in: req).requireID()
		let placemarkId = try req.parameters.require("placemarkId", as: PlacemarkModel.IDValue.self)
		
		let guardIsCreator = guardCreator(
			userId: userId, placemarkId: placemarkId,
			otherwise: "You cannot submit someone else's placemark!",
			in: req.db
		)
		
		let guardNoDuplicate = guardIsCreator
			.flatMap {
				SubmissionModel.query(on: req.db)
					.filter(\.$placemark.$id == placemarkId)
					.first()
			}
			.guard(\.isNil, else: Abort(.forbidden, reason: "You cannot submit a placemark twice!"))
			.transform(to: ())
		
		let submitPlacemarkFuture = guardNoDuplicate
			.flatMap { PlacemarkModel.find(placemarkId, on: req.db) }
			.unwrap(or: Abort(.notFound, reason: "Placemark not found"))
			.passthrough { $0.state = .submitted }
			.flatMap { $0.update(on: req.db) }
		
		let createSubmissionFuture = submitPlacemarkFuture
			.map { SubmissionModel(placemarkId: placemarkId) }
			.flatMap {
				$0.create(on: req.db)
					.transform(to: getLastSubmission(for: placemarkId, in: req.db))
			}
		
		return createSubmissionFuture
			.flatMap { $0.asPublic(on: req.db) }
			.flatMap { $0.encodeResponse(status: .created, for: req) }
	}
	
	func getPlacemarkSubmissionReport(req: Request) throws -> EventLoopFuture<Submission.Public> {
		let placemarkId = try req.parameters.require("placemarkId", as: PlacemarkModel.IDValue.self)
		
		return getLastSubmission(for: placemarkId, in: req.db)
			.flatMap { $0.asPublic(on: req.db) }
	}
	
	func listPlacemarkSubmissionReviews(req: Request) throws -> EventLoopFuture<[Review.Public]> {
		let placemarkId = try req.parameters.require("placemarkId", as: PlacemarkModel.IDValue.self)
		
		return getLastSubmission(for: placemarkId, in: req.db)
			.map { $0.reviews }
			.flatMapEach(on: req.eventLoop) { $0.asPublic(on: req.db) }
	}
	
	func addPlacemarkSubmissionReview(req: Request) throws -> EventLoopFuture<Review.Public> {
		let userId = try req.auth.require(UserModel.self, with: .bearer, in: req).requireID()
		let placemarkId = try req.parameters.require("placemarkId", as: PlacemarkModel.IDValue.self)
		
		// Validate and decode data
		try Review.Create.validate(content: req)
		let create = try req.content.decode(Review.Create.self)
		
		let updateSubmissionState = getLastSubmission(for: placemarkId, in: req.db)
			// FIXME: Set isModerator to true if user is a moderator
			.flatMap { $0.review(opinion: create.opinion, isModerator: false, on: req.db) }
		let publishPlacemarkIfNeeded = { (submission: SubmissionModel) -> EventLoopFuture<Void?>? in
			if submission.state == .accepted {
				return PlacemarkModel.find(placemarkId, on: req.db)
					.optionalFlatMap { placemark -> EventLoopFuture<Void> in
						placemark.state = .published
						return placemark.update(on: req.db)
					}
			}
			return nil
		}
		let addReview = { (submission: SubmissionModel) throws -> EventLoopFuture<ReviewModel> in
			let review = try ReviewModel(
				submissionId: submission.requireID(),
				reviewerId: userId,
				opinion: create.opinion,
				comment: create.comment ?? ""
			)
			return submission.$reviews.create(review, on: req.db)
				.transform(to: review)
		}
		let addIssues = { (review: ReviewModel) -> EventLoopFuture<Void> in
			let issues = create.issues ?? []
			let issuesObjects = issues.map { IssueModel(reviewId: userId, reason: $0.reason, comment: $0.comment) }
			return review.$issues.create(issuesObjects, on: req.db)
		}
		
		let guards = guardNotCreator(
			userId: userId, placemarkId: placemarkId,
			otherwise: "You cannot review your own submission!",
			in: req.db
		)
		.transform(to: guardNoDoubleReview(by: userId, for: placemarkId, in: req.db))
		
		let future = guards
			.transform(to: updateSubmissionState)
			.passthrough(publishPlacemarkIfNeeded)
			.flatMapThrowing(addReview)
			.flatMap { $0 }
			.passthrough(addIssues)
		
		return future
			.flatMap { $0.asPublic(on: req.db) }
	}
	
	// MARK: - Helper functions
	
	private func getLastSubmission(
		for placemarkId: PlacemarkModel.IDValue,
		in database: Database
	) -> EventLoopFuture<SubmissionModel> {
		SubmissionModel.query(on: database)
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
			// Get last submission
			.sort(\.$createdAt, .descending)
			.first()
			.unwrap(or: Abort(.notFound, reason: "No placemark submission found"))
	}
	
	private func guardCreator(
		userId: UserModel.IDValue,
		placemarkId: PlacemarkModel.IDValue,
		otherwise message: String,
		in database: Database
	) -> EventLoopFuture<Void> {
		PlacemarkModel.find(placemarkId, on: database)
			.unwrap(or: Abort(.notFound, reason: "Placemark not found"))
			.guard({ $0.$creator.id == userId }, else: Abort(.forbidden, reason: message))
			.transform(to: ())
	}
	
	/// Prevent user from reviewing his own submission
	private func guardNotCreator(
		userId: UserModel.IDValue,
		placemarkId: PlacemarkModel.IDValue,
		otherwise message: String,
		in database: Database
	) -> EventLoopFuture<Void> {
		PlacemarkModel.find(placemarkId, on: database)
			.unwrap(or: Abort(.notFound, reason: "Placemark not found"))
			.guard({ $0.$creator.id != userId }, else: Abort(.forbidden, reason: message))
			.transform(to: ())
	}
	
	/// Prevent user from reviewing twice the same submission
	private func guardNoDoubleReview(
		by userId: UserModel.IDValue,
		for placemarkId: PlacemarkModel.IDValue,
		in database: Database
	) -> EventLoopFuture<Void> {
		// Fetch all reviews
		ReviewModel.query(on: database)
			// From user `userId`
			.filter(\.$reviewer.$id == userId)
			// With a submission for placemark `placemarkId`
			.join(SubmissionModel.self, on: \ReviewModel.$submission.$id == \SubmissionModel.$id)
			.filter(SubmissionModel.self, \.$placemark.$id == placemarkId)
			.first()
			.guard(\.isNil, else: Abort(.forbidden, reason: "You cannot review a submission twice!"))
			.transform(to: ())
	}
	
}
