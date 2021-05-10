//
//  UserToken+Private.swift
//  AuthAPI
//
//  Created by Rémi Bardon on 08/06/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Vapor
import MonkiProjectsModel

extension UserModel.Token {
	
	public func asPrivate() throws -> MonkiProjectsModel.User.Token.Private {
		try .init(
			value: self.value,
			expiresAt: self.expiresAt,
			createdAt: self.createdAt.require()
		)
	}
	
}

extension User.Token.Private: Content {}
