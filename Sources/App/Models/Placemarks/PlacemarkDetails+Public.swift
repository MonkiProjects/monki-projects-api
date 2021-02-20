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
	
	func asPublic(on database: Database) throws -> MonkiMapModel.Placemark.Details.Public {
		typealias Properties = [MonkiMapModel.Placemark.Property.Localized]
		
		var features = Properties()
		var goodForTraining = Properties()
		var benefits = Properties()
		var hazards = Properties()
		
		for property in self.properties {
			let localized = try property.localized()
			
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
		
		let location = try Location.query(on: database)
			.filter(\.$details.$id == self.requireID())
			.first()
			.unwrap(or: Abort(.internalServerError,
				reason: "We could not find the location details for this placemark."
			))
			.wait()
		// FIXME: Trigger a call to reverse geocode location
		
		return try .init(
			caption: self.caption,
			satelliteImage: URL(string: self.satelliteImage).require(),
			images: self.images.map(URL.init(string:)).compactMap { $0 },
			location: location.asPublic(),
			features: features,
			goodForTraining: goodForTraining,
			benefits: benefits,
			hazards: hazards
		)
	}
	
}

extension Placemark.Details.Public: Content {}
