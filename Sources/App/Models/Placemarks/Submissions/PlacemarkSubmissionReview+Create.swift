//
//  PlacemarkSubmissionReview+Create.swift
//  App
//
//  Created by Rémi Bardon on 11/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import MonkiMapModel

extension Placemark.Submission.Review.Create: Validatable {
	
	public static func validations(_ validations: inout Validations) {
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
