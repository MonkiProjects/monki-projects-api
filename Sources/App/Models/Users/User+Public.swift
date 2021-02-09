//
//  User+Public.swift
//  App
//
//  Created by Rémi Bardon on on 08/06/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Vapor
import MonkiProjectsModel

extension UserModel {
	
	func asPublicSmall() throws -> User.Public.Small {
		// FIXME: Use real data
		return try .init(
			id: self.requireID(),
			username: self.username,
			displayName: "<TODO>",
			avatar: nil,
			country: nil,
			type: .user,
			updatedAt: self.updatedAt.require()
		)
	}
	
	func asPublicFull() throws -> User.Public.Full {
		// FIXME: Use real data
		return try .init(
			self.asPublicSmall(),
			with: User.Details(
				bio: nil,
				location: nil,
				experience: [:],
				socialUsernames: [:],
				createdAt: Date()
			)
		)
	}
	
}

extension User.Public.Small: Content {}
extension User.Public.Full: Content {}
