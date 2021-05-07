//
//  PlacemarkCategory+Migrations.swift
//  PlacemarksAPI
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension PlacemarkModel.Category {
	
	enum Migrations {
		
		typealias Migrated = PlacemarkModel.Category
		
		static var all: [Migration] {
			[CreatePlacemarkCategory(), AddInitialCategories()]
		}
		
	}
	
}
