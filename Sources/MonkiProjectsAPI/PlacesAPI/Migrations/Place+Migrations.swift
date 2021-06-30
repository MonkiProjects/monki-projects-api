//
//  Place+Migrations.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension PlaceModel {
	
	public enum Migrations {
		
		public static var all: [Migration] {
			Kind.Migrations.all
				+ [CreatePlace()]
				+ Details.Migrations.all
				+ Submission.Migrations.all
		}
		
	}
	
}
