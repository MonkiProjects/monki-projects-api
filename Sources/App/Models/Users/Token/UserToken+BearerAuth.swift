//
//  UserToken+BearerAuth.swift
//  App
//
//  Created by Rémi Bardon on 08/06/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Fluent
import Vapor

/// Comes from https://docs.vapor.codes/4.0/authentication/#model-token-authenticatable
extension UserModel.Token: ModelTokenAuthenticatable {
	
	typealias User = App.UserModel
	
	static let valueKey = \UserModel.Token.$value
	static let userKey = \UserModel.Token.$user
	
	var isValid: Bool {
		guard let expiryDate = expiresAt else {
			return true
		}
		
		return expiryDate > Date()
	}
	
}
