//
//  PlacemarkSubmissionReviewIssue+Reason.swift
//  App
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor

extension Placemark.Submission.Review.Issue {
	
	enum Reason: String, Content, CaseIterable {
		case name, coordinates, type, caption, satelliteImage, images,
			 location, property, other
	}
	
}
