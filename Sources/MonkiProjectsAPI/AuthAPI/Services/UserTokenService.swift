//
//  UserTokenService.swift
//  AuthAPI
//
//  Created by Rémi Bardon on 15/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiProjectsModel

internal struct UserTokenService: UserTokenServiceProtocol {
	
	let db: Database
	let app: Application
	let eventLoop: EventLoop
	let logger: Logger
	
	func deleteAllTokens(
		for userId: UserModel.IDValue,
		requesterId: UserModel.IDValue
	) -> EventLoopFuture<Void> {
		let userFuture = self.app.userRepository(for: self.db).get(userId)
		
		// Do additional validations
		let guardAuthorizedFuture = userFuture.guard({ user in
			user.id == requesterId
		}, else: Abort(.forbidden, reason: "You cannot delete someone else's tokens!"))
		
		let deleteTokensFuture = self.app.userTokenRepository(for: self.db)
			.getAll(for: userId)
			.flatMap { $0.delete(on: self.db) }
		
		return guardAuthorizedFuture
			.flatMap { _ in deleteTokensFuture }
	}
	
}
