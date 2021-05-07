//
//  PlacemarkDetailsServiceFactory.swift
//  PlacemarksAPI
//
//  Created by Rémi Bardon on 07/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent

// For more information, see <https://docs.vapor.codes/4.0/upgrading/#repositories>

internal struct PlacemarkDetailsServiceFactory {
	
	typealias Builder = (Database, Application, EventLoop, Logger) -> PlacemarkDetailsServiceProtocol
	
	var make: Builder?
	
	mutating func use(_ make: @escaping Builder) {
		self.make = make
	}
	
}

extension Application {
	
	private struct PlacemarkDetailsServiceKey: StorageKey {
		typealias Value = PlacemarkDetailsServiceFactory
	}
	
	var placemarkDetailsService: PlacemarkDetailsServiceFactory {
		get {
			self.storage[PlacemarkDetailsServiceKey.self] ?? .init()
		}
		set {
			self.storage[PlacemarkDetailsServiceKey.self] = newValue
		}
	}
	
	func placemarkDetailsService(
		database: Database,
		application: Application,
		eventLoop: EventLoop,
		logger: Logger
	) -> PlacemarkDetailsServiceProtocol {
		guard let make = self.placemarkDetailsService.make else {
			preconditionFailure("`app.placemarkDetailsService.use` required in `configure.swift`.")
		}
		return make(database, application, eventLoop, logger)
	}
	
}

extension Request {
	
	var placemarkDetailsService: PlacemarkDetailsServiceProtocol {
		self.application.placemarkDetailsService(
			database: self.db,
			application: self.application,
			eventLoop: self.eventLoop,
			logger: self.logger
		)
	}
	
}
