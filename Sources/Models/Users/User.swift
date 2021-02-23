//
//  User.swift
//  Models
//
//  Created by Rémi Bardon on 07/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor
	
public final class UserModel: Model {
	
	public static let schema = "users"
	
	@ID(key: .id)
	public var id: UUID?
	
	@Field(key: "username")
	public var username: String
	
	@Field(key: "email")
	public var email: String
	
	@Field(key: "password_hash")
	public var passwordHash: String
	
	@Timestamp(key: "created_at", on: .create)
	public var createdAt: Date?
	
	@Timestamp(key: "updated_at", on: .update)
	public var updatedAt: Date?
	
	@Timestamp(key: "deleted_at", on: .delete)
	public var deletedAt: Date?
	
	public init() {}
	
	public init(id: IDValue? = nil, username: String, email: String, passwordHash: String) {
		self.id = id
		self.username = username
		self.email = email
		self.passwordHash = passwordHash
	}
	
}
