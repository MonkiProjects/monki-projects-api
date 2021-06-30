//
//  PlacePropertyRepositoryFactory.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 17/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent

// For more information, see <https://docs.vapor.codes/4.0/upgrading/#repositories>

internal struct PlacePropertyRepositoryFactory {
	
	typealias Builder = (Database) -> PlacePropertyRepositoryProtocol
	
	var make: Builder?
	
	mutating func use(_ make: @escaping Builder) {
		self.make = make
	}
	
}

extension Application {
	
	private struct PlacePropertyRepositoryKey: StorageKey {
		typealias Value = PlacePropertyRepositoryFactory
	}
	
	var placePropertyRepository: PlacePropertyRepositoryFactory {
		get {
			self.storage[PlacePropertyRepositoryKey.self] ?? .init()
		}
		set {
			self.storage[PlacePropertyRepositoryKey.self] = newValue
		}
	}
	
	func placePropertyRepository(for database: Database) -> PlacePropertyRepositoryProtocol {
		guard let make = self.placePropertyRepository.make else {
			preconditionFailure("`app.placePropertyRepository.use` required in `configure.swift`.")
		}
		return make(database)
	}
	
}

extension Request {
	
	var placePropertyRepository: PlacePropertyRepositoryProtocol {
		self.application.placePropertyRepository(for: self.db)
	}
	
}
