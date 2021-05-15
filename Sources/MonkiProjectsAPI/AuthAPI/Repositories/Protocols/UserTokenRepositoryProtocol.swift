//
//  UserTokenRepositoryProtocol.swift
//  AuthAPI
//
//  Created by Rémi Bardon on 15/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Foundation
import Fluent
import MonkiProjectsModel

public protocol UserTokenRepositoryProtocol {
	
	func getAll(for userId: UserModel.IDValue) -> EventLoopFuture<[UserModel.Token]>
	
}
