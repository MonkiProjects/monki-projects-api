//
//  User+Private.swift
//  App
//
//  Created by Rémi Bardon on 03/08/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Vapor

extension User {
	
	struct Private: Content {
		
		let id: UUID
		let username: String
		let email: String
		
	}
	
	func asPrivate() throws -> Private {
		return try Private(
			id: self.requireID(),
			username: self.username,
			email: self.email
		)
	}
	
}
