//
//  PlacemarkType+Migrations.swift
//  App
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import MonkiMapModel

extension Placemark.Kind.Model {
	
	enum Migrations {
		
		typealias Migrated = Placemark.Kind
		
		static var all: [Migration] {
			return Category.Migrations.all
				+ [CreatePlacemarkType(), AddInitialTypes()]
		}
		
	}
	
}
