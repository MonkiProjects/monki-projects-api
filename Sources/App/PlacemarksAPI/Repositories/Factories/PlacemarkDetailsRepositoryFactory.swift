//
//  PlacemarkDetailsRepositoryFactory.swift
//  App
//
//  Created by Rémi Bardon on 17/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent

// For more information, see <https://docs.vapor.codes/4.0/upgrading/#repositories>

internal struct PlacemarkDetailsRepositoryFactory {
	
	typealias Builder = (Database) -> PlacemarkDetailsRepositoryProtocol
	
	var make: Builder?
	
	mutating func use(_ make: @escaping Builder) {
		self.make = make
	}
	
}

extension Application {
	
	private struct PlacemarkDetailsRepositoryKey: StorageKey {
		typealias Value = PlacemarkDetailsRepositoryFactory
	}
	
	var placemarkDetailsRepository: PlacemarkDetailsRepositoryFactory {
		get {
			self.storage[PlacemarkDetailsRepositoryKey.self] ?? .init()
		}
		set {
			self.storage[PlacemarkDetailsRepositoryKey.self] = newValue
		}
	}
	
	func placemarkDetailsRepository(for database: Database) -> PlacemarkDetailsRepositoryProtocol {
		guard let make = self.placemarkDetailsRepository.make else {
			preconditionFailure("`app.placemarkDetailsRepository.use` required in `configure.swift`.")
		}
		return make(database)
	}
	
}

extension Request {
	
	var placemarkDetailsRepository: PlacemarkDetailsRepositoryProtocol {
		self.application.placemarkDetailsRepository(for: self.db)
	}
	
}
