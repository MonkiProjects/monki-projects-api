//
//  PlacemarkCategory+Migrations.swift
//  App
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import MonkiMapModel

extension Placemark.Category.Model {
	
	enum Migrations {
		
		typealias Migrated = Placemark.Category
		
		static var all: [Migration] {
			return [CreatePlacemarkCategory(), AddInitialCategories()]
		}
		
	}
	
}
