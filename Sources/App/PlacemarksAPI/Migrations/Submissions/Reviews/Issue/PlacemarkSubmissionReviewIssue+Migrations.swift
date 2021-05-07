//
//  PlacemarkSubmissionReviewIssue+Migrations.swift
//  PlacemarksAPI
//
//  Created by Rémi Bardon on 11/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension PlacemarkModel.Submission.Review.Issue {
	
	enum Migrations {
		
		static var all: [Migration] {
			[CreatePlacemarkSubmissionReviewIssue()]
		}
		
	}
	
}
