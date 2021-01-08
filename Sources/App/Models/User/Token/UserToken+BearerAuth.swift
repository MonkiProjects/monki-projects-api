//
//  UserToken+BearerAuth.swift
//  App
//
//  Created by BARDON Rémi on 08/06/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Fluent
import Vapor

/// Comes from https://docs.vapor.codes/4.0/authentication/#model-token-authenticatable
extension User.Token: ModelTokenAuthenticatable {
	
	typealias User = App.User
	
	static let valueKey = \User.Token.$value
	static let userKey = \User.Token.$user
	
	var isValid: Bool {
		guard let expiryDate = expiresAt else {
			return true
		}
		
		return expiryDate > Date()
	}
	
}
