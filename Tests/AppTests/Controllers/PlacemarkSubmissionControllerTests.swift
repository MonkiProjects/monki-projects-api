//
//  File.swift
//  App
//
//  Created by Rémi Bardon on 12/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

@testable import App
import XCTVapor
import Fluent

// swiftlint:disable:next type_body_length
final class PlacemarkSubmissionControllerTests: AppTestCase {
	
	typealias Submission = Placemark.Submission
	typealias Review = Submission.Review
	
	private static var users = [(User, User.Token)]()
	private static let placemarkId = UUID()
	private var placemark: Placemark?
	
	override class func setUp() {
		super.setUp()
		
		do {
			let app = try XCTUnwrap(self.app)
			
			// Create 4 users
			for _ in 1...4 {
				// Create user
				let user = User.dummy()
				try user.create(on: app.db).wait()
				
				// Create user token
				let userToken = try user.generateToken()
				try userToken.create(on: app.db).wait()
				
				self.users.append((user, userToken))
			}
		} catch {
			XCTFail(error.localizedDescription)
		}
	}
	
	override func setUpWithError() throws {
		try super.setUpWithError()
		
		let app = try Self.app.require()
		let user = try Self.users.first.require().0
		
		let placemark = try Placemark.dummy(
			id: Self.placemarkId,
			typeId: typeId(for: "training_spot", on: app.db).wait(),
			creatorId: user.requireID()
		)
		try placemark.create(on: app.db).wait()
		self.placemark = placemark
	}
	
	override func tearDownWithError() throws {
		try super.tearDownWithError()
		
		let app = try Self.app.require()
		
		try self.placemark?.delete(force: true, on: app.db).wait()
	}
	
	// MARK: - Valid Domain
	
	/// Tests `GET /placemarks/{placemarkId}/submit`.
	///
	/// - GIVEN:
	///     - A user
	///     - A placemark
	/// - WHEN:
	///     - The creator of the placemark submits it
	/// - THEN:
	///     - `HTTP` status should be `201 Created`
	///     - `body` should be the newly created `Submission`
	///     - The `Placemark` state should be `.submitted`
	///     - A `Submission` should be created with the state `.waitingForReviews`
	func testSubmitActuallySubmitsPlacemark() throws {
		let app = try XCTUnwrap(Self.app)
		let token = try XCTUnwrap(Self.users[0].1)
		XCTAssertEqual(self.placemark?.state, .private)
		
		try app.test(
			.GET, "v1/placemarks/\(Self.placemarkId)/submit",
			beforeRequest: { req in
				let bearerAuth = BearerAuthorization(token: token.value)
				req.headers.bearerAuthorization = bearerAuth
			},
			afterResponse: { res in
				try res.assertStatus(.created) {
					let submission = try res.content.decode(Submission.Public.self)
					
					XCTAssertEqual(submission.placemark, Self.placemarkId)
					XCTAssertEqual(submission.state, .waitingForReviews)
					XCTAssertTrue(submission.reviews.isEmpty)
					XCTAssertEqual(submission.positiveReviews, 0)
					XCTAssertEqual(submission.negativeReviews, 0)
					
					// Check placemark state
					let placemark = try XCTUnwrap(Placemark.find(Self.placemarkId, on: app.db).wait())
					XCTAssertEqual(placemark.state, .submitted)
					
					// Check creation of `Submission`
					let storedSubmission = try Submission.query(on: app.db)
						.filter(\.$placemark.$id == Self.placemarkId)
						.first()
						.wait()
					XCTAssertNotNil(storedSubmission)
				}
			}
		)
	}
	
	/// Tests `GET /placemarks/{placemarkId}/submission`.
	///
	/// - GIVEN:
	///     - A submitted placemark
	/// - WHEN:
	///     - Getting the submission report
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be the latest `Submission`
	func testGetSubmissionReport() throws {
		let app = try XCTUnwrap(Self.app)
		let (_, submissionId, _) = try submitPlacemark(on: app.db)
		
		try app.test(
			.GET, "v1/placemarks/\(Self.placemarkId)/submission",
			afterResponse: { res in
				try res.assertStatus(.ok) {
					let result = try res.content.decode(Submission.Public.self)
					
					XCTAssertEqual(result.id, submissionId)
					XCTAssertEqual(result.placemark, Self.placemarkId)
				}
			}
		)
	}
	
	/// Tests `POST /placemarks/{placemarkId}/submission/reviews`.
	///
	/// - GIVEN:
	///     - A submitted placemark
	/// - WHEN:
	///     - A user submits a positive review
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be the newly created `Review`
	///     - The submission should have one review
	///     - Submission counters should show 1 positive and 0 negative review
	///     - The reviewed placemark should not be published
	func testAddSubmissionReview() throws {
		let app = try XCTUnwrap(Self.app)
		let token = try XCTUnwrap(Self.users[1].1)
		let (_, submissionId, _) = try submitPlacemark(on: app.db)
		
		let create = Review.Create(
			opinion: .positive,
			comment: "Test comment",
			issues: [],
			moderated: false
		)
		
		try app.test(
			.POST, "v1/placemarks/\(Self.placemarkId)/submission/reviews",
			beforeRequest: { req in
				let bearerAuth = BearerAuthorization(token: token.value)
				req.headers.bearerAuthorization = bearerAuth
				
				try req.content.encode(create)
			},
			afterResponse: { res in
				try res.assertStatus(.ok) {
					let review = try res.content.decode(Review.Public.self)
					
					XCTAssertEqual(review.opinion, create.opinion)
					XCTAssertEqual(review.comment, create.comment)
					XCTAssertEqual(review.issues.count, 0)
					
					let submission = try XCTUnwrap(Submission.find(submissionId, on: app.db).wait())
					try submission.$reviews.load(on: app.db).wait()
					XCTAssertEqual(submission.reviews.count, 1)
					XCTAssertEqual(submission.positiveReviews, 1)
					XCTAssertEqual(submission.negativeReviews, 0)
					
					let placemark = try XCTUnwrap(Placemark.find(Self.placemarkId, on: app.db).wait())
					XCTAssertEqual(placemark.state, .submitted)
				}
			}
		)
	}
	
	/// Tests adding a review to a submission that needs changes.
	///
	/// - GIVEN:
	///     - A submitted placemark
	/// - WHEN:
	///     - A user submits a review saying the submission needs changes
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - `body` should be the newly created `Review`
	///     - The review should point to a new `Submission`
	///     - The old `Submission` should not have any review
	///     - The old `Submission` should be in the `.needsChanges` state
	///     - The new `Submission` should be in the `.waitingForChanges` state
	///     - The new `Submission` should have one review
	///     - All submission counters should show 0 positive and 0 negative review
	func testReviewSubmissionNeedsChangesCreatesNewSubmission() throws {
		let app = try XCTUnwrap(Self.app)
		let token = try XCTUnwrap(Self.users[1].1)
		let (_, submissionId, _) = try submitPlacemark(on: app.db)
		
		let create = Review.Create(
			opinion: .needsChanges,
			comment: "This placemark needs changes",
			issues: [
				.init(
					reason: .coordinates,
					comment: "The placemark is not correcly located"
				),
			],
			moderated: false
		)
		
		try app.test(
			.POST, "v1/placemarks/\(Self.placemarkId)/submission/reviews",
			beforeRequest: { req in
				let bearerAuth = BearerAuthorization(token: token.value)
				req.headers.bearerAuthorization = bearerAuth
				
				try req.content.encode(create)
			},
			afterResponse: { res in
				try res.assertStatus(.ok) {
					let review = try res.content.decode(Review.Public.self)
					
					XCTAssertNotEqual(review.submission, submissionId)
					XCTAssertEqual(review.opinion, create.opinion)
					XCTAssertEqual(review.comment, create.comment)
					XCTAssertEqual(review.issues.count, 1)
					
					let oldSubmission = try XCTUnwrap(Submission.find(submissionId, on: app.db).wait())
					try oldSubmission.$reviews.load(on: app.db).wait()
					XCTAssertEqual(oldSubmission.state, .needsChanges)
					XCTAssertEqual(oldSubmission.reviews.count, 0)
					XCTAssertEqual(oldSubmission.positiveReviews, 0)
					XCTAssertEqual(oldSubmission.negativeReviews, 0)
					
					let newSubmission = try XCTUnwrap(Submission.find(review.submission, on: app.db).wait())
					try newSubmission.$reviews.load(on: app.db).wait()
					XCTAssertEqual(newSubmission.state, .waitingForChanges)
					XCTAssertEqual(newSubmission.reviews.count, 1)
					XCTAssertEqual(newSubmission.positiveReviews, 0)
					XCTAssertEqual(newSubmission.negativeReviews, 0)
				}
			}
		)
	}
	
	/// Tests that adding enough reviews will publish a submitted placemark.
	///
	/// - GIVEN:
	///     - A submitted placemark
	///     - Enough users to publish the placemark
	/// - WHEN:
	///     - A user submits a review saying the submission needs changes
	/// - THEN:
	///     - `HTTP` status should be `200 OK`
	///     - The reviewed placemark should be published
	///
	/// # Notes: #
	/// 1. Could pass if used count was review count and not **positive** review count
	func testEnoughReviewsSubmitsPlacemark() throws {
		let app = try XCTUnwrap(Self.app)
		let token = try XCTUnwrap(Self.users[1].1)
		let (_, submissionId, submission) = try submitPlacemark(on: app.db)
		
		submission.positiveReviews = Submission.positiveReviewCountToValidate - 1
		try submission.update(on: app.db).wait()
		
		let create = Review.Create(
			opinion: .positive,
			comment: "Looks great!",
			issues: [],
			moderated: false
		)
		
		try app.test(
			.POST, "v1/placemarks/\(Self.placemarkId)/submission/reviews",
			beforeRequest: { req in
				let bearerAuth = BearerAuthorization(token: token.value)
				req.headers.bearerAuthorization = bearerAuth
				
				try req.content.encode(create)
			},
			afterResponse: { res in
				try res.assertStatus(.ok) {
					_ = try res.content.decode(Review.Public.self)
					
					let submission = try XCTUnwrap(Submission.find(submissionId, on: app.db).wait())
					try submission.$reviews.load(on: app.db).wait()
					XCTAssertEqual(submission.state, .accepted)
					XCTAssertEqual(submission.positiveReviews, Submission.positiveReviewCountToValidate)
					XCTAssertEqual(submission.negativeReviews, 0)
					
					let placemark = try XCTUnwrap(Placemark.find(Self.placemarkId, on: app.db).wait())
					XCTAssertEqual(placemark.state, .published)
				}
			}
		)
	}
	
	// MARK: - Invalid Domain
	
	/// Tests that a user cannot submit someone else's placemark.
	///
	/// - GIVEN:
	///     - A placemark
	///     - A user that's not the creator of the placemark
	/// - WHEN:
	///     - The user tries to submit the placemark
	/// - THEN:
	///     - `HTTP` status should be `403 Forbidden`
	///     - `body` should be the `"You cannot submit someone else's placemark!"`
	func testCannotSubmitSomeoneElsesPlacemark() throws {
		let app = try XCTUnwrap(Self.app)
		let token = try XCTUnwrap(Self.users[1].1)
		XCTAssertEqual(self.placemark?.state, .private)
		
		try app.test(
			.GET, "v1/placemarks/\(Self.placemarkId)/submit",
			beforeRequest: { req in
				let bearerAuth = BearerAuthorization(token: token.value)
				req.headers.bearerAuthorization = bearerAuth
			},
			afterResponse: { res in
				try res.assertError(
					status: .forbidden,
					reason: "You cannot submit someone else's placemark!"
				)
				
				// Check placemark state
				let placemark = try XCTUnwrap(Placemark.find(Self.placemarkId, on: app.db).wait())
				XCTAssertEqual(placemark.state, .private)
				
				// Check no creation of `Submission`
				let storedSubmission = try Submission.query(on: app.db)
					.filter(\.$placemark.$id == Self.placemarkId)
					.first()
					.wait()
				XCTAssertNil(storedSubmission)
			}
		)
	}
	
	/// Tests that a user cannot submit their placemark twice.
	///
	/// - GIVEN:
	///     - A user
	///     - A user's placemark already submitted
	/// - WHEN:
	///     - The user tries to submit the placemark again
	/// - THEN:
	///     - `HTTP` status should be `403 Forbidden`
	///     - `body` should be the `"You cannot submit a placemark twice!"`
	func testCannotSubmitAPlacemarkTwice() throws {
		let app = try XCTUnwrap(Self.app)
		let token = try XCTUnwrap(Self.users[0].1)
		let (_, submissionId, _) = try submitPlacemark(on: app.db)
		
		try app.test(
			.GET, "v1/placemarks/\(Self.placemarkId)/submit",
			beforeRequest: { req in
				let bearerAuth = BearerAuthorization(token: token.value)
				req.headers.bearerAuthorization = bearerAuth
			},
			afterResponse: { res in
				try res.assertError(
					status: .forbidden,
					reason: "You cannot submit a placemark twice!"
				)
				
				// Check placemark state
				let placemark = try XCTUnwrap(Placemark.find(Self.placemarkId, on: app.db).wait())
				XCTAssertEqual(placemark.state, .submitted)
				
				// Check no creation of `Submission`
				let storedSubmissions = try Submission.query(on: app.db)
					.filter(\.$placemark.$id == Self.placemarkId)
					.all()
					.wait()
				XCTAssertEqual(storedSubmissions.count, 1)
				XCTAssertEqual(storedSubmissions.first?.id, submissionId)
			}
		)
	}
	
	/// Tests that a user cannot review their own submission.
	///
	/// - GIVEN:
	///     - A submitted placemark
	/// - WHEN:
	///     - The creator of the placemark tries to review their own submission
	/// - THEN:
	///     - `HTTP` status should be `403 Forbidden`
	///     - `body` should be `"You cannot review your own submission!"`
	///     - The submission should have no review
	///     - Submission counters should show 0 positive and 0 negative review
	func testCreatorCannotReviewOwnPlacemark() throws {
		let app = try XCTUnwrap(Self.app)
		let token = try XCTUnwrap(Self.users[0].1)
		let (_, submissionId, _) = try submitPlacemark(on: app.db)
		
		let create = Review.Create(
			opinion: .positive,
			comment: "Test comment",
			issues: [],
			moderated: false
		)
		
		try app.test(
			.POST, "v1/placemarks/\(Self.placemarkId)/submission/reviews",
			beforeRequest: { req in
				let bearerAuth = BearerAuthorization(token: token.value)
				req.headers.bearerAuthorization = bearerAuth
				
				try req.content.encode(create)
			},
			afterResponse: { res in
				try res.assertError(
					status: .forbidden,
					reason: "You cannot review your own submission!"
				)
				
				let submission = try XCTUnwrap(Submission.find(submissionId, on: app.db).wait())
				try submission.$reviews.load(on: app.db).wait()
				XCTAssertEqual(submission.reviews.count, 0)
				XCTAssertEqual(submission.positiveReviews, 0)
				XCTAssertEqual(submission.negativeReviews, 0)
			}
		)
	}
	
	/// Tests that a user cannot review their own submission.
	///
	/// - GIVEN:
	///     - A submitted placemark
	///     - A user
	///     - A submission from the user
	/// - WHEN:
	///     - The user tries to review the same submission again
	/// - THEN:
	///     - `HTTP` status should be `403 Forbidden`
	///     - `body` should be `"You cannot review a submission twice!"`
	///     - The submission should have no review
	///     - Submission counters should show 0 positive and 0 negative review
	func testCannotReviewSubmissionTwice() throws {
		let app = try XCTUnwrap(Self.app)
		let userId = try XCTUnwrap(Self.users[1].0)
		let token = try XCTUnwrap(Self.users[1].1)
		let (_, submissionId, submission) = try submitPlacemark(on: app.db)
		
		let firstReview = try Review(
			submissionId: submissionId,
			reviewerId: userId.requireID(),
			opinion: .positive,
			comment: "Test comment 1"
		)
		try submission.$reviews.create(firstReview, on: app.db).wait()
		submission.positiveReviews += 1
		try submission.update(on: app.db).wait()
		
		let create = Review.Create(
			opinion: .positive,
			comment: "Test comment 2",
			issues: [],
			moderated: false
		)
		
		try app.test(
			.POST, "v1/placemarks/\(Self.placemarkId)/submission/reviews",
			beforeRequest: { req in
				let bearerAuth = BearerAuthorization(token: token.value)
				req.headers.bearerAuthorization = bearerAuth
				
				try req.content.encode(create)
			},
			afterResponse: { res in
				try res.assertError(
					status: .forbidden,
					reason: "You cannot review a submission twice!"
				)
				
				let submission = try XCTUnwrap(Submission.find(submissionId, on: app.db).wait())
				try submission.$reviews.load(on: app.db).wait()
				XCTAssertEqual(submission.reviews.count, 1)
				XCTAssertEqual(submission.positiveReviews, 1)
				XCTAssertEqual(submission.negativeReviews, 0)
			}
		)
	}
	
	/// Tests that a submission cannot be reviewed after it has been marked as "needing changes".
	///
	/// - GIVEN:
	///     - A submitted placemark
	///     - Two users
	///     - A first submission marked as needing changes by one user
	/// - WHEN:
	///     - The other user tries to review the first submission
	/// - THEN:
	///     - `HTTP` status should be `403 Forbidden`
	///     - `body` should be `"This submission has been closed because it needed changes"`
	///     - The submission should have only one review
	///     - Submission counters should show 0 positive and 0 negative review
	func testCannotReviewSubmissionThatNeedsChanges() throws {
		let app = try XCTUnwrap(Self.app)
		let firstUserId = try XCTUnwrap(Self.users[1].0)
		let secondUserToken = try XCTUnwrap(Self.users[2].1)
		let (_, submissionId, submission) = try submitPlacemark(on: app.db)
		
		let firstReview = try Review(
			submissionId: submissionId,
			reviewerId: firstUserId.requireID(),
			opinion: .needsChanges,
			comment: "Test comment 1"
		)
		try submission.$reviews.create(firstReview, on: app.db).wait()
		submission.state = .needsChanges
		try submission.update(on: app.db).wait()
		
		let create = Review.Create(
			opinion: .positive,
			comment: "Test comment 2",
			issues: [],
			moderated: false
		)
		
		try app.test(
			.POST, "v1/placemarks/\(Self.placemarkId)/submission/reviews",
			beforeRequest: { req in
				let bearerAuth = BearerAuthorization(token: secondUserToken.value)
				req.headers.bearerAuthorization = bearerAuth
				
				try req.content.encode(create)
			},
			afterResponse: { res in
				try res.assertError(
					status: .forbidden,
					reason: "This submission has been closed because it needed changes"
				)
				
				let submission = try XCTUnwrap(Submission.find(submissionId, on: app.db).wait())
				try submission.$reviews.load(on: app.db).wait()
				XCTAssertEqual(submission.reviews.count, 1)
				XCTAssertEqual(submission.positiveReviews, 0)
				XCTAssertEqual(submission.negativeReviews, 0)
			}
		)
	}
	
	/// Tests that a submission cannot be reviewed after it has been marked as "accepted".
	///
	/// - GIVEN:
	///     - A submitted placemark
	///     - Two users
	///     - A first submission marked as accepted by one user (moderator)
	/// - WHEN:
	///     - The other user tries to review the first submission
	/// - THEN:
	///     - `HTTP` status should be `403 Forbidden`
	///     - `body` should be `"This place has already been accepted"`
	///     - The submission should have only one review
	///     - Submission counters should show 1 positive and 0 negative review
	func testCannotReviewAcceptedSubmission() throws {
		let app = try XCTUnwrap(Self.app)
		let firstUserId = try XCTUnwrap(Self.users[1].0)
		let secondUserToken = try XCTUnwrap(Self.users[2].1)
		let (_, submissionId, submission) = try submitPlacemark(on: app.db)
		
		let firstReview = try Review(
			submissionId: submissionId,
			reviewerId: firstUserId.requireID(),
			opinion: .positive,
			comment: "Test comment 1",
			moderated: true
		)
		try submission.$reviews.create(firstReview, on: app.db).wait()
		submission.state = .accepted
		submission.positiveReviews += 1
		try submission.update(on: app.db).wait()
		
		let create = Review.Create(
			opinion: .positive,
			comment: "Test comment 2",
			issues: [],
			moderated: false
		)
		
		try app.test(
			.POST, "v1/placemarks/\(Self.placemarkId)/submission/reviews",
			beforeRequest: { req in
				let bearerAuth = BearerAuthorization(token: secondUserToken.value)
				req.headers.bearerAuthorization = bearerAuth
				
				try req.content.encode(create)
			},
			afterResponse: { res in
				try res.assertError(
					status: .forbidden,
					reason: "This place has already been accepted"
				)
				
				let submission = try XCTUnwrap(Submission.find(submissionId, on: app.db).wait())
				try submission.$reviews.load(on: app.db).wait()
				XCTAssertEqual(submission.reviews.count, 1)
				XCTAssertEqual(submission.positiveReviews, 1)
				XCTAssertEqual(submission.negativeReviews, 0)
			}
		)
	}
	
	/// Tests that a submission cannot be reviewed after it has been marked as "rejected".
	///
	/// - GIVEN:
	///     - A submitted placemark
	///     - Two users
	///     - A first submission marked as rejected by one user (moderator)
	/// - WHEN:
	///     - The other user tries to review the first submission
	/// - THEN:
	///     - `HTTP` status should be `403 Forbidden`
	///     - `body` should be `"This place has been rejected"`
	///     - The submission should have only one review
	///     - Submission counters should show 0 positive and 1 negative review
	func testCannotReviewRejectedSubmission() throws {
		let app = try XCTUnwrap(Self.app)
		let firstUserId = try XCTUnwrap(Self.users[1].0)
		let secondUserToken = try XCTUnwrap(Self.users[2].1)
		let (_, submissionId, submission) = try submitPlacemark(on: app.db)
		
		let firstReview = try Review(
			submissionId: submissionId,
			reviewerId: firstUserId.requireID(),
			opinion: .negative,
			comment: "Test comment 1",
			moderated: true
		)
		try submission.$reviews.create(firstReview, on: app.db).wait()
		submission.state = .rejected
		submission.negativeReviews += 1
		try submission.update(on: app.db).wait()
		
		let create = Review.Create(
			opinion: .positive,
			comment: "Test comment 2",
			issues: [],
			moderated: false
		)
		
		try app.test(
			.POST, "v1/placemarks/\(Self.placemarkId)/submission/reviews",
			beforeRequest: { req in
				let bearerAuth = BearerAuthorization(token: secondUserToken.value)
				req.headers.bearerAuthorization = bearerAuth
				
				try req.content.encode(create)
			},
			afterResponse: { res in
				try res.assertError(
					status: .forbidden,
					reason: "This place has been rejected"
				)
				
				let submission = try XCTUnwrap(Submission.find(submissionId, on: app.db).wait())
				try submission.$reviews.load(on: app.db).wait()
				XCTAssertEqual(submission.reviews.count, 1)
				XCTAssertEqual(submission.positiveReviews, 0)
				XCTAssertEqual(submission.negativeReviews, 1)
			}
		)
	}
	
	/// Tests that a submission cannot be reviewed after it has been marked as "rejected".
	///
	/// - GIVEN:
	///     - A submitted placemark
	///     - Two users
	///     - A first submission marked as rejected by one user (moderator)
	/// - WHEN:
	///     - The other user tries to review the first submission
	/// - THEN:
	///     - `HTTP` status should be `403 Forbidden`
	///     - `body` should be `"This place has been rejected"`
	///     - The submission should have only one review
	///     - Submission counters should show 0 positive and 1 negative review
	func testCannotReviewModeratedSubmission() throws {
		let app = try XCTUnwrap(Self.app)
		let token = try XCTUnwrap(Self.users[2].1)
		let (_, submissionId, submission) = try submitPlacemark(on: app.db)
		
		submission.state = .moderated
		try submission.update(on: app.db).wait()
		
		let create = Review.Create(
			opinion: .positive,
			comment: "Test comment",
			issues: [],
			moderated: false
		)
		
		try app.test(
			.POST, "v1/placemarks/\(Self.placemarkId)/submission/reviews",
			beforeRequest: { req in
				let bearerAuth = BearerAuthorization(token: token.value)
				req.headers.bearerAuthorization = bearerAuth
				
				try req.content.encode(create)
			},
			afterResponse: { res in
				try res.assertError(
					status: .forbidden,
					reason: "This place has been moderated"
				)
				
				let submission = try XCTUnwrap(Submission.find(submissionId, on: app.db).wait())
				try submission.$reviews.load(on: app.db).wait()
				XCTAssertEqual(submission.reviews.count, 0)
				XCTAssertEqual(submission.positiveReviews, 0)
				XCTAssertEqual(submission.negativeReviews, 0)
			}
		)
	}
	
	// MARK: - Helper Functions
	
	// swiftlint:disable:next large_tuple
	private func submitPlacemark(on database: Database) throws -> (Placemark, UUID, Submission) {
		let placemark = try XCTUnwrap(self.placemark)
		placemark.state = .submitted
		try placemark.update(on: database).wait()
		
		let submissionId = UUID()
		let submission = Submission(
			id: submissionId,
			placemarkId: Self.placemarkId
		)
		try submission.create(on: database).wait()
		
		return (placemark, submissionId, submission)
	}
	
}
// swiftlint:disable:this file_length
