//
//  PlacemarkSubmissionReview+Migrations.swift
//  Migrations
//
//  Created by Rémi Bardon on 11/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Models

extension PlacemarkModel.Submission.Review {
	
	enum Migrations {
		
		static var all: [Migration] {
			[CreatePlacemarkSubmissionReview()]
				+ Issue.Migrations.all
		}
		
	}
	
}
