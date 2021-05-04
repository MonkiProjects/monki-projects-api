//
//  CreateUser.swift
//  Migrations
//
//  Created by Rémi Bardon on 07/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension UserModel.Migrations {
	
	struct CreateUser: Migration {
		
		var name: String { "CreateUser" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.schema("users")
				.id()
				.field("username", .string, .required)
				.field("email", .string, .required)
				.field("password_hash", .string, .required)
				.field("created_at", .datetime, .required)
				.field("updated_at", .datetime, .required)
				.field("deleted_at", .datetime)
				.unique(on: "username", name: "users_no_duplicate_username")
				.unique(on: "email", name: "users_no_duplicate_email")
				.create()
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.schema("users").delete()
		}
		
	}
	
}
