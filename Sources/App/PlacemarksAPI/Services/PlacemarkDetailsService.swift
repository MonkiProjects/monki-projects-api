//
//  PlacemarkDetailsService.swift
//  PlacemarksAPI
//
//  Created by Rémi Bardon on 07/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiMapModel

internal struct PlacemarkDetailsService: PlacemarkDetailsServiceProtocol {
	
	let db: Database
	let app: Application
	let eventLoop: EventLoop
	let logger: Logger
	
	func addProperties(
		_ properties: [Placemark.Property],
		to details: PlacemarkModel.Details
	) -> EventLoopFuture<Void> {
		self.eventLoop.makeSucceededFuture(properties)
			.flatMapEach(on: self.eventLoop) { property in
				self.app.placemarkPropertyRepository(for: self.db)
					.get(kind: property.kind, humanId: property.id)
					.flatMap { property in
						details.$properties.attach(property, method: .ifNotExists, on: self.db)
					}
			}
			.transform(to: ())
	}
	
}
