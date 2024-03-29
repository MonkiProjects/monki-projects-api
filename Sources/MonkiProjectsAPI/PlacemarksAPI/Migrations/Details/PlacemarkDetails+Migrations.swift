//
//  PlacemarkDetails+Migrations.swift
//  PlacemarksAPI
//
//  Created by Rémi Bardon on 20/02/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension PlacemarkModel.Details {
	
	enum Migrations {
		
		static var all: [Migration] {
			Property.Migrations.all
				+ [CreatePlacemarkDetails()]
				+ Location.Migrations.all
				+ PlacemarkPropertyPivot.Migrations.all
		}
		
	}
	
}
