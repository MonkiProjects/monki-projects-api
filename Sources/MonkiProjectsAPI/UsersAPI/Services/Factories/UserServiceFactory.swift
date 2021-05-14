//
//  UserServiceFactory.swift
//  UsersAPI
//
//  Created by Rémi Bardon on 07/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent

// For more information, see <https://docs.vapor.codes/4.0/upgrading/#repositories>

internal struct UserServiceFactory {
	
	typealias Builder = (Database, Application, EventLoop, Logger) -> UserServiceProtocol
	
	var make: Builder?
	
	mutating func use(_ make: @escaping Builder) {
		self.make = make
	}
	
}

extension Application {
	
	private struct UserServiceKey: StorageKey {
		typealias Value = UserServiceFactory
	}
	
	var userService: UserServiceFactory {
		get {
			self.storage[UserServiceKey.self] ?? .init()
		}
		set {
			self.storage[UserServiceKey.self] = newValue
		}
	}
	
	func userService(
		database: Database,
		application: Application,
		eventLoop: EventLoop,
		logger: Logger
	) -> UserServiceProtocol {
		guard let make = self.userService.make else {
			preconditionFailure("`app.userService.use` required in `configure.swift`.")
		}
		return make(database, application, eventLoop, logger)
	}
	
}

extension Request {
	
	var userService: UserServiceProtocol {
		self.application.userService(
			database: self.db,
			application: self.application,
			eventLoop: self.eventLoop,
			logger: self.logger
		)
	}
	
}
