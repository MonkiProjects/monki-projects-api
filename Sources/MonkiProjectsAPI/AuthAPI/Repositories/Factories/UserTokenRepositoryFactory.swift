//
//  UserTokenRepositoryFactory.swift
//  AuthAPI
//
//  Created by Rémi Bardon on 15/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent

// For more information, see <https://docs.vapor.codes/4.0/upgrading/#repositories>

internal struct UserTokenRepositoryFactory {
	
	typealias Builder = (Database) -> UserTokenRepositoryProtocol
	
	var make: Builder?
	
	mutating func use(_ make: @escaping Builder) {
		self.make = make
	}
	
}

extension Application {
	
	private struct UserTokenRepositoryKey: StorageKey {
		typealias Value = UserTokenRepositoryFactory
	}
	
	var userTokenRepository: UserTokenRepositoryFactory {
		get {
			self.storage[UserTokenRepositoryKey.self] ?? .init()
		}
		set {
			self.storage[UserTokenRepositoryKey.self] = newValue
		}
	}
	
	func userTokenRepository(for database: Database) -> UserTokenRepositoryProtocol {
		guard let make = self.userTokenRepository.make else {
			preconditionFailure("`app.userTokenRepository.use` required in `configure.swift`.")
		}
		return make(database)
	}
	
}

extension Request {
	
	var userTokenRepository: UserTokenRepositoryProtocol {
		self.application.userTokenRepository(for: self.db)
	}
	
}
