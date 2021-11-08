//
//  PlaceDetailsService.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 07/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiMapModel

internal struct PlaceDetailsService: Service, PlaceDetailsServiceProtocol {
	
	let db: Database
	let app: Application
	let eventLoop: EventLoop
	let logger: Logger
	
	func addProperties(
		_ properties: [Place.Property],
		to details: PlaceModel.Details
	) async throws {
		let placePropertyRepository = self.make(self.app.placePropertyRepository)
		for property in properties {
			let property: PlaceModel.Property = try await placePropertyRepository
				.get(kind: property.kind, humanId: property.id)
			try await details.$properties.attach(property, method: .ifNotExists, on: self.db)
		}
	}
	
}
