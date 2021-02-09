//
//  User+Private.swift
//  App
//
//  Created by Rémi Bardon on 03/08/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Vapor
import MonkiProjectsModel

extension UserModel {
	
	func asPrivate() throws -> User.Private {
		return try User.Private(
			self.asPublicFull(),
			email: self.email
		)
	}
	
}

extension User.Private: Content {}
