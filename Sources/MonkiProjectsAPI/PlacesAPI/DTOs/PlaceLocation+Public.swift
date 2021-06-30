//
//  PlaceLocation+Public.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import MonkiMapModel

extension PlaceModel.Location {
	
	public func asPublic() -> Place.Location.Public {
		.init(
			city: self.city,
			country: self.country
		)
	}
	
}

extension Place.Location.Public: Content {}
