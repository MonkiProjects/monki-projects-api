//
//  PlacemarkRepositoryFactory.swift
//  App
//
//  Created by Rémi Bardon on 16/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent

// For more information, see <https://docs.vapor.codes/4.0/upgrading/#repositories>

internal struct PlacemarkRepositoryFactory {
	
	typealias Builder = (Database) -> PlacemarkRepositoryProtocol
	
	var make: Builder?
	
	mutating func use(_ make: @escaping Builder) {
		self.make = make
	}
	
}

extension Application {
	
	private struct PlacemarkRepositoryKey: StorageKey {
		typealias Value = PlacemarkRepositoryFactory
	}
	
	var placemarkRepository: PlacemarkRepositoryFactory {
		get {
			self.storage[PlacemarkRepositoryKey.self] ?? .init()
		}
		set {
			self.storage[PlacemarkRepositoryKey.self] = newValue
		}
	}
	
	func placemarkRepository(for database: Database) -> PlacemarkRepositoryProtocol {
		guard let make = self.placemarkRepository.make else {
			preconditionFailure("`app.placemarkRepository.use` required in `configure.swift`.")
		}
		return make(database)
	}
	
}

extension Request {
	
	var placemarkRepository: PlacemarkRepositoryProtocol {
		self.application.placemarkRepository(for: self.db)
	}
	
}
