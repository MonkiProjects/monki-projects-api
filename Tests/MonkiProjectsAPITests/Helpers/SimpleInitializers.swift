//
//  SimpleInitializers.swift
//  MonkiProjectsAPITests
//
//  Created by Rémi Bardon on 12/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

@testable import MonkiProjectsAPI
import Foundation
import MonkiProjectsModel
import MonkiMapModel

extension UserModel {
	
	static func dummy(
		id: User.ID = .init(),
		username: String = UUID().uuidString,
		displayName: String = UUID().uuidString,
		email: String = "\(UUID())@example.com",
		passwordHash: String = "password" // Do not hash for speed purposes
	) -> Self {
		self.init(
			id: id,
			username: username,
			displayName: displayName,
			email: email,
			passwordHash: passwordHash
		)
	}
	
}

extension PlaceModel {
	
	static func dummy(
		id: Place.ID = .init(),
		name: String = UUID().uuidString,
		latitude: Double = Double.random(in: -90...90),
		longitude: Double = Double.random(in: -180...180),
		kindId: Kind.IDValue,
		visibility: Visibility = .public,
		isDraft: Bool = false,
		creatorId: UserModel.IDValue
	) -> Self {
		self.init(
			id: id, name: name, latitude: latitude, longitude: longitude, kindId: kindId,
			visibility: visibility, isDraft: isDraft, creatorId: creatorId
		)
	}
	
}

extension PlaceModel.Details {
	
	static func dummy(
		id: IDValue = .init(),
		placeId: Place.IDValue,
		caption: String = UUID().uuidString,
		images: [String] = [],
		satelliteImageId: String? = nil
	) -> Self {
		self.init(
			id: id,
			placeId: placeId,
			caption: caption,
			images: images,
			satelliteImageId: satelliteImageId
		)
	}
	
}

extension PlaceModel.Location {
	
	static func dummy(
		id: IDValue = .init(),
		detailsId: Details.IDValue,
		city: String = UUID().uuidString,
		country: String = UUID().uuidString
	) -> Self {
		self.init(
			id: id,
			detailsId: detailsId,
			city: city,
			country: country
		)
	}
	
}
