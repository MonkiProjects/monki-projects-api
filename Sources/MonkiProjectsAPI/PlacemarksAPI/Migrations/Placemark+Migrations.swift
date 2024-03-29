//
//  Placemark+Migrations.swift
//  PlacemarksAPI
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension PlacemarkModel {
	
	public enum Migrations {
		
		public static var all: [Migration] {
			Kind.Migrations.all
				+ [CreatePlacemark()]
				+ Details.Migrations.all
				+ Submission.Migrations.all
		}
		
	}
	
}
