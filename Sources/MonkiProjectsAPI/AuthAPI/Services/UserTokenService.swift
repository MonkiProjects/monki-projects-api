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
	) async throws {
		// Perform validations
		let canDelete = await self.make(self.app.authorizationService)
			.user(requesterId, can: .delete, user: userId)
		guard canDelete else {
			throw Abort(.forbidden, reason: "You cannot delete someone else's tokens!")
		}
		
		// Delete tokens
		let tokens = try await self.make(self.app.userTokenRepository).getAll(for: userId)
		await withThrowingTaskGroup(of: Void.self) { group in
			for token in tokens {
				group.addTask {
					try await token.delete(on: self.db)
				}
			}
		}
	}
	
}
