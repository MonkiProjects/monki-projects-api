//
//  Placemark+Create.swift
//  App
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor

extension Placemark {
	
	struct Create: Content {
		let name: String
		let latitude, longitude: Double
		let type,
			caption: String
		let images: [URL]?
		let features, goodForTraining, benefits, hazards: [String]?
	}
	
}

extension Placemark.Create: Validatable {
	
	static func validations(_ validations: inout Validations) {
		validations.add("name", as: String.self, is: .count(3...48))
		validations.add("latitude", as: Double.self, is: .range(-90...90))
		validations.add("longitude", as: Double.self, is: .range(-180...180))
		validations.add("type", as: String.self)
		validations.add("caption", as: String.self)
		validations.add("images", as: [URL].self, required: false)
		validations.add("features", as: [String].self, required: false)
		validations.add("goodForTraining", as: [String].self, required: false)
		validations.add("benefits", as: [String].self, required: false)
		validations.add("hazards", as: [String].self, required: false)
	}
	
}