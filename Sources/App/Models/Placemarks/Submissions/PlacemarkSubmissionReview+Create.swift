//
//  PlacemarkSubmissionReview+Create.swift
//  App
//
//  Created by Rémi Bardon on 11/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor

extension Placemark.Submission.Review {
	
	struct Create: Content {
		let opinion: Opinion
		let comment: String?
		// TODO: For some reason, not providing an "issues" array causes
		//       "issues failed to decode: keyNotFound(issues,
		//       Swift.DecodingError.Context(codingPath: [],
		//       debugDescription: \"Cannot get UnkeyedDecodingContainer --
		//       no value found for key issues (\\\"issues\\\")\", underlyingError: nil))"
		//       Probably caused by Vapor's Content decoding, because no validation error happens
		let issues: [Issue.Create]?
		let moderated: Bool?
	}
	
}

extension Placemark.Submission.Review.Create: Validatable {
	
	static func validations(_ validations: inout Validations) {
		validations.add(
			"opinion", as: String.self,
			is: .in(Placemark.Submission.Review.Opinion.allCases.map(\.rawValue))
		)
		validations.add("comment", as: String.self, required: false)
		validations.add(each: "issues", required: false) { _, validations in
			Placemark.Submission.Review.Issue.Create.validations(&validations)
		}
		validations.add("moderated", as: Bool.self, required: false)
	}
	
}
