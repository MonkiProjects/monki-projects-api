//
//  AuthorizationService.swift
//  AuthAPI
//
//  Created by Rémi Bardon on 15/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiProjectsModel

internal struct AuthorizationService: Service, AuthorizationServiceProtocol {
	
	let db: Database
	let app: Application
	let eventLoop: EventLoop
	let logger: Logger
	
	func user(
		_ requesterId: UserModel.IDValue,
		can right: AuthorizationRight,
		user userId: UserModel.IDValue
	) async -> Bool {
		// Anyone has full rights over their data
		if requesterId == userId {
			return true
		}
		// FIXME: Add real authorization
		return false
	}
	
	func user(
		_ requesterId: UserModel.IDValue,
		can right: AuthorizationRight,
		place placeId: PlaceModel.IDValue
	) async throws -> Bool {
		let place = try await self.make(self.app.placeRepository).get(placeId)
		
		// Anyone has full rights over their data
		if place.$creator.id == requesterId {
			return true
		}
		
		// FIXME: Add real authorization
		
		return false
	}
	
}
