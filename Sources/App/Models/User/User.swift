//
//  User.swift
//  App
//
//  Created by Rémi Bardon on 07/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor

final class User: Model {
	
	static let schema = "users"
	
	@ID(key: .id)
	var id: UUID?
	
	@Field(key: "username")
	var username: String
	
	@Field(key: "email")
	var email: String
	
	@Field(key: "password_hash")
	var passwordHash: String
	
	init() {}
	
	init(id: UUID? = nil, username: String, email: String, passwordHash: String) {
		self.id = id
		self.username = username
		self.email = email
		self.passwordHash = passwordHash
	}
	
}
