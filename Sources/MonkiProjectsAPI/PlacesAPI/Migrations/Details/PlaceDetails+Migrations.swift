//
//  PlaceDetails+Migrations.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 20/02/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension PlaceModel.Details {
	
	enum Migrations {
		
		static var all: [Migration] {
			Property.Migrations.all
				+ [CreatePlaceDetails()]
				+ Location.Migrations.all
				+ PlacePropertyPivot.Migrations.all
		}
		
	}
	
}
