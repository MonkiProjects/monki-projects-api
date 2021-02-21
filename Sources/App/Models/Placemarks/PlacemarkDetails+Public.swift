//
//  PlacemarkDetails+Public.swift
//  App
//
//  Created by Rémi Bardon on 16/02/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiMapModel

extension Models.Placemark.Details {
	
	func asPublic(on database: Database) throws -> EventLoopFuture<MonkiMapModel.Placemark.Details.Public> {
		let locationFuture = try Location.query(on: database)
			.filter(\.$details.$id == self.requireID())
			.first()
		// FIXME: Trigger a call to reverse geocode location
		
		let loadRelationsFuture = locationFuture
			.passthroughAfter { _ in self.$properties.load(on: database) }
		
		return loadRelationsFuture.flatMapThrowing { location in
			typealias Properties = [MonkiMapModel.Placemark.Property.Localized]
			
			var features = Properties()
			var goodForTraining = Properties()
			var benefits = Properties()
			var hazards = Properties()
			
			for property in self.properties {
				let localized = try property.localized(in: .en)
				
				switch localized.kind {
				case .feature:
					features.append(localized)
				case .technique:
					goodForTraining.append(localized)
				case .benefit:
					benefits.append(localized)
				case .hazard:
					hazards.append(localized)
				}
			}
			
			return try MonkiMapModel.Placemark.Details.Public(
				caption: self.caption,
				satelliteImage: cloudinary.image(withId: self.satelliteImageId).requireURL(),
				images: self.images.map(URL.init(string:)).compactMap { $0 },
				location: location?.asPublic(),
				features: features,
				goodForTraining: goodForTraining,
				benefits: benefits,
				hazards: hazards
			)
		}
	}
	
}

extension Placemark.Details.Public: Content {}
