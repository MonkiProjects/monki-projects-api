//
//  CreateUserToken.swift
//  App
//
//  Created by Rémi Bardon on 08/06/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Fluent

extension User.Token {
	
	/// Comes from https://docs.vapor.codes/4.0/authentication/#user-token
	struct CreateUserToken: Migration {
		
		var name: String { "CreateUserToken" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.schema("user_tokens")
				.id()
				.field("value", .string, .required)
				.field("user_id", .uuid, .required, .references("users", .id))
				.field("created_at", .datetime, .required)
				.field("expires_at", .datetime)
				.unique(on: "value")
				.create()
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.schema("user_tokens").delete()
		}
		
	}
	
}
