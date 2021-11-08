//
//  Users+PublicMappings.swift
//  UsersAPI
//
//  Created by Rémi Bardon on 07/11/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiProjectsModel

extension Fluent.Page where T == UserModel {
	
	func asPublicSmall() throws -> Fluent.Page<User.Public.Small> {
		try self.map { try $0.asPublicSmall() }
	}
	
}
