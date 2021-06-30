//
//  PlaceCategory+Migrations.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension PlaceModel.Category {
	
	enum Migrations {
		
		typealias Migrated = PlaceModel.Category
		
		static var all: [Migration] {
			[CreatePlaceCategory(), AddInitialCategories()]
		}
		
	}
	
}
