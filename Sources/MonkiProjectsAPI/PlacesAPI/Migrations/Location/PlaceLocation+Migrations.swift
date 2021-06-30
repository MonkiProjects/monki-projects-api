//
//  PlaceLocation+Migrations.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension PlaceModel.Location {
	
	enum Migrations {
		
		static var all: [Migration] {
			[CreatePlaceLocation()]
		}
		
	}
	
}
