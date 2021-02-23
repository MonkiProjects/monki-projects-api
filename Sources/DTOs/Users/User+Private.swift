//
//  User+Private.swift
//  DTOs
//
//  Created by Rémi Bardon on 03/08/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Vapor
import Models
import MonkiProjectsModel

extension UserModel {
	
	public func asPrivate() throws -> User.Private {
		return try User.Private(
			self.asPublicFull(),
			email: self.email
		)
	}
	
}

extension User.Private: Content {}
