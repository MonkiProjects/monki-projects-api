//
//  PlaceDetailsServiceProtocol.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 07/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import MonkiMapModel

public protocol PlaceDetailsServiceProtocol {
	
	func addProperties(
		_ properties: [Place.Property],
		to details: PlaceModel.Details
	) async throws
	
}
