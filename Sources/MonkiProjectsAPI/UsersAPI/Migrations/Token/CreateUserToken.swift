//
//  CreateUserToken.swift
//  UsersAPI
//
//  Created by Rémi Bardon on 08/06/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Fluent

extension UserModel.Token {
	
	/// Comes from https://docs.vapor.codes/4.0/authentication/#user-token
	struct CreateUserToken: Migration {
		
		var name: String { "CreateUserToken" }
		
		func prepare(on database: Database) -> EventLoopFuture<Void> {
			database.schema("user_tokens")
				.id()
				.field("value", .string, .required)
				.field("user_id", .string, .required, .references("users", .id, onDelete: .cascade))
				.field("created_at", .datetime, .required)
				.field("expires_at", .datetime)
				.unique(on: "value", name: "no_duplicate_user_tokens")
				.create()
		}
		
		func revert(on database: Database) -> EventLoopFuture<Void> {
			database.schema("user_tokens").delete()
		}
		
	}
	
}
