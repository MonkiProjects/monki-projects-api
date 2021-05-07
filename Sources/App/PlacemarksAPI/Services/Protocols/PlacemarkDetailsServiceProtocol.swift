//
//  PlacemarkDetailsServiceProtocol.swift
//  App
//
//  Created by Rémi Bardon on 07/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import MonkiMapModel

public protocol PlacemarkDetailsServiceProtocol {
	
	func addProperties(
		_ properties: [Placemark.Property],
		to details: PlacemarkModel.Details
	) -> EventLoopFuture<Void>
	
}
