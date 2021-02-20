//
//  Placemark+Migrations.swift
//  App
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import MonkiMapModel

extension Models.Placemark {
	
	enum Migrations {
		
		static var all: [Migration] {
			return Kind.Migrations.all
				+ Property.Migrations.all
				+ Location.Migrations.all
				+ [CreatePlacemark()]
				+ PlacemarkPropertyPivot.Migrations.all
				+ Submission.Migrations.all
		}
		
	}
	
}
