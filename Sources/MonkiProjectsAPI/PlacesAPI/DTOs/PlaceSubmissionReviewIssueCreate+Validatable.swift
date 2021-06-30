//
//  PlaceSubmissionReviewIssueCreate+Validatable.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 11/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import MonkiMapModel

extension Place.Submission.Review.Issue.Create: Content, Validatable {
	
	public static func validations(_ validations: inout Validations) {
		validations.add(
			"reason", as: String.self,
			is: .in(Place.Submission.Review.Issue.Reason.allCases.map(\.rawValue))
		)
		validations.add("comment", as: String.self, is: .count(4...))
	}
	
}
