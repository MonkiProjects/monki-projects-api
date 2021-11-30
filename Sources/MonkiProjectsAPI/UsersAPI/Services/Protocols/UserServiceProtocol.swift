//
//  UserServiceProtocol.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 14/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import MonkiProjectsModel

public protocol UserServiceProtocol {
	
	func listUsers(pageRequest: Fluent.PageRequest) async throws -> Fluent.Page<UserModel>
	
	func createUser(_ create: User.Create) async throws -> UserModel
	
	func updateUser(
		_ userId: UserModel.IDValue,
		with update: User.Update,
		requesterId: UserModel.IDValue
	) async throws -> UserModel
	
	func findUsers(
		with filters: User.QueryFilters,
		pageRequest: Fluent.PageRequest
	) async throws -> Fluent.Page<UserModel>
	
	func deleteUser(
		_ userId: UserModel.IDValue,
		requesterId: UserModel.IDValue
	) async throws
	
	/// Check for existing email
	func checkEmailAvailable(_ email: String) async throws
	
	/// Check for existing username
	func checkUsernameAvailable(_ username: String) async throws
	
}
