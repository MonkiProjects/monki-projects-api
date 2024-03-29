//
//  PlacemarkProperty+Migrations.swift
//  PlacemarksAPI
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension PlacemarkModel.Property {
	
	enum Migrations {
		
		typealias Migrated = PlacemarkModel.Property
		
		static var all: [Migration] {
			[CreatePlacemarkProperty(), AddInitialProperties()]
		}
		
	}
	
}
