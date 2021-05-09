//
//  UserToken+Private.swift
//  AuthAPI
//
//  Created by Rémi Bardon on 08/06/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiProjectsModel

extension UserModel.Token {
	
	public struct Private: Content {
		let value: String
		let expiresAt: Date?
		let createdAt: Date
	}
	
	public func asPrivate() throws -> Private {
		try Private(
			value: self.value,
			expiresAt: self.expiresAt,
			createdAt: self.createdAt.require()
		)
	}
	
}
