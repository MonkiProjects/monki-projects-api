//
//  AuthorizationServiceProtocol.swift
//  AuthAPI
//
//  Created by Rémi Bardon on 15/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

public enum AuthorizationRight {
	case read, update, delete
}

public protocol AuthorizationServiceProtocol {
	
	func user(
		_ requesterId: UserModel.IDValue,
		can right: AuthorizationRight,
		user userId: UserModel.IDValue
	) -> EventLoopFuture<Bool>
	
	func user(
		_ requesterId: UserModel.IDValue,
		can right: AuthorizationRight,
		placemark placemarkId: PlacemarkModel.IDValue
	) -> EventLoopFuture<Bool>
	
}
