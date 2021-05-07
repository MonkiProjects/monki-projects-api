//
//  UserToken+BearerAuth.swift
//  Models
//
//  Created by Rémi Bardon on 08/06/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Fluent
import Vapor

/// Comes from https://docs.vapor.codes/4.0/authentication/#model-token-authenticatable
extension UserModel.Token: ModelTokenAuthenticatable {
	
	public typealias User = UserModel
	
	public static let valueKey = \UserModel.Token.$value
	public static let userKey = \UserModel.Token.$user
	
	public var isValid: Bool {
		guard let expiryDate = expiresAt else {
			return true
		}
		
		return expiryDate > Date()
	}
	
}
