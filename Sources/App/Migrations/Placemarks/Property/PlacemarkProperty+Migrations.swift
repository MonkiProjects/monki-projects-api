//
//  PlacemarkProperty+Migrations.swift
//  App
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension Models.Placemark.Property {
	
	enum Migrations {
		
		typealias Migrated = Models.Placemark.Property
		
		static var all: [Migration] {
			return [CreatePlacemarkProperty(), AddInitialProperties()]
		}
		
	}
	
}
