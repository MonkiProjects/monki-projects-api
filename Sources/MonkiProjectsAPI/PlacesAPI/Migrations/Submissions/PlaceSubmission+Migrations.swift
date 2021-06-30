//
//  PlaceSubmission+Migrations.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 11/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension PlaceModel.Submission {
	
	enum Migrations {
		
		static var all: [Migration] {
			[CreatePlaceSubmission()]
				+ Review.Migrations.all
		}
		
	}
	
}
