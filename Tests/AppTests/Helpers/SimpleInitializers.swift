//
//  SimpleInitializers.swift
//  AppTests
//
//  Created by Rémi Bardon on 12/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

@testable import App
import Foundation
import Models

extension UserModel {
	
	static func dummy(
		id: UUID = UUID(),
		username: String = UUID().uuidString,
		email: String = "\(UUID())@example.com",
		passwordHash: String = "password" // Do not hash for speed purposes
	) -> Self {
		self.init(id: id, username: username, email: email, passwordHash: passwordHash)
	}
	
}

extension PlacemarkModel {
	
	static func dummy(
		id: UUID = UUID(),
		name: String = UUID().uuidString,
		latitude: Double = Double.random(in: -90...90),
		longitude: Double = Double.random(in: -180...180),
		kindId: Kind.IDValue,
		state: State = .private,
		creatorId: UserModel.IDValue
	) -> Self {
		self.init(
			id: id, name: name, latitude: latitude, longitude: longitude, kindId: kindId,
			state: state, creatorId: creatorId
		)
	}
	
}

extension PlacemarkModel.Details {
	
	static func dummy(
		id: IDValue = UUID(),
		placemarkId: Placemark.IDValue,
		caption: String = UUID().uuidString,
		images: [String] = [],
		satelliteImageId: String? = nil
	) -> Self {
		self.init(
			id: id,
			placemarkId: placemarkId,
			caption: caption,
			images: images,
			satelliteImageId: satelliteImageId
		)
	}
	
}

extension PlacemarkModel.Location {
	
	static func dummy(
		id: IDValue = UUID(),
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
