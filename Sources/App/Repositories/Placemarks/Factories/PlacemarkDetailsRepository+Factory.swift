//
//  PlacemarkDetailsRepository+Factory.swift
//  App
//
//  Created by Rémi Bardon on 17/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor

// For more information, see <https://docs.vapor.codes/4.0/upgrading/#repositories>

internal struct PlacemarkDetailsRepositoryFactory {
	
	var make: ((Request) -> PlacemarkDetailsRepositoryProtocol)?
	
	mutating func use(_ make: @escaping ((Request) -> PlacemarkDetailsRepositoryProtocol)) {
		self.make = make
	}
	
}

extension Application {
	
	private struct PlacemarkDetailsRepositoryKey: StorageKey {
		typealias Value = PlacemarkDetailsRepositoryFactory
	}
	
	var placemarkDetails: PlacemarkDetailsRepositoryFactory {
		get {
			self.storage[PlacemarkDetailsRepositoryKey.self] ?? .init()
		}
		set {
			self.storage[PlacemarkDetailsRepositoryKey.self] = newValue
		}
	}
	
}

extension Request {
	
	var placemarkDetails: PlacemarkDetailsRepositoryProtocol {
		guard let make = self.application.placemarkDetails.make else {
			preconditionFailure("`app.placemarkDetails.use` required in `configure.swift`.")
		}
		return make(self)
	}
	
}
