//
//  PlacemarkRepository+Factory.swift
//  App
//
//  Created by Rémi Bardon on 16/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor

// For more information, see <https://docs.vapor.codes/4.0/upgrading/#repositories>

internal struct PlacemarkRepositoryFactory {
	
	var make: ((Request) -> PlacemarkRepositoryProtocol)?
	
	mutating func use(_ make: @escaping ((Request) -> PlacemarkRepositoryProtocol)) {
		self.make = make
	}
	
}

extension Application {
	
	private struct PlacemarkRepositoryKey: StorageKey {
		typealias Value = PlacemarkRepositoryFactory
	}
	
	var placemarks: PlacemarkRepositoryFactory {
		get {
			self.storage[PlacemarkRepositoryKey.self] ?? .init()
		}
		set {
			self.storage[PlacemarkRepositoryKey.self] = newValue
		}
	}
	
}

extension Request {
	
	var placemarks: PlacemarkRepositoryProtocol {
		guard let make = self.application.placemarks.make else {
			preconditionFailure("`app.placemarks.use` required in `configure.swift`.")
		}
		return make(self)
	}
	
}
