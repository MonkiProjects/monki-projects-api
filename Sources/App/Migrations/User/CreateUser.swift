//
//  CreateUser.swift
//  App
//
//  Created by Rémi Bardon on 07/01/2021.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Fluent

extension User.Migrations {
	
	struct CreateUser: Migration {
		
		var name: String { "CreateUser" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.schema("users")
				.id()
				.field("username", .string, .required)
				.field("email", .string, .required)
				.field("password_hash", .string, .required)
				.create()
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.schema("users").delete()
		}
		
	}
	
}
