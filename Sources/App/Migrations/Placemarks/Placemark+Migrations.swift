//
//  Placemark+Migrations.swift
//  App
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension Placemark {
	
	enum Migrations {
		
		static var all: [Migration] {
			return Category.Migrations.all
				+ PlacemarkType.Migrations.all
				+ Property.Migrations.all
				+ Location.Migrations.all
				+ [CreatePlacemark()]
				+ PlacemarkPropertyPivot.Migrations.all
		}
		
	}
	
}
