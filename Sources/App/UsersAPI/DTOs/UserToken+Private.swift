//
//  UserToken+Private.swift
//  DTOs
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
		let user: MonkiProjectsModel.User.Private
		let expiresAt: Date?
		let createdAt: Date
		
	}
	
	public func asPrivate(on database: Database) -> EventLoopFuture<Private> {
		let loadRelationsFuture = self.$user.load(on: database)
		
		return loadRelationsFuture.flatMapThrowing {
			try Private(
				value: self.value,
				user: self.user.asPrivate(),
				expiresAt: self.expiresAt,
				createdAt: self.createdAt.require()
			)
		}
	}
	
}
