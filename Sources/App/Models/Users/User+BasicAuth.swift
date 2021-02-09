//
//  User+ModelAuthenticable.swift
//  App
//
//  Created by Rémi Bardon on 08/06/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Vapor
import Fluent

/// Comes from https://docs.vapor.codes/4.0/authentication/#model-authenticatable
extension UserModel: ModelAuthenticatable {
	
	static let usernameKey = \UserModel.$username
	static let passwordHashKey = \UserModel.$passwordHash
	
	func verify(password: String) throws -> Bool {
		try Bcrypt.verify(password, created: self.passwordHash)
	}
	
}
