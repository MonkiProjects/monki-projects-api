//
//  PlacemarkSubmissionReviewIssue+Create.swift
//  App
//
//  Created by Rémi Bardon on 11/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor

extension Placemark.Submission.Review.Issue {
	
	struct Create: Content {
		let reason: Reason
		let comment: String
	}
	
}

extension Placemark.Submission.Review.Issue.Create: Validatable {
	
	static func validations(_ validations: inout Validations) {
		validations.add(
			"reason", as: String.self,
			is: .in(Placemark.Submission.Review.Issue.Reason.allCases.map(\.rawValue))
		)
		validations.add("comment", as: String.self, is: .count(4...))
	}
	
}
