//
//  PlaceDetails+Public.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 16/02/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiProjectsModel
import MonkiMapModel

extension PlaceModel.Details {
	
	public func asPublic(
		on req: Request
	) async throws-> MonkiMapModel.Place.Details.Public {
		// Load relations
		try await self.$properties.load(on: req.db)
		
		let location = try await Location.query(on: req.db)
			.filter(\.$details.$id == self.requireID())
			.first()
		
		// TODO: Trigger a call to reverse geocode location
		
		return MonkiMapModel.Place.Details.Public(
			caption: self.caption,
			satelliteImage: cloudinary.image(withId: self.satelliteImageId).url.map(ImageSource.url),
			images: self.images.compactMap { urlString -> ImageSource? in
				if let url = URL(string: urlString) {
					return ImageSource.url(url)
				} else {
					return nil
				}
			},
			location: location?.asPublic(),
			properties: self.properties.map { MonkiMapModel.Place.Property(kind: $0.kind, id: $0.humanId) }
		)
	}
	
}

extension Place.Details.Public: Content {}
