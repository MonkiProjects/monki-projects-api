//
//  UserServiceProtocol.swift
//  PlacemarksAPI
//
//  Created by Rémi Bardon on 14/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import MonkiProjectsModel

public protocol UserServiceProtocol {
	
	func listUsers(pageRequest: PageRequest) -> EventLoopFuture<Fluent.Page<UserModel>>
	
	func createUser(_ create: User.Create) -> EventLoopFuture<UserModel>
	
	func updateUser(
		_ userId: UserModel.IDValue,
		with update: User.Update,
		requesterId: UserModel.IDValue
	) -> EventLoopFuture<UserModel>
	
	func deleteUser(
		_ userId: UserModel.IDValue,
		requesterId: UserModel.IDValue
	) -> EventLoopFuture<Void>
	
	func checkEmailAvailable(_ email: String) -> EventLoopFuture<Void>
	
	func checkUsernameAvailable(_ username: String) -> EventLoopFuture<Void>
	
}
