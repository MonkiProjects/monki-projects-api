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

internal struct UserTokenService: Service, UserTokenServiceProtocol {
	
	let db: Database
	let app: Application
	let eventLoop: EventLoop
	let logger: Logger
	
	func deleteAllTokens(
		for userId: UserModel.IDValue,
		requesterId: UserModel.IDValue
	) -> EventLoopFuture<Void> {
		let validationsFuture = EventLoopFuture.andAllSucceed([
			self.make(self.app.authorizationService)
				.user(requesterId, can: .delete, user: userId)
				.guard(else: Abort(.forbidden, reason: "You cannot delete someone else's tokens!")),
		], on: self.eventLoop)
		
		func deleteTokensFuture() -> EventLoopFuture<Void> {
			self.make(self.app.userTokenRepository)
				.getAll(for: userId)
				.flatMap { $0.delete(on: self.db) }
		}
		
		return validationsFuture
			.flatMap(deleteTokensFuture)
	}
	
}
