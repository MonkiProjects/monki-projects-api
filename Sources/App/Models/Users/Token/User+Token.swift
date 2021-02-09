//
//  User+Token.swift
//  App
//
//  Created by Rémi Bardon on 08/06/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Vapor
import Fluent

/// Comes from https://docs.vapor.codes/4.0/authentication/#user-token
extension UserModel {
	
	final class Token: Model {
		
		static let schema = "user_tokens"
		
		@ID(key: .id)
		var id: UUID?
		
		@Field(key: "value")
		var value: String
		
		@Parent(key: "user_id")
		var user: UserModel
		
		@Field(key: "expires_at")
		var expiresAt: Date?
		
		@Timestamp(key: "created_at", on: .create)
		var createdAt: Date?
		
		init() {}
		
		init(id: UUID? = nil, value: String, userId: UserModel.IDValue, expiresAt: Date? = nil) {
			self.id = id
			self.value = value
			self.$user.id = userId
			self.expiresAt = expiresAt
		}
		
	}
	
}

extension UserModel {
	
	/// Comes from https://docs.vapor.codes/4.0/authentication/#user-token
	func generateToken() throws -> Token {
		let calendar = Calendar(identifier: .gregorian)
		let expiryDate = calendar.date(byAdding: .year, value: 1, to: Date())
		
		return try .init(
			value: [UInt8].random(count: 16).base64,
			userId: self.requireID(),
			expiresAt: expiryDate
		)
	}
	
}
