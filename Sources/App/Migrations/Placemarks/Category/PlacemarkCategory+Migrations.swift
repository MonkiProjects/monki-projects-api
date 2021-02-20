//
//  PlacemarkCategory+Migrations.swift
//  App
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension Models.Placemark.Category {
	
	enum Migrations {
		
		typealias Migrated = Models.Placemark.Category
		
		static var all: [Migration] {
			return [CreatePlacemarkCategory(), AddInitialCategories()]
		}
		
	}
	
}
