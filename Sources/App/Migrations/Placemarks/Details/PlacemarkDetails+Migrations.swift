//
//  PlacemarkDetails+Migrations.swift
//  App
//
//  Created by Rémi Bardon on 20/02/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension Models.Placemark.Details {
	
	enum Migrations {
		
		static var all: [Migration] {
			return Property.Migrations.all
				+ [CreatePlacemarkDetails()]
				+ Location.Migrations.all
				+ PlacemarkPropertyPivot.Migrations.all
		}
		
	}
	
}
