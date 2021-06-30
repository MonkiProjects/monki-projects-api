//
//  PlaceSubmissionControllerV1.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor
import MonkiMapModel

internal struct PlaceSubmissionControllerV1: RouteCollection {
	
	typealias Submission = Place.Submission
	typealias Review = Submission.Review
	
	typealias SubmissionModel = PlaceModel.Submission
	typealias ReviewModel = SubmissionModel.Review
	typealias IssueModel = ReviewModel.Issue
	
	// MARK: - Routes
	
	/// Routes start at `/places/v1/{placeId}`
	func boot(routes: RoutesBuilder) throws {
		let tokenProtected = routes.grouped([
			AuthErrorMiddleware(type: "Bearer", realm: "Bearer authentication required."),
			UserModel.Token.authenticator(),
		])
		
		// POST /places/v1/{placeId}/submit
		tokenProtected.post("submit", use: submitPlace)
		
		let submission = routes.grouped("submission")
		
		// GET /places/v1/{placeId}/submission
		submission.get(use: getPlaceSubmissionReport)
		
		let reviews = submission.grouped("reviews")
		
		// GET /places/v1/{placeId}/submission/reviews
		reviews.get(use: listPlaceSubmissionReviews)
		
		let tokenProtectedReviews = reviews.grouped([
			AuthErrorMiddleware(type: "Bearer", realm: "Bearer authentication required."),
			UserModel.Token.authenticator(),
		])
		// POST /places/v1/{placeId}/submission/reviews
		tokenProtectedReviews.post(use: addPlaceSubmissionReview)
	}
	
	// MARK: - Route functions
	
	func submitPlace(req: Request) throws -> EventLoopFuture<Response> {
		let userId = try req.auth.require(UserModel.self, with: .bearer, in: req).requireID()
		let placeId = try req.parameters.require("placeId", as: PlaceModel.IDValue.self)
		
		let guardIsCreator = guardCreator(
			userId: userId, placeId: placeId,
			otherwise: "You cannot submit someone else's place!",
			in: req.db
		)
		
		let guardNoDuplicate = guardIsCreator
			.flatMap {
				SubmissionModel.query(on: req.db)
					.filter(\.$place.$id == placeId)
					.first()
			}
			.guard(\.isNil, else: Abort(.forbidden, reason: "You cannot submit a place twice!"))
			.transform(to: ())
		
		let submitPlaceFuture = guardNoDuplicate
			.flatMap { PlaceModel.find(placeId, on: req.db) }
			.unwrap(or: Abort(.notFound, reason: "Place not found"))
			.passthrough { $0.state = .submitted }
			.flatMap { $0.update(on: req.db) }
		
		let createSubmissionFuture = submitPlaceFuture
			.map { SubmissionModel(placeId: placeId) }
			.flatMap {
				$0.create(on: req.db)
					.transform(to: getLastSubmission(for: placeId, in: req.db))
			}
		
		return createSubmissionFuture
			.flatMap { $0.asPublic(on: req) }
			.flatMap { $0.encodeResponse(status: .created, for: req) }
	}
	
	func getPlaceSubmissionReport(req: Request) throws -> EventLoopFuture<Submission.Public> {
		let placeId = try req.parameters.require("placeId", as: PlaceModel.IDValue.self)
		
		return getLastSubmission(for: placeId, in: req.db)
			.flatMap { $0.asPublic(on: req) }
	}
	
	func listPlaceSubmissionReviews(req: Request) throws -> EventLoopFuture<Page<Review.Public>> {
		let placeId = try req.parameters.require("placeId", as: PlaceModel.IDValue.self)
		
		return getLastSubmission(for: placeId, in: req.db)
			.flatMapThrowing { try $0.requireID() }
			.flatMap { submissionId in
				ReviewModel.query(on: req.db)
					.filter(\.$submission.$id == submissionId)
					.paginate(for: req)
					.asPublic(on: req)
			}
	}
	
	func addPlaceSubmissionReview(req: Request) throws -> EventLoopFuture<Review.Public> {
		let userId = try req.auth.require(UserModel.self, with: .bearer, in: req).requireID()
		let placeId = try req.parameters.require("placeId", as: PlaceModel.IDValue.self)
		
		// Validate and decode data
		try Review.Create.validate(content: req)
		let create = try req.content.decode(Review.Create.self)
		
		let updateSubmissionState = { () -> EventLoopFuture<SubmissionModel> in
			getLastSubmission(for: placeId, in: req.db)
				// FIXME: Set isModerator to true if user is a moderator
				.flatMap { $0.review(opinion: create.opinion, isModerator: false, on: req.db) }
		}
		let publishPlaceIfNeeded = { (submission: SubmissionModel) -> EventLoopFuture<Void?>? in
			if submission.state == .accepted {
				return PlaceModel.find(placeId, on: req.db)
					.optionalFlatMap { place -> EventLoopFuture<Void> in
						place.state = .published
						return place.update(on: req.db)
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
			let issuesObjects = create.issues
				.map { IssueModel(reviewId: userId, reason: $0.reason, comment: $0.comment) }
			return review.$issues.create(issuesObjects, on: req.db)
		}
		
		let guards = guardNotCreator(
			userId: userId, placeId: placeId,
			otherwise: "You cannot review your own submission!",
			in: req.db
		)
		.transform(to: guardNoDoubleReview(by: userId, for: placeId, in: req.db))
		
		let future = guards
			.flatMap(updateSubmissionState)
			.passthrough(publishPlaceIfNeeded)
			.flatMapThrowing(addReview)
			.flatMap { $0 }
			.passthrough(addIssues)
		
		return future
			.flatMap { $0.asPublic(on: req) }
	}
	
	// MARK: - Helper functions
	
	private func getLastSubmission(
		for placeId: PlaceModel.IDValue,
		in database: Database
	) -> EventLoopFuture<SubmissionModel> {
		SubmissionModel.query(on: database)
			.with(\.$place)
			.filter(\.$place.$id == placeId)
			// Get last submission
			.sort(\.$createdAt, .descending)
			.first()
			.unwrap(or: Abort(.notFound, reason: "No place submission found"))
	}
	
	private func guardCreator(
		userId: UserModel.IDValue,
		placeId: PlaceModel.IDValue,
		otherwise message: String,
		in database: Database
	) -> EventLoopFuture<Void> {
		PlaceModel.find(placeId, on: database)
			.unwrap(or: Abort(.notFound, reason: "Place not found"))
			.guard({ $0.$creator.id == userId }, else: Abort(.forbidden, reason: message))
			.transform(to: ())
	}
	
	/// Prevent user from reviewing his own submission
	private func guardNotCreator(
		userId: UserModel.IDValue,
		placeId: PlaceModel.IDValue,
		otherwise message: String,
		in database: Database
	) -> EventLoopFuture<Void> {
		PlaceModel.find(placeId, on: database)
			.unwrap(or: Abort(.notFound, reason: "Place not found"))
			.guard({ $0.$creator.id != userId }, else: Abort(.forbidden, reason: message))
			.transform(to: ())
	}
	
	/// Prevent user from reviewing twice the same submission
	private func guardNoDoubleReview(
		by userId: UserModel.IDValue,
		for placeId: PlaceModel.IDValue,
		in database: Database
	) -> EventLoopFuture<Void> {
		// Fetch all reviews
		ReviewModel.query(on: database)
			// From user `userId`
			.filter(\.$reviewer.$id == userId)
			// With a submission for place `placeId`
			.join(SubmissionModel.self, on: \ReviewModel.$submission.$id == \SubmissionModel.$id)
			.filter(SubmissionModel.self, \.$place.$id == placeId)
			.first()
			.guard(\.isNil, else: Abort(.forbidden, reason: "You cannot review a submission twice!"))
			.transform(to: ())
	}
	
}
