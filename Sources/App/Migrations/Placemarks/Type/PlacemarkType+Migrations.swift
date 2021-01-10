//
//  PlacemarkType+Migrations.swift
//  App
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension Placemark.PlacemarkType {
	
	enum Migrations {
		
		static var all: [Migration] {
			return [CreatePlacemarkType(), AddTypes()]
		}
		
	}
	
}
