//
//  User+BasicAuth.swift
//  Models
//
//  Created by Rémi Bardon on 08/06/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Vapor
import Fluent

/// Comes from https://docs.vapor.codes/4.0/authentication/#model-authenticatable
extension UserModel: ModelAuthenticatable {
	
	public static let usernameKey = \UserModel.$username
	public static let passwordHashKey = \UserModel.$passwordHash
	
	public func verify(password: String) throws -> Bool {
		try Bcrypt.verify(password, created: self.passwordHash)
	}
	
}
