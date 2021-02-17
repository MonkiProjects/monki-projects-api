//
//  PlacemarkSubmissionReview+Migrations.swift
//  App
//
//  Created by Rémi Bardon on 11/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import MonkiMapModel

extension Placemark.Submission.Review.Model {
	
	enum Migrations {
		
		static var all: [Migration] {
			return [CreatePlacemarkSubmissionReview()]
				+ Issue.Migrations.all
		}
		
	}
	
}
