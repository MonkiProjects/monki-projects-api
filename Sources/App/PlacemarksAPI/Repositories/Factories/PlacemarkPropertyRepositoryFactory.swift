//
//  PlacemarkPropertyRepositoryFactory.swift
//  PlacemarksAPI
//
//  Created by Rémi Bardon on 17/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent

// For more information, see <https://docs.vapor.codes/4.0/upgrading/#repositories>

internal struct PlacemarkPropertyRepositoryFactory {
	
	typealias Builder = (Database) -> PlacemarkPropertyRepositoryProtocol
	
	var make: Builder?
	
	mutating func use(_ make: @escaping Builder) {
		self.make = make
	}
	
}

extension Application {
	
	private struct PlacemarkPropertyRepositoryKey: StorageKey {
		typealias Value = PlacemarkPropertyRepositoryFactory
	}
	
	var placemarkPropertyRepository: PlacemarkPropertyRepositoryFactory {
		get {
			self.storage[PlacemarkPropertyRepositoryKey.self] ?? .init()
		}
		set {
			self.storage[PlacemarkPropertyRepositoryKey.self] = newValue
		}
	}
	
	func placemarkPropertyRepository(for database: Database) -> PlacemarkPropertyRepositoryProtocol {
		guard let make = self.placemarkPropertyRepository.make else {
			preconditionFailure("`app.placemarkPropertyRepository.use` required in `configure.swift`.")
		}
		return make(database)
	}
	
}

extension Request {
	
	var placemarkPropertyRepository: PlacemarkPropertyRepositoryProtocol {
		self.application.placemarkPropertyRepository(for: self.db)
	}
	
}
