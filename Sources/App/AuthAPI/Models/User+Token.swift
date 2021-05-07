//
//  User+Token.swift
//  Models
//
//  Created by Rémi Bardon on 08/06/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Vapor
import Fluent

/// Comes from https://docs.vapor.codes/4.0/authentication/#user-token
extension UserModel {
	
	public final class Token: Model {
		
		public static let schema = "user_tokens"
		
		@ID(key: .id)
		public var id: UUID?
		
		@Field(key: "value")
		public var value: String
		
		@Parent(key: "user_id")
		public var user: UserModel
		
		@Field(key: "expires_at")
		public var expiresAt: Date?
		
		@Timestamp(key: "created_at", on: .create)
		public var createdAt: Date?
		
		public init() {}
		
		public init(id: UUID? = nil, value: String, userId: UserModel.IDValue, expiresAt: Date? = nil) {
			self.id = id
			self.value = value
			self.$user.id = userId
			self.expiresAt = expiresAt
		}
		
	}
	
}

extension UserModel {
	
	/// Comes from https://docs.vapor.codes/4.0/authentication/#user-token
	public func generateToken() throws -> Token {
		let calendar = Calendar(identifier: .gregorian)
		let expiryDate = calendar.date(byAdding: .year, value: 1, to: Date())
		
		return try .init(
			value: [UInt8].random(count: 16).base64,
			userId: self.requireID(),
			expiresAt: expiryDate
		)
	}
	
}
