//
//  UtilityServiceFactory.swift
//  UtilityAPI
//
//  Created by Rémi Bardon on 13/01/2022.
//  Copyright © 2022 Monki Projects. All rights reserved.
//

import Vapor
import Fluent

// For more information, see <https://docs.vapor.codes/4.0/upgrading/#repositories>

internal struct UtilityServiceFactory {
	
	typealias Builder = (Database, Application, EventLoop, Logger) -> UtilityServiceProtocol
	
	var make: Builder?
	
	mutating func use(_ make: @escaping Builder) {
		self.make = make
	}
	
}

extension Application {
	
	private struct UtilityServiceKey: StorageKey {
		typealias Value = UtilityServiceFactory
	}
	
	var utilityService: UtilityServiceFactory {
		get {
			self.storage[UtilityServiceKey.self] ?? .init()
		}
		set {
			self.storage[UtilityServiceKey.self] = newValue
		}
	}
	
	func utilityService(
		database: Database,
		application: Application,
		eventLoop: EventLoop,
		logger: Logger
	) -> UtilityServiceProtocol {
		guard let make = self.utilityService.make else {
			preconditionFailure("`app.utilityService.use` required in `configure.swift`.")
		}
		return make(database, application, eventLoop, logger)
	}
	
}

extension Request {
	
	var utilityService: UtilityServiceProtocol {
		self.application.utilityService(
			database: self.db,
			application: self.application,
			eventLoop: self.eventLoop,
			logger: self.logger
		)
	}
	
}
