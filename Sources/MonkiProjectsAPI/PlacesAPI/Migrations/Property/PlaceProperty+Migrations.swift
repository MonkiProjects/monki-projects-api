//
//  PlaceProperty+Migrations.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension PlaceModel.Property {
	
	enum Migrations {
		
		typealias Migrated = PlaceModel.Property
		
		static var all: [Migration] {
			[CreatePlaceProperty(), AddInitialProperties()]
		}
		
	}
	
}
