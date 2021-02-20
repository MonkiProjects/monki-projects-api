//
//  PlacemarkKind+Migrations.swift
//  App
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension Models.Placemark.Kind {
	
	enum Migrations {
		
		typealias Migrated = Models.Placemark.Kind
		
		static var all: [Migration] {
			return Category.Migrations.all
				+ [CreatePlacemarkKind(), AddInitialKinds()]
		}
		
	}
	
}
