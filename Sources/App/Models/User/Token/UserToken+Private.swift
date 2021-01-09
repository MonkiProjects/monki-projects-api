//
//  UserToken+Private.swift
//  App
//
//  Created by Rémi Bardon on 08/06/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Vapor

extension User.Token {
	
	struct Private: Content {
		
		let value: String
		let user: User.Public
		let expiresAt: Date?
		let createdAt: Date
		
	}
	
	func asPrivate() throws -> Private {
		return try Private(
			value: self.value,
			user: self.user.asPublic(),
			expiresAt: self.expiresAt,
			createdAt: self.createdAt.require()
		)
	}
	
}
