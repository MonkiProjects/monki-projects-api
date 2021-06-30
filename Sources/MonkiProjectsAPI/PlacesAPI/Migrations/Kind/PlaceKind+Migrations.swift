//
//  PlaceKind+Migrations.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension PlaceModel.Kind {
	
	enum Migrations {
		
		typealias Migrated = PlaceModel.Kind
		
		static var all: [Migration] {
			Category.Migrations.all
				+ [CreatePlaceKind(), AddInitialKinds()]
		}
		
	}
	
}
