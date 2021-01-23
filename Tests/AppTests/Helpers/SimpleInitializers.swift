//
//  SimpleInitializers.swift
//  AppTests
//
//  Created by Rémi Bardon on 12/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

@testable import App
import Foundation

extension User {
	
	static func dummy(
		id: UUID = UUID(),
		username: String = UUID().uuidString,
		email: String = "\(UUID())@example.com",
		passwordHash: String = "password" // Do not hash for speed purposes
	) -> Self {
		self.init(id: id, username: username, email: email, passwordHash: passwordHash)
	}
	
}

extension Placemark {
	
	static func dummy(
		id: UUID = UUID(),
		name: String = UUID().uuidString,
		latitude: Double = Double.random(in: -90...90),
		longitude: Double = Double.random(in: -180...180),
		typeId: PlacemarkType.IDValue,
		state: State = .private,
		creatorId: User.IDValue,
		caption: String = UUID().uuidString,
		images: [String] = []
	) -> Self {
		self.init(
			id: id, name: name, latitude: latitude, longitude: longitude, typeId: typeId,
			state: state, creatorId: creatorId, caption: caption, images: images
		)
	}
	
}
