//
//  UserTokenServiceFactory.swift
//  AuthAPI
//
//  Created by Rémi Bardon on 15/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent

// For more information, see <https://docs.vapor.codes/4.0/upgrading/#repositories>

internal struct UserTokenServiceFactory {
	
	typealias Builder = (Database, Application, EventLoop, Logger) -> UserTokenServiceProtocol
	
	var make: Builder?
	
	mutating func use(_ make: @escaping Builder) {
		self.make = make
	}
	
}

extension Application {
	
	private struct UserTokenServiceKey: StorageKey {
		typealias Value = UserTokenServiceFactory
	}
	
	var userTokenService: UserTokenServiceFactory {
		get {
			self.storage[UserTokenServiceKey.self] ?? .init()
		}
		set {
			self.storage[UserTokenServiceKey.self] = newValue
		}
	}
	
	func userTokenService(
		database: Database,
		application: Application,
		eventLoop: EventLoop,
		logger: Logger
	) -> UserTokenServiceProtocol {
		guard let make = self.userTokenService.make else {
			preconditionFailure("`app.userTokenService.use` required in `configure.swift`.")
		}
		return make(database, application, eventLoop, logger)
	}
	
}

extension Request {
	
	var userTokenService: UserTokenServiceProtocol {
		self.application.userTokenService(
			database: self.db,
			application: self.application,
			eventLoop: self.eventLoop,
			logger: self.logger
		)
	}
	
}
