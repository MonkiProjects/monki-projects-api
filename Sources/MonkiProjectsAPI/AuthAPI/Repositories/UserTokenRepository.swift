//
//  UserTokenRepository.swift
//  AuthAPI
//
//  Created by Rémi Bardon on 15/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiProjectsModel

internal struct UserTokenRepository: UserTokenRepositoryProtocol {
	
	let database: Database
	
	init(database: Database) {
		self.database = database
	}
	
	func getAll(for userId: UserModel.IDValue) async throws -> [UserModel.Token] {
		try await UserModel.Token.query(on: self.database)
			.with(\.$user)
			.filter(\.$user.$id == userId)
			.all()
	}
	
}
