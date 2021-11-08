//
//  UserTokenServiceProtocol.swift
//  AuthAPI
//
//  Created by Rémi Bardon on 15/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import MonkiProjectsModel

public protocol UserTokenServiceProtocol {
	
	func deleteAllTokens(
		for userId: UserModel.IDValue,
		requesterId: UserModel.IDValue
	) async throws
	
}
