//
//  AuthorizationServiceFactory.swift
//  AuthAPI
//
//  Created by Rémi Bardon on 15/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent

// For more information, see <https://docs.vapor.codes/4.0/upgrading/#repositories>

internal struct AuthorizationServiceFactory {
	
	typealias Builder = (Database, Application, EventLoop, Logger) -> AuthorizationServiceProtocol
	
	var make: Builder?
	
	mutating func use(_ make: @escaping Builder) {
		self.make = make
	}
	
}

extension Application {
	
	private struct AuthorizationServiceKey: StorageKey {
		typealias Value = AuthorizationServiceFactory
	}
	
	var authorizationService: AuthorizationServiceFactory {
		get {
			self.storage[AuthorizationServiceKey.self] ?? .init()
		}
		set {
			self.storage[AuthorizationServiceKey.self] = newValue
		}
	}
	
	func authorizationService(
		database: Database,
		application: Application,
		eventLoop: EventLoop,
		logger: Logger
	) -> AuthorizationServiceProtocol {
		guard let make = self.authorizationService.make else {
			preconditionFailure("`app.authorizationService.use` required in `configure.swift`.")
		}
		return make(database, application, eventLoop, logger)
	}
	
}

extension Request {
	
	var authorizationService: AuthorizationServiceProtocol {
		self.application.authorizationService(
			database: self.db,
			application: self.application,
			eventLoop: self.eventLoop,
			logger: self.logger
		)
	}
	
}
