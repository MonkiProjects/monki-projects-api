//
//  User.swift
//  App
//
//  Created by Rémi Bardon on 07/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor
import MonkiProjectsModel

typealias UserModel = User.Model

extension User {
	
	final class Model: Fluent.Model {
		
		static let schema = "users"
		
		@ID(key: .id)
		var id: UUID?
		
		@Field(key: "username")
		var username: String
		
		@Field(key: "email")
		var email: String
		
		@Field(key: "password_hash")
		var passwordHash: String
		
		@Timestamp(key: "created_at", on: .create)
		var createdAt: Date?
		
		@Timestamp(key: "updated_at", on: .update)
		var updatedAt: Date?
		
		@Timestamp(key: "deleted_at", on: .delete)
		var deletedAt: Date?
		
		init() {}
		
		init(id: UUID? = nil, username: String, email: String, passwordHash: String) {
			self.id = id
			self.username = username
			self.email = email
			self.passwordHash = passwordHash
		}
		
	}
	
}
