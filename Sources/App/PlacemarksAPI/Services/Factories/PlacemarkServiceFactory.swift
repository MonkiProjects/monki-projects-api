//
//  PlacemarkServiceFactory.swift
//  App
//
//  Created by Rémi Bardon on 07/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent

// For more information, see <https://docs.vapor.codes/4.0/upgrading/#repositories>

internal struct PlacemarkServiceFactory {
	
	typealias Builder = (Database, Application, EventLoop, Logger) -> PlacemarkServiceProtocol
	
	var make: Builder?
	
	mutating func use(_ make: @escaping Builder) {
		self.make = make
	}
	
}

extension Application {
	
	private struct PlacemarkServiceKey: StorageKey {
		typealias Value = PlacemarkServiceFactory
	}
	
	var placemarkService: PlacemarkServiceFactory {
		get {
			self.storage[PlacemarkServiceKey.self] ?? .init()
		}
		set {
			self.storage[PlacemarkServiceKey.self] = newValue
		}
	}
	
	func placemarkService(
		database: Database,
		application: Application,
		eventLoop: EventLoop,
		logger: Logger
	) -> PlacemarkServiceProtocol {
		guard let make = self.placemarkService.make else {
			preconditionFailure("`app.placemarkService.use` required in `configure.swift`.")
		}
		return make(database, application, eventLoop, logger)
	}
	
}

extension Request {
	
	var placemarkService: PlacemarkServiceProtocol {
		self.application.placemarkService(
			database: self.db,
			application: self.application,
			eventLoop: self.eventLoop,
			logger: self.logger
		)
	}
	
}
