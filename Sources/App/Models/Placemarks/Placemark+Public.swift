//
//  Placemark+Public.swift
//  App
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Vapor

extension Placemark {
	
	struct Public: Content {
		
		let id: UUID
		let name: String
		let latitude: Double
		let longitude: Double
		let type: String
		let category: String
		let state: State
		let creator: UUID
		let caption: String
		let satelliteImage: URL
		let images: [URL]
		let location: Location.Public?
		let features: [Property.Public]
		let goodForTraining: [Property.Public]
		let benefits: [Property.Public]
		let hazards: [Property.Public]
		let createdAt: Date
		let updatedAt: Date
		
	}
	
	func asPublic() throws -> Public {
		var features = [Property.Public]()
		var goodForTraining = [Property.Public]()
		var benefits = [Property.Public]()
		var hazards = [Property.Public]()
		
		for property in self.properties {
			switch property.type {
			case .feature:
				features.append(property.asPublic())
			case .technique:
				goodForTraining.append(property.asPublic())
			case .benefit:
				benefits.append(property.asPublic())
			case .hazard:
				hazards.append(property.asPublic())
			}
		}
		
		return try Public(
			id: self.requireID(),
			name: self.name,
			latitude: self.latitude,
			longitude: self.longitude,
			type: self.type.humanId,
			category: self.type.category.humanId,
			state: self.state,
			creator: self.creator.requireID(),
			caption: self.caption,
			satelliteImage: URL(string: self.satelliteImage).require(),
			images: self.images.map { try URL(string: $0).require() },
			location: self.location?.asPublic(),
			features: features,
			goodForTraining: goodForTraining,
			benefits: benefits,
			hazards: hazards,
			createdAt: self.createdAt.require(),
			updatedAt: self.updatedAt.require()
		)
	}
	
}