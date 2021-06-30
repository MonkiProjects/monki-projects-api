//
//  PlaceCreate+Validatable.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import MonkiMapModel

extension Place.Create: Content, Validatable {
	
	public static func validations(_ validations: inout Validations) {
		validations.add("name", as: String.self, is: .count(3...48))
		validations.add("latitude", as: Double.self, is: .range(-90...90))
		validations.add("longitude", as: Double.self, is: .range(-180...180))
		validations.add("kind", as: String.self)
		validations.add("caption", as: String.self)
		validations.add("images", as: [URL].self)
		validations.add("properties", as: [Place.Property].self)
	}
	
}
