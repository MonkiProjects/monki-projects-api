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
	) -> EventLoopFuture<Bool> {
		// Anyone has full rights over their data
		if requesterId == userId {
			return self.eventLoop.makeSucceededFuture(true)
		}
		// FIXME: Add real authorization
		return self.eventLoop.makeSucceededFuture(false)
	}
	
	func user(
		_ requesterId: UserModel.IDValue,
		can right: AuthorizationRight,
		placemark placemarkId: PlacemarkModel.IDValue
	) -> EventLoopFuture<Bool> {
		self.make(self.app.placemarkRepository)
			.get(placemarkId)
			.map { placemark in
				// Anyone has full rights over their data
				if placemark.$creator.id == requesterId {
					return true
				}
				// FIXME: Add real authorization
				return false
			}
	}
	
}
