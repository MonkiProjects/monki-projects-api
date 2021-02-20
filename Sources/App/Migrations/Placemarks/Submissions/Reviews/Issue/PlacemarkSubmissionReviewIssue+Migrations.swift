//
//  PlacemarkSubmissionReviewIssue+Migrations.swift
//  App
//
//  Created by Rémi Bardon on 11/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension Models.Placemark.Submission.Review.Issue {
	
	enum Migrations {
		
		static var all: [Migration] {
			return [CreatePlacemarkSubmissionReviewIssue()]
		}
		
	}
	
}
